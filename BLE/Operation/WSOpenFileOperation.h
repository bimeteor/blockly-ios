//
//  WSOpenFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSOpenFileOperation : WSBaseOperation

@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,assign) FILEMODE fileMode;

@property (nonatomic,assign) uint32_t filePointer;  // 文件句柄
@property (nonatomic,assign) uint32_t fileSize;     // 文件大小
@property (nonatomic,assign) uint32_t fileCrc32;    // 文件crc32校验

- (id) initWithPath:(NSString *)path mode:(FILEMODE)mode;

@end
