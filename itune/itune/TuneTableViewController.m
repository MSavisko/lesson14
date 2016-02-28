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
#import "TuneCell.h"

#import "TuneTableViewController.h"

@interface TuneTableViewController () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSArray *itunesEntries;
@property (nonatomic, strong) NSMutableArray *tunes;
@property (strong, nonatomic) IBOutlet UITableView *tuneTableView;
@property (nonatomic) NSInteger indexPathRow;

@end

@implementation TuneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
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
                                                 NSLog(@"111: %lu", (unsigned long)self.itunesEntries.count);
                                                 [self initTunes];
                                                 [self.tuneTableView reloadData];
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
        tune.downloadTask = [self.session downloadTaskWithURL:tune.url];
        [self.tunes addObject:tune];
    }
}

#pragma mark - URL Session Delegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    NSLog(@"%@ of %@", [formatter stringFromByteCount:totalBytesWritten], [formatter stringFromByteCount:totalBytesExpectedToWrite]);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    //Tune by TaskID
    DownloadTune * tune = [[DownloadTune alloc]init];
    NSURLSessionTask * currentSessionTask = downloadTask;
    NSInteger tagInt = currentSessionTask.taskIdentifier - 2;
    tune = self.tunes[tagInt];
    NSString * artistNameAndTrackAndFormat = [NSString stringWithFormat:@"%@ - %@.m4a", tune.artistName, tune.trackName];
    
    //Save
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *destinationUrl = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
    destinationUrl = [destinationUrl stringByAppendingPathComponent:artistNameAndTrackAndFormat];
    
    //Save file to Library
    if (![fileManager fileExistsAtPath:destinationUrl]) {
        [fileManager moveItemAtURL:location
                             toURL:[NSURL fileURLWithPath:destinationUrl]
                             error:&error];
        NSLog(@"Destenation URL: %@", destinationUrl);
    } else {
        [fileManager replaceItemAtURL:[NSURL fileURLWithPath:destinationUrl]
                        withItemAtURL:location
                       backupItemName:@"ololo"
                              options:0ul
                     resultingItemURL:NULL
                                error:&error];
        NSLog(@"Destenation URL: %@", destinationUrl);
    }
    NSLog(@"Error %@", error);
    
    tune.fileUrl = destinationUrl;
    tune.isDownloaded = YES;
    tune.isDownloading = NO;
    [self.tunes replaceObjectAtIndex:tagInt withObject:tune];
    [self.tuneTableView reloadData];
    
}

#pragma mark - Action

-(void) downloadTuneFromButton:(UIButton*)button {
    DownloadTune * tune = [[DownloadTune alloc]init];
    tune = self.tunes[button.tag];
    tune.isDownloading = YES;
    [self.tunes replaceObjectAtIndex:button.tag withObject:tune];
    [tune.downloadTask resume];
    [self.tuneTableView reloadData];
}

-(void) playTuneFromButton: (UIButton*)button {
    DownloadTune * tune = [[DownloadTune alloc]init];
    tune = self.tunes[button.tag];
    
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:tune.fileUrl]];
    playerViewController.player = player;
    [self presentViewController:playerViewController
                       animated:YES
                     completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tunes.count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"List of songs";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TuneCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TuneCell" forIndexPath:indexPath];
    DownloadTune *tune = [self.tunes objectAtIndex:indexPath.row];
    cell.artistName.text = tune.artistName;
    cell.trackName.text = tune.trackName;
    cell.actionButton.tag = indexPath.row;
    [cell.indicatorView setHidden:YES];
    if (tune.isDownloaded) {
        [cell.actionButton setTitle:@"Play" forState:UIControlStateNormal];
        [cell.indicatorView stopAnimating];
        [cell.actionButton addTarget:self action:@selector(playTuneFromButton:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        if (tune.isDownloading) {
            [cell.indicatorView setHidden:NO];
            [cell.indicatorView startAnimating];
        }
        [cell.actionButton addTarget:self action:@selector(downloadTuneFromButton:) forControlEvents:UIControlEventTouchUpInside];
    }

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
