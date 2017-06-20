//
//  HSDownLoadManager.h
//  FunkyFMDownLoad
//
//  Created by 胡晟 on 2017/6/19.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSDownLoader.h"


@interface HSDownLoadManager : NSObject

// 获取单利对象
+ (instancetype)shareInstance;


/**
 根据 url 下载相应的资源

 @param url 资源url地址
 @param downLoadInfo 资源信息
 @param progressBlock 下载进度
 @param successBlock 下载成功回调
 @param failedBlock 下载失败回调
 */
- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock;

// 根据url暂停任务
- (void)pauseWithURL:(NSURL *)url;

// 根据url开始／继续任务
- (void)resumeWithURL:(NSURL *)url;

// 根据url取消任务
- (void)cancelWithURL:(NSURL *)url;

// 根据url 取消任务, 并清理资源
- (void)cacelAndCleanWithURL:(NSURL *)url;


- (void)pauseAll;
- (void)resumeAll;


@end
