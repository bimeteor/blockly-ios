//
//  WSRobotManager+FileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager+FileOperation.h"
#import "WSOpenFileOperation.h"
#import "WSCloseFileOperation.h"
#import "WSReadFileOperation.h"
#import "WSWriteFileOperation.h"
#import "WSRenameFileOperation.h"
#import "WSDeleteFileOperation.h"
#include <zlib.h>

@implementation WSRobotManager (FileOperation)

- (WSOpenFileOperation *)openFile:(NSString *)filename fileMode:(FILEMODE)fileMode;
{
    WSOpenFileOperation *op = [[WSOpenFileOperation alloc] initWithPath:filename mode:fileMode];
    [self addTask:op];

    NSLog(@"打开文件====== %d %d %d", op.filePointer, op.fileSize, op.fileCrc32);
    
    return op;
}

- (NSData *)readFile:(NSString *)path bytes:(uint32_t)bytes
{
    //只读模式打开文件
    WSOpenFileOperation *op = [[WSOpenFileOperation alloc] initWithPath:path mode:FILEMODE_RDONLY];
    [self addTask:op];

    NSLog(@"打开文件====== %d %d %u", op.filePointer, op.fileSize, op.fileCrc32);

    //打开文件完成
    uint32_t bytesWantToRead = bytes;
    if (bytesWantToRead == 0) {
        //读文件的全部
        bytesWantToRead = op.fileSize;
    }
    
    //循环读取
    NSMutableData *result = [NSMutableData data];
    NSData *perTimeData = nil;
    uint32_t readBytesPerTime = 128;    //每次读取128字节
    do {
        WSReadFileOperation *readOp = [[WSReadFileOperation alloc] initWithFilePointer:op.filePointer readBytes:readBytesPerTime];
        [self addTask:readOp];
        
        perTimeData = readOp.data;
        
        if (perTimeData != nil) {
            [result appendData:perTimeData];
        }
        
    } while (perTimeData != nil && perTimeData.length == readBytesPerTime);
    
    //关闭文件
    WSCloseFileOperation *closeOp = [[WSCloseFileOperation alloc] initWithFilePointer:op.filePointer];
    [self addTask:closeOp];
    
    BOOL closeSuc = closeOp.closeSuc;
    if (closeSuc) {
        NSLog(@"关闭成功");
        uLong crc = crc32(0, NULL, 0);
        uLong crcValue = crc32(crc, [result bytes], (uInt)[result length]);
        
        if (crcValue == op.fileCrc32) {
            NSLog(@"读成功");
        }else {
            NSLog(@"读失败");
        }
    }else {
        NSLog(@"关闭失败");
    }
    
    return result;
}

- (BOOL)writeFile:(NSString *)path data:(NSData *)data
{
    //只读模式打开文件
//    NSString *tempFilePath = [path stringByAppendingString:@".tmp"];
    NSString *tempFilePath = path;
    NSLog(@"文件路径========= %@", tempFilePath);
    
    WSOpenFileOperation *op = [[WSOpenFileOperation alloc] initWithPath:tempFilePath mode:FILEMODE_WRONLY | FILEMODE_TRUNC | FILEMODE_CREATE];
    [self addTask:op];
    
    NSLog(@"打开文件====== %d %d %d", op.filePointer, op.fileSize, op.fileCrc32);

    // 循环写文件
    int writeCount = 128;
    int offset = 0;
    while (offset < data.length) {
        NSData *dataToBeWrite = nil;
        if (data.length - offset > writeCount) {
            dataToBeWrite = [data subdataWithRange:NSMakeRange(offset, writeCount)];
        }else {
            int len = (int)data.length - offset;
            dataToBeWrite = [data subdataWithRange:NSMakeRange(offset, len)];
        }
        
        NSLog(@"dataToBeWrite ====== %@ %d %lu", dataToBeWrite, offset , (unsigned long)data.length);
        
        WSWriteFileOperation *writeOp = [[WSWriteFileOperation alloc] initWithFilePointer:op.filePointer writeData:dataToBeWrite];
        [self addTask:writeOp];
        
        if (NO == writeOp.writeResult) {
            NSLog(@"写失败");
            break;
        }else {
            offset += writeCount;
            NSLog(@"写成功，继续");
        }
     }

    //关闭文件
    WSCloseFileOperation *closeOp = [[WSCloseFileOperation alloc] initWithFilePointer:op.filePointer];
    [self addTask:closeOp];
    
    BOOL closeSuc = closeOp.closeSuc;
    if (closeSuc) {
        NSLog(@"关闭成功");
        
        // 读模式打开文件获取文件大小和crc32
        WSOpenFileOperation *operation = [[WSOpenFileOperation alloc] initWithPath:tempFilePath mode:FILEMODE_RDONLY];
        [self addTask:operation];
        
        //关闭文件
        WSCloseFileOperation *close2Op = [[WSCloseFileOperation alloc] initWithFilePointer:operation.filePointer];
        [self addTask:close2Op];
        
        BOOL close2Suc = close2Op.closeSuc;
        if (close2Suc) {
            NSLog(@"关闭成功");
            return  YES;
            
//            uLong crc = crc32(0, NULL, 0);
//            uLong crcValue = crc32(crc, [data bytes], (uInt)[data length]);
//
//            //NSLog(@"crc ===== -------- %lu  %u", crcValue, operation.fileCrc32);
//
//            if (crcValue == operation.fileCrc32) {
//
//                [self deleteFile:path];
//                [self renameFile:tempFilePath newName:path];
//
//                NSLog(@"重命名成功，整个写文件操作成功～");
//
//                return YES;
//            }else {
//                NSLog(@"crc32校验失败。。。。。。");
//
//                return NO;
//            }
            
        }else {
            return NO;
        }
    }else {
        return NO;
    }
}


- (BOOL)renameFile:(NSString *)oldName newName:(NSString *)newName
{
    WSRenameFileOperation *op = [[WSRenameFileOperation alloc] initWithOldName:oldName newName:newName];
    [self addTask:op];

    NSLog(@"重命名文件结果===== %d", op.renameSuc);

    return op.renameSuc;
}

- (BOOL)deleteFile:(NSString *)filename
{
    WSDeleteFileOperation *op = [[WSDeleteFileOperation alloc] initWithPath:filename];
    [self addTask:op];

    NSLog(@"删除文件结果===== %d", op.deleteSuc);

    return op.deleteSuc;
}

- (BOOL)closeFile:(uint32_t)filePointer
{
    WSCloseFileOperation *closeOp = [[WSCloseFileOperation alloc] initWithFilePointer:filePointer];
    [self addTask:closeOp];
    
    NSLog(@"关闭文件结果===== %d", closeOp.closeSuc);
    return closeOp.closeSuc;
}

@end
