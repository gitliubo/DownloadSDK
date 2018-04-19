//
//  DownloadManager.m
//  DownloadManager
//
//  Created by liubo on 2018/4/18.
//  Copyright © 2018年 Person. All rights reserved.
//  Github: https://github.com/gitliubo/DownloadSDK.git
//

#import "DownloadManager.h"

#define kCommonUtilsGigabyte (1024 * 1024 * 1024)
#define kCommonUtilsMegabyte (1024 * 1024)
#define kCommonUtilsKilobyte 1024

@interface DownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *itemsDictM;
/**本地通知开关，默认关,一般用于测试。可以根据通知名称，自定义*/
@property (nonatomic, assign) BOOL localPushOn;

@end

@implementation DownloadManager

static id _instance;

#pragma mark - init

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self getDownloadItems];
        if(!self.itemsDictM) self.itemsDictM = [NSMutableDictionary dictionary];
        [self addNotification];
        __block BOOL isNeedSave = false;
        //waing async callback
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //get cached file size
            [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, DownloadModel *  _Nonnull item, BOOL * _Nonnull stop) {
                if (item.downloadStatus == kDownloadStatusFailed || item.downloadStatus == kDownloadStatusPaused) {
                    DownloadTask *task = [DownloadSession.downloadSession taskForTaskId:item.taskId];
                    item.downloadedSize = task.downloadedSize;
                    isNeedSave = true;
                }
            }];
            if(isNeedSave) [self saveDownloadItems];
        });
    }
    
    return self;
}

- (void)saveDownloadItems {
    [NSKeyedArchiver archiveRootObject:self.itemsDictM toFile:[self downloadItemSavePath]];
}

- (void)getDownloadItems {
    NSMutableDictionary *items = [NSKeyedUnarchiver unarchiveObjectWithFile:[self downloadItemSavePath]];;
    
    //app闪退或者手动杀死app，会继续下载。APP再次启动默认暂停所有下载
    [items enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *item = obj;
        //app重新启动，将等待和下载的任务的状态变成暂停
        if (item.downloadStatus == kDownloadStatusDownloading || item.downloadStatus == kDownloadStatusWaiting) {
            item.downloadStatus = kDownloadStatusPaused;
        }
    }];
    
    self.itemsDictM = items;
    
}

- (NSString *)downloadItemSavePath {
    NSString *saveDir = [DownloadTask saveDir];
    return [saveDir stringByAppendingPathComponent:@"items.data"];
}

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadStatusChangedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllTaskFinished) name:kDownloadAllTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadNeedSaveDataNoti object:nil];
}


#pragma mark - public
+ (void)setMaxTaskCount:(NSInteger)count {
    [[DownloadManager manager] setMaxTaskCount: count];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl{
    [[DownloadManager manager] startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId{
    [[DownloadManager manager] startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:fileId];
}

// 新增扩展类
+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId downloadType:(NSUInteger)downloadType categoryId:(NSString *)categoryId extra:(NSDictionary *)extra{
    [[DownloadManager manager] startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:fileId downloadType:downloadType categoryId:categoryId extra:extra];
}

+ (void)pauseDownloadWithItem:(DownloadModel *)item {
    [[DownloadManager manager] pauseDownloadWithItem:item];
}


+ (void)resumeDownloadWithItem:(DownloadModel *)item {
    [[DownloadManager manager] resumeDownloadWithItem:item];
}

+ (void)stopDownloadWithItem:(DownloadModel *)item {
    [[DownloadManager manager] stopDownloadWithItem:item];
}

/**
 暂停所有的下载
 */
+ (void)pauseAllDownloadTask {
    [[DownloadManager manager] pauseAllDownloadTask];
}

+ (void)resumeAllDownloadTask {
    [[DownloadManager manager] resumeAllDownloadTask];
}

+ (void)removeAllCache {
    [[DownloadManager manager] removeAllCache];
}

+ (NSArray *)downloadList {
    return [[DownloadManager manager] downloadList];
}
+ (NSArray *)finishList {
    return [[DownloadManager manager] finishList];
}

+ (BOOL)isDownloadWithId:(NSString *)downloadId {
    return [[self manager] isDownloadWithId:downloadId];
}

+ (DownloadStatus)downloasStatusWithId:(NSString *)downloadId {
    return [[self manager] downloasStatusWithId:downloadId];
}

+ (DownloadModel *)downloadItemWithId:(NSString *)downloadId {
    return [[self manager] itemWithIdentifier:downloadId];
}

+(void)allowsCellularAccess:(BOOL)isAllow {
    [[DownloadManager manager] allowsCellularAccess:isAllow];
}

+(void)localPushOn:(BOOL)isOn {
    [[DownloadManager manager] localPushOn:isOn];
}

#pragma mark tools
+(BOOL)isAllowsCellularAccess{
    return [[DownloadManager manager] isAllowsCellularAccess];
}

+ (NSUInteger)videoCacheSize {
    NSUInteger size = 0;
    NSArray *downloadList = [self downloadList];
    NSArray *finishList = [self finishList];
    for (DownloadTask *task in downloadList) {
        size += task.downloadedSize;
    }
    for (DownloadTask *task in finishList) {
        size += task.fileSize;
    }
    
    return size;
}

+ (NSUInteger)fileSystemFreeSize {
    NSUInteger totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedIntegerValue];
    }
    return totalFreeSpace;
}

+ (void)saveDownloadStatus {
    [[DownloadManager manager] saveDownloadItems];
}
+ (NSString *)fileSizeStringFromBytes:(uint64_t)byteSize {
    if (kCommonUtilsGigabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@GB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsGigabyte]];
    }
    if (kCommonUtilsMegabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@MB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsMegabyte]];
    }
    if (kCommonUtilsKilobyte <= byteSize) {
        return [NSString stringWithFormat:@"%@KB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsKilobyte]];
    }
    return [NSString stringWithFormat:@"%zdB", byteSize];
}


