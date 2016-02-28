//
//  TuneTableViewController.m
//  itune
//
//  Created by Maksym Savisko on 2/28/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "DownloadTune.h"

#import "TuneTableViewController.h"

@interface TuneTableViewController () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSArray *itunesEntries;
@property (nonatomic, strong) NSMutableArray *tunes;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TuneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPMaximumConnectionsPerHost = 3;
    self.session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:@"https://itunes.apple.com/search?term=rock&country=US&entity=song"]
                                             completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                 NSError *jsonError = nil;
                                                 //Converting NSData to JSON
                                                 NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                          options:0ul
                                                                                                            error:&jsonError];
                                                 self.itunesEntries = jsonData[@"results"];
                                                 //NSLog(@"%@", self.itunesEntries);
                                                 //NSString *previewUrl = [self.itunesEntries lastObject][@"previewUrl"];
                                                 //NSString *artistName = [self.itunesEntries lastObject][@"artistName"];
                                                 //NSString *artistId = self.itunesEntries[49][@"artistId"];
                                                 //NSLog(@"%@", artistName);
                                                 //NSLog(@"%@", artistId);
                                                 //NSLog(@"%lu", (unsigned long)[self.itunesEntries count]);
                                                 //NSLog(@"%@", [previewUrl lastPathComponent]);
                                                 NSLog(@"111: %lu", (unsigned long)self.itunesEntries.count);
                                                 [self initTunes];
                                                 //[self downloadItunesAudioPreview:previewUrl];
                                                 //Array of tune
                                                 //NSLog(@"%lu", (unsigned long)self.itunesEntries.count);
                                                 [self.tableView reloadData];
                                             }];
    [task resume];
    NSString *applicationSupportPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) downloadItunesAudioPreview:(NSString *)previewUrl {
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:previewUrl]];
    [task resume];
}

-(void) initTunes {
    self.tunes = [[NSMutableArray alloc]init];
    for (int i = 0; i <= self.itunesEntries.count-1; i++) {
        DownloadTune * tune = [[DownloadTune alloc]init];
        tune.artistName = self.itunesEntries[i][@"artistName"];
        NSString *previewUrl = self.itunesEntries[i][@"previewUrl"];
        tune.url = [NSURL URLWithString:previewUrl];
        tune.trackName = self.itunesEntries[i][@"trackCensoredName"];
        tune.isDownloaded = NO;
        tune.isDownloading = NO;
        [self.tunes addObject:tune];
    }
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    //NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    //NSLog(@"%@ of %@", [formatter stringFromByteCount:totalBytesWritten], [formatter stringFromByteCount:totalBytesExpectedToWrite]);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    destinationUrl = [destinationUrl stringByAppendingPathComponent:@"2.m4a"];
    
    if (![fileManager fileExistsAtPath:destinationUrl]) {
        [fileManager moveItemAtURL:location
                             toURL:[NSURL fileURLWithPath:destinationUrl]
                             error:&error];
    } else {
        [fileManager replaceItemAtURL:[NSURL fileURLWithPath:destinationUrl]
                        withItemAtURL:location
                       backupItemName:@"ololo"
                              options:0ul
                     resultingItemURL:NULL
                                error:&error];
    }
    NSLog(@"Error %@", error);
    
    //	AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
    //	AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:destinationUrl]];
    //	playerViewController.player = player;
    //	[self presentViewController:playerViewController
    //					   animated:YES
    //					 completion:NULL];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itunesEntries.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TuneCell" forIndexPath:indexPath];
    
    // Configure the cell...
    DownloadTune *tune = [self.tunes objectAtIndex:indexPath.row];
    cell.textLabel.text = tune.artistName;
    cell.detailTextLabel.text = tune.trackName;
    return cell;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
