//
//  HSDownLoadFileTool.h
//  Pods
//
//  Created by 胡晟 on 2017/6/23.
//
//

#import <Foundation/Foundation.h>

@interface HSDownLoadFileTool : NSObject


// filePath下文件是否存在
+ (BOOL)fileExists:(NSString *)filePath;

// filePath下文件的大小
+ (long long)fileSize:(NSString *)filePath;

// 移动 fromPath 路径下的文件到 toPath 下
+ (void)moveFile:(NSString *)fromPath toPath:(NSString *)toPath;

// 移除 filePath 路径下的文件
+ (void)removeFile:(NSString *)filePath;



@end
