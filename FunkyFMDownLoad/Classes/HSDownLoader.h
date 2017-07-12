//
//  HSDownLoader.h
//  FunkyFMDownLoad
//
//  Created by 胡晟 on 2017/6/19.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownLoadURLOrStateChangeNotification @"downLoadURLOrStateChangeNotification"


typedef NS_ENUM(NSUInteger, HSDownLoadState) {
    HSDownLoadStatePause,
    HSDownLoadStateDownLoading,
    HSDownLoadStatePauseSuccess,
    HSDownLoadStatePauseFailed
};


typedef void(^DownLoadInfoType)(long long totalSize);
typedef void(^ProgressBlockType)(float progress);
typedef void(^SuccessBlockType)(NSString *filePath);
typedef void(^FailedBlockType)();
typedef void(^StateChangeType)(HSDownLoadState state);


@interface HSDownLoader : NSObject

// 外界只需使用此方法
- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock;



// 获取下载完成后的存放路径
+ (NSString *)downLoadedFileWithURL: (NSURL *)url;

// 该资源的临时缓存大小
+ (long long)tmpCacheSizeWithURL: (NSURL *)url;

// 清除下载完成的资源文件
+ (void)clearCacheWithURL: (NSURL *)url;


// 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作   url 资源路径
- (void)downLoader:(NSURL *)url;

// 暂停任务
- (void)pauseCurrentTask;

// 取消任务
- (void)cacelCurrentTask;

// 取消任务, 并清理资源
- (void)cacelAndClean;

// 继续任务
- (void)resumeCurrentTask;

// 下载状态 重写setter方法，使用推模式
@property (nonatomic, assign, readonly) HSDownLoadState state;

@property (nonatomic, assign, readonly) float progress;

// 下载信息
@property (nonatomic, copy) DownLoadInfoType downLoadInfo;
// 监听下载状态的改变
@property (nonatomic, copy) StateChangeType stateChange;
@property (nonatomic, copy) ProgressBlockType progressChange;
@property (nonatomic, copy) SuccessBlockType successBlock;
@property (nonatomic, copy) FailedBlockType faildBlock;

@end
