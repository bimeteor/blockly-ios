//
//  WSWriteFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSWriteFileOperation.h"

@implementation WSWriteFileOperation


- (id) initWithFilePointer:(uint32_t)pointer writeData:(NSData *)bytes;
{
    if (self = [super init])
    {
        self.filePointer = pointer;
        self.bytesForWrite = bytes;
        
        uint16_t bytesLen = [bytes length];
        
        uint16_t totalLen = 4 + 2 + bytesLen;   //filePointer(4B) + len(2B) + bytesLen
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pointer, 2);
        
        cursor += 4;
        memcpy(cursor, &bytesLen, 2);
        
        cursor += 2;
        memcpy(cursor, [bytes bytes], bytesLen);
        
        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_WRITE_FILE
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
        
        self.writeResult = *(uint16_t *)cursor;
        
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}
@end