+ (NSString *)numberStringFromDouble:(const double)num {
    NSInteger section = round((num - (NSInteger)num) * 100);
    if (section % 10) {
        return [NSString stringWithFormat:@"%.2f", num];
    }
    if (section > 0) {
        return [NSString stringWithFormat:@"%.1f", num];
    }
    return [NSString stringWithFormat:@"%.0f", num];
}

#pragma mark - private

- (void)setMaxTaskCount:(NSInteger)count{
    [DownloadSession downloadSession].maxTaskCount = count;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl {
    [self startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:downloadURLString];
}

//下载文件时候的保存名称，如果没有fileid那么必须 savename = nil
- (NSString *)saveNameForItem:(DownloadModel *)item {
    NSString *saveName = [item.downloadUrl isEqualToString:item.fileId] ? nil : item.fileId;
    return saveName;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId{
    if (downloadURLString.length == 0 && fileId.length == 0) return;
    NSString *taskId = [DownloadTask taskIdForUrl:downloadURLString fileId:fileId];
    DownloadModel *item = [self.itemsDictM valueForKey:taskId];
    if (item == nil) {
        item = [[DownloadModel alloc] initWithUrl:downloadURLString fileId:fileId];
        item.downloadStatus = kDownloadStatusDownloading;
        item.fileName = fileName;
        item.thumbImageUrl = imagUrl;
        [self.itemsDictM setValue:item forKey:taskId];
    }
    
    [DownloadSession.downloadSession startDownloadWithUrl:downloadURLString fileId:fileId delegate:item];
}

// 新增
- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId downloadType:(NSUInteger)downloadType categoryId:(NSString *)categoryId extra:(NSDictionary *)extra{
    
    if (downloadURLString.length == 0 && fileId.length == 0) return;
    NSString *taskId = [DownloadTask taskIdForUrl:downloadURLString fileId:fileId];
    DownloadModel *item = [self.itemsDictM valueForKey:taskId];
    if (item == nil) {
        item = [[DownloadModel alloc] initWithUrl:downloadURLString fileId:fileId];
        item.downloadStatus = kDownloadStatusDownloading;
        item.fileName = fileName;
        item.thumbImageUrl = imagUrl;
        item.downloadType = downloadType;
        item.categoryId = categoryId;
        item.extra = extra;
        [self.itemsDictM setValue:item forKey:taskId];
    }
    
    [DownloadSession.downloadSession startDownloadWithUrl:downloadURLString fileId:fileId delegate:item];
}

- (void)resumeDownloadWithItem:(DownloadModel *)item{
    item.downloadStatus = kDownloadStatusDownloading;
    if(item.compatibleKey.length>0){
        DownloadTask *task = [DownloadSession.downloadSession taskForTaskId:item.taskId];
        task.delegate = item;
        [DownloadSession.downloadSession resumeDownloadWithTaskId:item.taskId];
    }
    else{
        DownloadTask *task = [DownloadSession.downloadSession taskForTaskId:item.downloadUrl];
        task.delegate = item;
        //TODO: compatiable 1.0.0
        [DownloadSession.downloadSession resumeDownloadWithTaskId:item.taskId.length==0 ? item.downloadUrl : item.taskId];
    }
    
    [self saveDownloadItems];
}

- (void)pauseDownloadWithItem:(DownloadModel *)item {
    item.downloadStatus = kDownloadStatusPaused;
    if(item.compatibleKey.length>0){
        [DownloadSession.downloadSession pauseDownloadWithTaskId:item.taskId];
    }
    else{
        //TODO: compatiable 1.0.0
        [DownloadSession.downloadSession pauseDownloadWithTaskId:item.taskId.length==0 ? item.downloadUrl : item.taskId];
    }
    
    [self saveDownloadItems];
}

- (void)stopDownloadWithItem:(DownloadModel *)item {
    if (item == nil )  return;
    [DownloadSession.downloadSession stopDownloadWithTaskId:item.taskId.length == 0 ? item.downloadUrl : item.taskId];
    //TODO: compatiable 1.0.0 [self.itemsDictM removeObjectForKey: item.taskId];
    [self.itemsDictM removeObjectForKey:item.taskId.length == 0 ? item.downloadUrl : item.taskId];
    
    [self saveDownloadItems];
}

- (void)pauseAllDownloadTask {
    [[DownloadSession downloadSession] pauseAllDownloadTask];
}

- (void)removeAllCache {
    [self.itemsDictM.copy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, DownloadModel *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self stopDownloadWithItem:obj];
    }];
}

