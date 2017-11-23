//
//  WSReadFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSReadFileOperation.h"

@implementation WSReadFileOperation

- (id) initWithFilePointer:(uint32_t)pointer readBytes:(uint16_t)bytes
{
    if (self = [super init])
    {
        self.filePointer = pointer;
        self.bytes = bytes;
        
        uint16_t totalLen = 4 + 2;
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pointer, 2);
        
        cursor += 4;
        memcpy(cursor, &bytes, 2);

        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_READ_FILE
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
        
        uint16_t fileSize = *(uint16_t *)cursor;
        cursor += 2;
        
        self.data = [NSData dataWithBytes:cursor length:fileSize];
        
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}


@end
