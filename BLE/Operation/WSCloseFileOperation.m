//
//  WSCloseFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSCloseFileOperation.h"

@implementation WSCloseFileOperation

- (id) initWithFilePointer:(uint32_t)pointer
{
    if (self = [super init])
    {
        self.filePointer = pointer;
        self.closeSuc = NO;
        
        uint16_t totalLen = 4;
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pointer, 2);
        
        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_CLOSE_FILE
                                                     param:param];
        free(buffer);
    }
    return self;
}


- (BOOL)parseResponseData:(NSData *)data
{
    self.closeSuc = [super parseResponseData:data];
    return self.closeSuc;
}

@end
