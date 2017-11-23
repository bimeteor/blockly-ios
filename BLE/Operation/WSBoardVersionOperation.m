//
//  WSBoardVersionOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBoardVersionOperation.h"

@implementation WSBoardVersionOperation


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN address:DEVICE_ADDRESS_HOST cmd:BASE_CMD_VERSION param:NULL];
    }
    
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    NSData *param = [self paramFromResponseProtocalData:data];
    if (param)
    {
        Byte *cursor = (Byte *)[param bytes];
        uint16_t bufferSize = *(uint16_t *)cursor;
        
        cursor += 2;
        uint16_t version = *(uint16_t *)cursor;
        NSString *versionString = [NSString stringWithFormat:@"%d.%d.%d.%d", (version & 0xF000) >> 12, (version & 0x0F00) >> 8, (version & 0x00F0) >> 4, version & 0x000F];
        
        self.bufferSize = bufferSize;
        self.versionString = versionString;
        
        return YES;
    }
    return NO;
}

@end
