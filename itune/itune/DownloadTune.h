//
//  DownloadTune.h
//  itune
//
//  Created by Maksym Savisko on 2/27/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadTune : NSObject

@property (nonatomic, strong) NSURL * url;
@property (nonatomic, strong) NSString * fileUrl;
@property (nonatomic) float progress;
@property (nonatomic) float size;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL isDownloaded;
@property (nonatomic, strong) NSURLSessionDownloadTask * downloadTask;
@property (nonatomic, strong) NSDictionary * jsonData;

@end
