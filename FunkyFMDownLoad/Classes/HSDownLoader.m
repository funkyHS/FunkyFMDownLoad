//
//  HSDownLoader.m
//  FunkyFMDownLoad
//
//  Created by 胡晟 on 2017/6/19.
//  Copyright © 2017年 funkyHS. All rights reserved.
//

#import "HSDownLoader.h"
#import "HSDownLoadFileTool.h"


#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()

@interface HSDownLoader()<NSURLSessionDelegate>
{
    // 临时文件的大小
    long long _tmpSize;
    // 文件的总大小
    long long _totalSize;
}

/** 下载会话 */
@property (nonatomic, strong) NSURLSession *session;
/** 下载任务 */
@property (nonatomic, weak) NSURLSessionDataTask *dataTask;
/** 文件的缓存路径 */
@property (nonatomic, copy) NSString *downLoadedPath;
/** 文件的临时缓存路径 */
@property (nonatomic, copy) NSString *downLoadingPath;
/** 文件输出流 */
@property (nonatomic, strong) NSOutputStream *outputStream;


@end



@implementation HSDownLoader



#pragma mark - 提供给外界的接口

- (void)downLoader:(NSURL *)url downLoadInfo:(DownLoadInfoType)downLoadInfo progress:(ProgressBlockType)progressBlock success:(SuccessBlockType)successBlock failed:(FailedBlockType)failedBlock {
    
    // 1. 给所有的block赋值
    self.downLoadInfo = downLoadInfo;
    self.progressChange = progressBlock;
    self.successBlock = successBlock;
    self.faildBlock = failedBlock;
    
    // 2. 开始下载
    [self downLoader:url];
    
}


// 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
- (void)downLoader:(NSURL *)url {
    
    
    // 0. 当前任务,已经存在了
    if ([url isEqual:self.dataTask.originalRequest.URL]) {
        // 判断当前的状态, 如果是暂停状态 --> 继续
        if (self.state == HSDownLoadStatePause) {
            [self resumeCurrentTask];
            return;
        }
    }
    
    // 0.1 任务存在, 但是, 任务的Url地址不同
    [self cacelCurrentTask];

    
    // 1. 文件的存放
    // 下载ing => temp + 名称 (MD5 + URL 防止重复资源)
    // 下载完成 => cache + 名称
    NSString *fileName = url.lastPathComponent;
    self.downLoadedPath = [kCachePath stringByAppendingPathComponent:fileName];
    self.downLoadingPath = [kTmpPath stringByAppendingPathComponent:fileName];
    
    
    
    // 2. 判断, url地址, 对应的资源, 是否下载完毕,(下载完成的目录里面,存在这个文件)
    if ([HSDownLoadFileTool fileExists:self.downLoadedPath]) {
        // UNDO: 告诉外界, 已经下载完成;
        NSLog(@"已经下载完成");
        self.state = HSDownLoadStatePauseSuccess;
        return;
    }
    
    
    // 3. 检测, 临时文件是否存在
    if (![HSDownLoadFileTool fileExists:self.downLoadingPath]) {
        
        // 3.1 --> 不存在，从0字节开始请求资源
        [self downLoadWithURL:url offset:0];
        return;
    }
    
    
    // 3.2 --> 存在 则以当前的存在文件大小,作为开始字节,去网络请求资源
    
    //    正确的大小 1000   缓存大小 1001，说明文件缓存错误
    //   本地大小 == 总大小  ==> 移动到下载完成的路径中
    //   本地大小  > 总大小  ==> 删除本地临时缓存, 从0开始下载
    //   本地大小  < 总大小  ==> 从本地大小开始下载
    
    // 获取本地大小
    _tmpSize = [HSDownLoadFileTool fileSize:self.downLoadingPath];
    [self downLoadWithURL:url offset:_tmpSize];
    
    
}

// 暂停任务  注意:如果调用了几次继续,就要调用几次暂停, 才可以暂停  解决方案: 引入状态
- (void)pauseCurrentTask {
    if (self.state == HSDownLoadStateDownLoading) {
        self.state = HSDownLoadStatePause;
        [self.dataTask suspend];
    }
}

// 取消当前任务
- (void)cacelCurrentTask {
    self.state = HSDownLoadStatePause;
    [self.session invalidateAndCancel];
    self.session = nil;
}

// 取消任务, 并清理资源
- (void)cacelAndClean {
    [self cacelCurrentTask];
    [HSDownLoadFileTool removeFile:self.downLoadingPath];
    // 下载完成的文件 -> 手动删除某个声音 或者 统一清理缓存
}

