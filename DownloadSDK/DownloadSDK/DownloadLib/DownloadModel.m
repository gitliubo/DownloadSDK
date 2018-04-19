//
//  DownloadModel.m
//  DownloadManager
//
//  Created by liubo on 2018/4/18.
//  Copyright © 2018年 Person. All rights reserved.
//  Github: https://github.com/gitliubo/DownloadSDK.git
//

#import "DownloadModel.h"

#import <objc/runtime.h>
#import "DownloadSession.h"

@implementation DownloadModel

#pragma mark - init
-(instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    if (self = [super init]) {
        _downloadUrl = url;
        _fileId = fileId;
        _taskId = [DownloadTask taskIdForUrl:url fileId:fileId];
        _compatibleKey = [DownloadSession downloadSession].downloadVersion;
    }
    return self;
}

+(instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId {
    return [[DownloadModel alloc] initWithUrl:url fileId:fileId];
}

#pragma mark - YCDownloadSessionDelegate
- (void)downloadProgress:(DownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize {
    self.downloadedSize = downloadedSize;
    self.fileSize = fileSize;
    if ([self.delegate respondsToSelector:@selector(downloadItem:downloadedSize:totalSize:)]) {
        [self.delegate downloadItem:self downloadedSize:downloadedSize totalSize:fileSize];
    }
}

- (void)downloadStatusChanged:(DownloadStatus)status downloadTask:(DownloadTask *)task {
    if (status == kDownloadStatusFinished) {
        self.downloadedSize = self.fileSize;
    }
    self.downloadStatus = status;
    if ([self.delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
        [self.delegate downloadItemStatusChanged:self];
    }
    //通知优先级最后，不与上面的finished重合
    if (status == kDownloadStatusFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadTaskFinishedNoti object:self];
    }
}

- (void)downloadCreated:(DownloadTask *)task {
    self.downloadStatus = kDownloadStatusDownloading;
    if(task.fileSize > 0){
        self.fileSize = task.fileSize;
    }
    _saveName = task.saveName;
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadNeedSaveDataNoti object:nil userInfo:nil];
}

#pragma mark - public

- (NSString *)savePath {
    return [DownloadTask savePathWithSaveName:self.saveName];
}

#pragma mark - private
///  解档
- (instancetype)initWithCoder:(NSCoder *)coder{
    if (self = [super init]) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([self class], &count);
        for (NSInteger i=0; i<count; i++) {
            Ivar ivar = ivars[i];
            NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
            if([name isEqualToString:@"_delegate"]) continue;
            id value = [coder decodeObjectForKey:name];
            if(value) [self setValue:value forKey:name];
        }
        
        free(ivars);
    }
    return self;
}

///  归档
- (void)encodeWithCoder:(NSCoder *)coder{
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (NSInteger i=0; i<count; i++) {
        Ivar ivar = ivars[i];
        NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
        if([name isEqualToString:@"_delegate"]) continue;
        id value = [self valueForKey:name];
        if(value) [coder encodeObject:value forKey:name];
    }
    
    free(ivars);
}

@end
