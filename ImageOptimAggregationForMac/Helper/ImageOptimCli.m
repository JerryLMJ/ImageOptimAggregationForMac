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
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.standardOutput = pipe;
    NSString * lanchPath = [[NSBundle mainBundle] pathForResource:@"imageoptim" ofType:nil];
    NSLog(@"----lanchPath : %@",lanchPath);
    task.launchPath = lanchPath;
    NSArray *arguments = @[[NSString stringWithFormat:@"%@", filePath]];
    NSLog(@"----arguments : %@",arguments);
    task.arguments = arguments;
    task.terminationHandler = ^(NSTask * _Nonnull task) {
        NSLog(@"----finished");
    };
    [task launch];
    
    
    // 输出执行log
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"----grep returned :\n%@", grepOutput);
}

@end
