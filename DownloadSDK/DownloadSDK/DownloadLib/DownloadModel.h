//
//  DownloadModel.h
//  DownloadManager
//
//  Created by liubo on 2018/4/18.
//  Copyright © 2018年 Person. All rights reserved.
//  Github: https://github.com/gitliubo/DownloadSDK.git
//

#import <Foundation/Foundation.h>

#import "DownloadTask.h"
@class DownloadModel;

/**某一的任务下载完成的通知*/
static NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
/**保存下载数据通知*/
static NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";

@protocol DownloadModelDelegate <NSObject>

@optional
- (void)downloadItemStatusChanged:(DownloadModel *)item;
- (void)downloadItem:(DownloadModel *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;

@end

@interface DownloadModel : NSObject<DownloadTaskDelegate>

- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId;
+ (instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId;

/**下载任务标识*/
@property (nonatomic, copy,readonly) NSString *fileId;// 下载媒体id
@property (nonatomic, copy,readonly) NSString *downloadUrl;// 下载地址
@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, weak) id <DownloadModelDelegate> delegate;
@property (nonatomic, copy) NSString *fileName;// 下载媒体名字
@property (nonatomic, copy) NSString *thumbImageUrl;// 媒体图片
/**下载完成后保存在本地的路径*/
@property (nonatomic, readonly) NSString *savePath;
@property (nonatomic, assign) NSUInteger fileSize;// 总大小
@property (nonatomic, assign) NSUInteger downloadedSize;// 当前下载大小
@property (nonatomic, assign) DownloadStatus downloadStatus;// 下载状态
@property (nonatomic, copy, readonly) NSString *saveName;// 保存名字
@property (nonatomic, copy) NSString *compatibleKey;
/*
 * 媒体下载类型
 */
@property (nonatomic, assign) NSUInteger downloadType;
@property (nonatomic, copy) NSString *categoryId;// 大分类ID(用于扩展id)
@property (nonatomic, strong) NSDictionary *extra;// 用于扩展

@end
