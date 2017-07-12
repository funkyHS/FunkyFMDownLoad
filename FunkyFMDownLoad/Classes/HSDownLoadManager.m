//
//  HSDownLoadManager.m
//  FunkyFMDownLoad
//
//  Created by 胡晟 on 2017/6/19.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "HSDownLoadManager.h"
#import "NSString+HSDownLoader.h"


@interface HSDownLoadManager()<NSCopying, NSMutableCopying>

@property (nonatomic, strong) NSMutableDictionary <NSString * ,HSDownLoader *>*downLoadInfo;

@end

@implementation HSDownLoadManager

static HSDownLoadManager *_shareInstance;
+ (instancetype)shareInstance {
    if (_shareInstance == nil) {
        _shareInstance = [[self alloc] init];
    }
    return _shareInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}
- (id)copyWithZone:(NSZone *)zone {
    return _shareInstance;
}
- (id)mutableCopyWithZone:(NSZone *)zone {
    return _shareInstance;
}


// 根据URL下载资源
- (HSDownLoader *)downLoadWithURL: (NSURL *)url {
    
    NSString *md5 = [url.absoluteString md5Str];
    
    HSDownLoader *downLoader = self.downLoadInfo[md5];
    if (downLoader) {
        [downLoader resumeCurrentTask];
        return downLoader;
    }
    downLoader = [[HSDownLoader alloc] init];
    [self.downLoadInfo setValue:downLoader forKey:md5];
    
    __weak typeof(self) weakSelf = self;
    [downLoader downLoader:url downLoadInfo:nil progress:nil success:^(NSString *filePath) {
        
        // 下载完成之后, 移除下载器
        [weakSelf.downLoadInfo removeObjectForKey:md5];
        
    } failed:^{
        [weakSelf.downLoadInfo removeObjectForKey:md5];
    }];
    
    return downLoader;
    
}

// 获取url对应的downLoader
- (HSDownLoader *)getDownLoaderWithURL: (NSURL *)url {
    NSString *md5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[md5];
    return downLoader;
}

// 根据 url 下载相应的资源
- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock {
    
    // 1. url
    NSString *urlMD5 = [url.absoluteString md5Str];
    
    // 2. 根据 urlMD5 , 查找相应的下载器
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    if (downLoader == nil) {
        downLoader = [[HSDownLoader alloc] init];
        self.downLoadInfo[urlMD5] = downLoader;
    }
        
    __weak typeof(self) weakSelf = self;
    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:^(NSString *filePath) {
        
        // 下载完成之后, 移除下载器
        [weakSelf.downLoadInfo removeObjectForKey:urlMD5];
        
        // 拦截block
        successBlock(filePath);
        
    } failed:failedBlock];
    
}

// 根据url暂停任务
- (void)pauseWithURL:(NSURL *)url {
    
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader pauseCurrentTask];
    
}

// 根据url开始／继续任务
- (void)resumeWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader resumeCurrentTask];
}

// 根据url取消任务
- (void)cancelWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader cacelCurrentTask];
    
}

// 根据url 取消任务, 并清理资源
- (void)cacelAndCleanWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader cacelAndClean];
}

// 暂停所有
- (void)pauseAll {
    
    [self.downLoadInfo.allValues performSelector:@selector(pauseCurrentTask) withObject:nil];
    
}

// 恢复所有
- (void)resumeAll {
    [self.downLoadInfo.allValues performSelector:@selector(resumeCurrentTask) withObject:nil];
}


#pragma mark - 懒加载
// key: md5(url)  value: HSDownLoader
- (NSMutableDictionary *)downLoadInfo {
    if (!_downLoadInfo) {
        _downLoadInfo = [NSMutableDictionary dictionary];
    }
    return _downLoadInfo;
}


@end
