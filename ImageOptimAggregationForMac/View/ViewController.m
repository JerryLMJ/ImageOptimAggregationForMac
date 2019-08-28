//
//  ViewController.m
//  ImageOptimAggregationForMac
//
//  Created by LiMingjie on 2019/6/28.
//  Copyright © 2019 LMJ. All rights reserved.
//

#import "ViewController.h"

#import <CoreServices/CoreServices.h>
#import "ImageOptimCli.h"

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);


@interface ViewController()

@property (weak) IBOutlet NSTextField *filePathInput;

@property(nonatomic) NSInteger syncEventID;
@property(nonatomic, assign) FSEventStreamRef syncEventStream;

@end

@implementation ViewController
{
    NSMutableArray * _imageLogs;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _imageLogs = [NSMutableArray array];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}


- (void)startWatch {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
    NSArray *paths = @[_filePathInput.stringValue];// 这里填入需要监控的文件夹
    FSEventStreamContext context;
    context.info = (__bridge void * _Nullable)(self);
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    self.syncEventStream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef _Nonnull)(paths), self.syncEventID, 1, kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
    FSEventStreamScheduleWithRunLoop(self.syncEventStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.syncEventStream);
}
- (void)stopWatch {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
}


#pragma mark - Process Filepath
- (void)processFilePath:(NSString *)filePath{
    if ([_imageLogs containsObject:filePath]) return;
    if ([filePath hasSuffix:@".png"] |
        [filePath hasSuffix:@".jpg"] |
        [filePath hasSuffix:@".jpeg"] ) {
        NSLog(@"----filePath : %@", filePath);
        [_imageLogs addObject:filePath];
        [ImageOptimCli processFile:filePath];
    }
}


#pragma mark - private method
-(void)updateEventID {
    self.syncEventID = FSEventStreamGetLatestEventId(self.syncEventStream);
}
-(void)setSyncEventID:(NSInteger)syncEventID{
    [[NSUserDefaults standardUserDefaults] setInteger:syncEventID forKey:@"SyncEventID"];
}
-(NSInteger)syncEventID {
    NSInteger syncEventID = [[NSUserDefaults standardUserDefaults] integerForKey:@"SyncEventID"];
    if(syncEventID == 0) {
        syncEventID = kFSEventStreamEventIdSinceNow;
    }
    return syncEventID;
}

#pragma mark - Btn Actions
- (IBAction)clickFileBtn:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];//是否能选择文件file
    [panel setCanChooseDirectories:YES];//是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];//是否允许多选file
    if ([panel runModal] == NSModalResponseOK) {
        for (NSURL *url in [panel URLs]) {
            _filePathInput.stringValue = [url.absoluteString substringFromIndex:7];
        }
    }
}
- (IBAction)startWatchClicked:(id)sender {
    [self startWatch];
}

@end

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    ViewController *self = (__bridge ViewController *)userData;
    NSArray *pathArr = (__bridge NSArray*)eventPaths;
    FSEventStreamEventId lastRenameEventID = 0;
    NSString* lastPath = nil;
    for(int i=0; i<numEvents; i++){
        FSEventStreamEventFlags flag = eventFlags[i];
        if(kFSEventStreamEventFlagItemCreated & flag) {
            NSLog(@"create file: %@", pathArr[i]);
        }
        if(kFSEventStreamEventFlagItemRenamed & flag) {
            FSEventStreamEventId currentEventID = eventIds[i];
            NSString* currentPath = pathArr[i];
            if (currentEventID == lastRenameEventID + 1) {
                // 重命名或者是移动文件
                NSLog(@"mv %@ %@", lastPath, currentPath);
                [self processFilePath:currentPath];
            } else {
                // 其他情况, 例如移动进来一个文件, 移动出去一个文件, 移动文件到回收站
                if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath]) {
                    // 移动进来一个文件
                    NSLog(@"move in file: %@", currentPath);
                } else {
                    // 移出一个文件
                    NSLog(@"move out file: %@", currentPath);
                }
            }
            lastRenameEventID = currentEventID;
            lastPath = currentPath;
        }
        if(kFSEventStreamEventFlagItemRemoved & flag) {
            NSLog(@"remove: %@", pathArr[i]);
        }
        if(kFSEventStreamEventFlagItemModified & flag) {
            NSLog(@"modify: %@", pathArr[i]);
        }
    }
    [self updateEventID];
}