- (void)resumeAllDownloadTask{
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *item = obj;
        if (item.downloadStatus == kDownloadStatusPaused || item.downloadStatus == kDownloadStatusFailed) {
            [self resumeDownloadWithItem:item];
        }
    }];
}

- (NSArray *)downloadList {
    NSMutableArray *arrM = [NSMutableArray array];
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *item = obj;
        if(item.downloadStatus != kDownloadStatusFinished){
            [arrM addObject:item];
        }
    }];
    
    return arrM;
}
- (NSArray *)finishList {
    NSMutableArray *arrM = [NSMutableArray array];
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *item = obj;
        if(item.downloadStatus == kDownloadStatusFinished){
            [arrM addObject:item];
        }
    }];
    return arrM;
}

/**id 可以是downloadUrl，也可以是fileId，首先从fileId开始找，然后downloadUrl*/

- (DownloadModel *)itemWithIdentifier:(NSString *)identifier {
    __block  DownloadModel *item = nil;
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *dItem = obj;
        if([dItem.fileId isEqualToString:identifier]){
            item = dItem;
            *stop = true;
        }
    }];
    
    if(item) return item;
    
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        DownloadModel *dItem = obj;
        if([dItem.downloadUrl isEqualToString:identifier]){
            item = dItem;
            *stop = true;
        }
    }];
    
    return item;
}

-(void)allowsCellularAccess:(BOOL)isAllow {
    [[DownloadSession downloadSession] allowsCellularAccess:isAllow];
}

- (BOOL)isAllowsCellularAccess {
    return [[DownloadSession downloadSession] isAllowsCellularAccess];
}

- (BOOL)isDownloadWithId:(NSString *)downloadId {
    DownloadModel *item = [self itemWithIdentifier:downloadId];
    return item != nil;
}

- (DownloadStatus)downloasStatusWithId:(NSString *)downloadId {
    DownloadModel *item = [self itemWithIdentifier:downloadId];
    if (!item) {
        return -1;
    }
    
    return item.downloadStatus;
}

- (void)localPushOn:(BOOL)isOn {
    self.localPushOn = isOn;
}

#pragma mark - 下载通知
- (void)downloadAllTaskFinished{
    [self localPushWithTitle:@"墨子学堂" detail:@"所有的下载任务已完成！"];
}

- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
    DownloadModel *item = noti.object;
    if (item) {
        NSString *category = nil;
        if (item.downloadType <= 6) {
            category = @"该音频";
        }
        
        category = [NSString stringWithFormat:@"%@已经完成下载！", category];
        [self localPushWithTitle:item.fileName detail:category];
    }
}

- (void)localPushWithTitle:(NSString *)title detail:(NSString *)body  {
    
    if (!self.localPushOn) return;
    
    // 1.创建本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    
    // 2.设置本地通知的内容
    // 2.1.设置通知发出的时间
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:3.0];
    // 2.2.设置通知的内容
    localNote.alertBody = body;
    // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
    localNote.alertAction = @"滑动来“解锁”";
    // 2.4.决定alertAction是否生效
    localNote.hasAction = NO;
    // 2.5.设置点击通知的启动图片
    //    localNote.alertLaunchImage = @"123Abc";
    // 2.6.设置alertTitle
    localNote.alertTitle = title;
    // 2.7.设置有通知时的音效
    localNote.soundName = @"default";
    // 2.8.设置应用程序图标右上角的数字
    localNote.applicationIconBadgeNumber = 0;
    
    // 2.9.设置额外信息
    localNote.userInfo = @{@"type" : @1};
    
    // 3.调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
    
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
