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

@property (nonatomic, strong) NSMutableDictionary *downLoadInfo;

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


- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock {
    
    // 1. url
    NSString *urlMD5 = [url.absoluteString md5Str];
    
    // 2. 根据 urlMD5 , 查找相应的下载器
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    if (downLoader == nil) {
        downLoader = [[HSDownLoader alloc] init];
        self.downLoadInfo[urlMD5] = downLoader;
    }
    
    //    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:successBlock failed:failedBlock];
    
    __weak typeof(self) weakSelf = self;
    [downLoader downLoader:url downLoadInfo:downLoadInfo progress:progressBlock success:^(NSString *filePath) {
        
        // 下载完成之后, 移除下载器
        [weakSelf.downLoadInfo removeObjectForKey:urlMD5];
        
        // 拦截block
        successBlock(filePath);
        
    } failed:failedBlock];
    
}


- (void)pauseWithURL:(NSURL *)url {
    
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader pauseCurrentTask];
    
}
- (void)resumeWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader resumeCurrentTask];
}
- (void)cancelWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader cacelCurrentTask];
    
}
- (void)cacelAndCleanWithURL:(NSURL *)url {
    NSString *urlMD5 = [url.absoluteString md5Str];
    HSDownLoader *downLoader = self.downLoadInfo[urlMD5];
    [downLoader cacelAndClean];
}

- (void)pauseAll {
    
    [self.downLoadInfo.allValues performSelector:@selector(pauseCurrentTask) withObject:nil];
    
}
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
