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
#import "AppInstalledHelper.h"

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);


@interface ViewController()

@property (weak) IBOutlet NSTextField *filePathInput;
@property (weak) IBOutlet NSButtonCell *watchBtn;

@property (weak) IBOutlet NSImageView *imageOptimIcon;
@property (weak) IBOutlet NSImageView *imageAlphaIcon;
@property (weak) IBOutlet NSImageView *jpegMiniIcon;
@property (weak) IBOutlet NSImageView *jpegMiniLiteIcon;
@property (weak) IBOutlet NSImageView *jpegMiniProIcon;

@property (weak) IBOutlet NSScrollView *detailScrollView;
@property (unsafe_unretained) IBOutlet NSTextView *detailTextView;


@property(nonatomic) NSInteger syncEventID;
@property(nonatomic, assign) FSEventStreamRef syncEventStream;

@end

@implementation ViewController
{
    NSMutableArray * _imageLogs;
    NSMutableAttributedString * _detailAttributStr;
    BOOL _isWatching;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logDetail:) name:@"DetailLog" object:nil];
    
    _isWatching = NO;
    _imageLogs = [NSMutableArray array];
    _detailAttributStr = [[NSMutableAttributedString alloc] initWithString:@"------- detail --------"];
    
    NSImage * trueIcon  = [NSImage imageNamed:@"true"];
    NSImage * falseIcon = [NSImage imageNamed:@"false"];
    
    _imageOptimIcon.image   = [AppInstalledHelper isInstallAppOfBundleIdentifier:@"net.pornel.ImageOptim"] ? trueIcon : falseIcon;
    _imageAlphaIcon.image   = [AppInstalledHelper isInstallAppOfBundleIdentifier:@"net.pornel.ImageAlpha"] ? trueIcon : falseIcon;
    _jpegMiniIcon.image     = [AppInstalledHelper isInstallAppOfBundleIdentifier:@"com.icvt.JPEGmini"] ? trueIcon : falseIcon;
    _jpegMiniLiteIcon.image = [AppInstalledHelper isInstallAppOfBundleIdentifier:@"com.icvt.JPEGminiLite"] ? trueIcon : falseIcon;
    _jpegMiniProIcon.image  = [AppInstalledHelper isInstallAppOfBundleIdentifier:@"com.icvt.JPEGmini-Pro-retail"] ? trueIcon : falseIcon;
}


- (void)logDetail:(NSNotification *)notification {
    NSDictionary * info = [notification object];
    NSString * type = [info objectForKey:@"type"];
    NSString * detail = [info objectForKey:@"detail"];
    if ([type isEqualToString:@"path"]) {
        NSString * str = [NSString stringWithFormat:@"\n%@", detail];
        NSMutableAttributedString * attributStr = [[NSMutableAttributedString alloc] initWithString:str];
        [attributStr addAttribute:NSFontAttributeName
                        value:[NSFont boldSystemFontOfSize:14.f]
                        range:NSMakeRange(0, str.length)];
        [_detailAttributStr insertAttributedString:attributStr atIndex:_detailAttributStr.length];
    }
    if ([type isEqualToString:@"detail"]) {
        NSString * str = [NSString stringWithFormat:@"\n%@", [info objectForKey:@"detail"]];
        NSMutableAttributedString * attributStr = [[NSMutableAttributedString alloc] initWithString:str];
        [attributStr addAttribute:NSForegroundColorAttributeName
                            value:[NSColor grayColor]
                            range:NSMakeRange(0, str.length)];
        [_detailAttributStr insertAttributedString:attributStr atIndex:_detailAttributStr.length];
    }
  
    [[_detailTextView textStorage] setAttributedString:_detailAttributStr];
    [_detailScrollView.contentView scrollToPoint:CGPointMake(0, _detailScrollView.contentView.frame.size.height-_detailScrollView.frame.size.height)];
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
    _isWatching = YES;
    [_watchBtn setTitle:@"停止监控"];
}
- (void)stopWatch {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
        _isWatching = NO;
        [_watchBtn setTitle:@"开始监控"];
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
    if (_isWatching) {
        [self stopWatch];
    } else {
        [self startWatch];
    }
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



