//
//  ImageOptimCli.m
//  ImageOptimAggregationForMac
//
//  Created by LiMingjie on 2019/8/28.
//  Copyright © 2019 LMJ. All rights reserved.
//

#import "ImageOptimCli.h"

@implementation ImageOptimCli

+ (void)processFile:(NSString *)filePath {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailLog" object:@{@"type": @"path", @"detail": filePath } userInfo:nil];
    
    NSTask *task = [[NSTask alloc] init];
    NSString * lanchPath = [[NSBundle mainBundle] pathForResource:@"imageoptim" ofType:nil];
    NSLog(@"----lanchPath : %@",lanchPath);
    task.launchPath = lanchPath;
    NSArray *arguments = @[[NSString stringWithFormat:@"%@", filePath]];
    NSLog(@"----arguments : %@",arguments);
    task.arguments = arguments;
    task.terminationHandler = ^(NSTask * _Nonnull task) {
        NSLog(@"----finished");
    };

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    NSFileHandle *file = pipe.fileHandleForReading;
    [file waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:file queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSFileHandle *fh = [note object];
        NSData *data = [fh availableData];
        if (data.length > 0) { // if data is found, re-register for more data (and print)
            [fh waitForDataInBackgroundAndNotify];
            NSString *log = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog (@"----grep returned :\n%@", log);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DetailLog" object:@{@"type": @"detail", @"detail": log } userInfo:nil];
        }
    }];

    [task launch];
}

@end
