//
//  HSDownLoadFileTool.m
//  Pods
//
//  Created by 胡晟 on 2017/6/23.
//
//

#import "HSDownLoadFileTool.h"

@implementation HSDownLoadFileTool

+ (BOOL)fileExists:(NSString *)filePath {
    if (filePath.length == 0) {
        return NO;
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (long long)fileSize:(NSString *)filePath {
    
    if (![self fileExists:filePath]) {
        return 0;
    }
    
    NSError *error = nil;
    NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error == nil) {
        return [fileDic[NSFileSize] longLongValue];
    }
    
    return 0;
    
}

+ (void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath {
    
    if (![self fileSize:fromPath]) {
        return;
    }
    
    [[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:nil];
    
}

+ (void)removeFile:(NSString *)filePath {
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}


@end
