//
//  WSOpenFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSOpenFileOperation.h"

@implementation WSOpenFileOperation

- (id) initWithPath:(NSString *)path mode:(FILEMODE)mode
{
    if (self = [super init])
    {
        self.filePath = path;
        self.fileMode = mode;
        
        const char *path = [self.filePath UTF8String];
        uint32_t fileMode = self.fileMode;
        
        uint16_t pathLen = strlen(path) + 1;
        
        uint16_t totalLen = pathLen + 2 + 4;    //length(2B) + fileMode(4B)
        
        Byte *buffer = (Byte *)malloc(totalLen);
        memset(buffer, 0, totalLen);
        Byte *cursor = buffer;
        memcpy(cursor, &pathLen, 2);
        cursor += 2;
        memcpy(cursor, path, pathLen);
        cursor += pathLen;
        memcpy(cursor, &fileMode, 4);
        
        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_OPEN_FILE
                                                     param:param];
        free(buffer);
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    NSData *paramData = [self paramFromResponseProtocalData:data];
    if (paramData)
    {
        Byte *cursor = (Byte *)[paramData bytes];

        self.filePointer = *(uint32_t *)cursor;
        cursor += 4;

        self.fileSize = *(uint32_t *)cursor;
        cursor += 4;
        
        self.fileCrc32 = *(uint32_t *)cursor;
        
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}


@end
