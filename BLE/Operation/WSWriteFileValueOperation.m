//
//  WSWriteFileValueOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSWriteFileValueOperation.h"

@implementation WSWriteFileValueOperation

- (id) initWithPath:(NSString *)path name:(NSString *)name value:(int32_t)value
{
    if (self = [super init])
    {
        self.path = path;
        self.name = name;
        self.value = value;
        self.isWriteSuc = NO;

        const char *p = [self.path UTF8String];
        const char *n = [self.name UTF8String];
        
        uint16_t pathLen = strlen(p) + 1;
        uint16_t nameLen = strlen(n) + 1;
        
        uint16_t totalLen = pathLen + nameLen + 4 + 4;  //path长度（2B) + name长度(2B) + value（4B）
        
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pathLen, 2);
        cursor += 2;
        memcpy(cursor, p, pathLen);
        cursor += pathLen;
        memcpy(cursor, &nameLen, 2);
        cursor += 2;
        memcpy(cursor, n, nameLen);
        cursor += nameLen;
        int32_t value = self.value;
        memcpy(cursor, &value, 4);
        
        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:MAINBOARD_CMD_JSON_FILE_WRITE
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
        self.isWriteSuc = YES;
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}

@end