// 继续任务  如果调用了几次暂停, 就要调用几次继续, 才可以继续  解决方案: 引入状态
- (void)resumeCurrentTask {
    if (self.dataTask && self.state == HSDownLoadStatePause) {
        [self.dataTask resume];
        self.state = HSDownLoadStateDownLoading;
    }
}


#pragma mark - 私有方法

// 根据开始字节,请求资源  offset 开始字节
- (void)downLoadWithURL:(NSURL *)url offset: (long long)offset {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    self.dataTask = task;
    [self resumeCurrentTask];


}



#pragma mark - NSURLSessionDataDelegate

// 当发送的请求, 第一次接受到响应的时候调用  completionHandler 系统传递的一个回调代码块,可以通过这个代码块, 来告诉系统,如何处理接下来的数据，可以控制是继续请求，还是取消本次请求
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    NSLog(@"%@",response);
    /*
     --> Content-Length  是请求的大小 不等于 资源大小
     --> Content-Range 这个是资源总大小 有可能没有值(当没有传请求头Range的时候没有值)！！
    
     正确的取资源总大小:
        1. 从 Content-Length 取出来
        2. 如果 Content-Range 有，则从 Content-Range 里面获取
    */
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    _totalSize = [httpResponse.allHeaderFields[@"Content-Length"] longLongValue];
    
    if (httpResponse.allHeaderFields[@"Content-Range"]) {
        
        NSString *rangeStr = httpResponse.allHeaderFields[@"Content-Range"] ;
        _totalSize = [[[rangeStr componentsSeparatedByString:@"/"] lastObject] longLongValue];
    }
    
    if (self.downLoadInfo) {
        self.downLoadInfo(_totalSize);
    }
    
    
    // 比对本地大小, 和 总大小
    if (_tmpSize == _totalSize) {
        
        NSLog(@"移动文件到下载完成");
        
        // 1. 移动到下载完成文件夹
        [HSDownLoadFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        
        // 2. 取消本次请求
        completionHandler(NSURLSessionResponseCancel);
        
        self.state = HSDownLoadStatePauseSuccess;
        
        return;
    }
    
    
    if (_tmpSize > _totalSize) {
        
        NSLog(@"删除临时缓存并重新开始下载");
        
        // 1. 删除临时缓存
        [HSDownLoadFileTool removeFile:self.downLoadingPath];
        
        // 2. 取消请求
        completionHandler(NSURLSessionResponseCancel);
        
        // 3. 从0 开始下载
        [self downLoader:response.URL];

        return;
    }
    
    self.state = HSDownLoadStateDownLoading;
    // 继续接受数据
    // 确定开始下载数据
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingPath append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);

}

// 接收数据的时候调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // 这就是当前已经下载的大小
    _tmpSize += data.length;
    
    // 进度 = 当前下载的大小 / 总大小
    self.progress =  1.0 * _tmpSize / _totalSize;
    
    [self.outputStream write:data.bytes maxLength:data.length];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.outputStream close];
    self.outputStream = nil;

    if (error == nil) {
        
        NSLog(@"下载完毕");
        /*
         不一定是成功
         数据是肯定可以请求完毕
         判断, 本地缓存 == 文件总大小 {服务器返回 filename: filesize: md5:xxx}
         如果等于 => 验证, 是否文件完整(file md5 )
        */
        
        // 移动数据  temp - > cache
        [HSDownLoadFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
        self.state = HSDownLoadStatePauseSuccess;
//        if (self.downLoadSuccess) {
//            self.downLoadSuccess(self.cacheFilePath);
//        }
    }else {
        
        NSLog(@"有问题--%zd--%@", error.code, error.localizedDescription);
        // 取消,  断网
        // 999 != 999
        if (-999 == error.code) {
            self.state = HSDownLoadStatePause;
        }else {
            self.state = HSDownLoadStatePauseFailed;
        }
    }
    
    
}



#pragma mark - 懒加载

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)setState:(HSDownLoadState)state {
    if(_state == state) {
        return;
    }
    _state = state;
    
    // 代理, block, 通知 (推模式)
    
    if (self.stateChange) {
        self.stateChange(_state);
    }
    
    if (_state == HSDownLoadStatePauseSuccess && self.successBlock) {
        self.successBlock(self.downLoadedPath);
    }
    
    if (_state == HSDownLoadStatePauseFailed && self.faildBlock) {
        self.faildBlock();
    }
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if (self.progressChange) {
        self.progressChange(_progress);
    }
}



@end
