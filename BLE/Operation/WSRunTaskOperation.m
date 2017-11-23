//
//  WSRunTaskOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRunTaskOperation.h"

@implementation WSRunTaskOperation

- (id) initWithPath:(NSString *)path role:(WSRoleType)role
{
    if (self = [super init])
    {
        self.path = path;
        self.role = role;
        self.isStartSuc = NO;

        const char *p = [self.path UTF8String];
        uint16_t pathLen = strlen(p) + 1;
        uint16_t totalLen = pathLen + 2;
        totalLen += (self.role == WSRoleMaster ? 0 : (1 + 4));   //添加熟人需要参数，paramLen(1B) + param(4B)
        
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pathLen, 2);
        cursor += 2;
        memcpy(cursor, p, pathLen);
        cursor += pathLen;
        if (self.role != WSRoleMaster)
        {
            Byte len = 1;
            int32_t role = self.role;
            memcpy(cursor, &len, 1);
            
            cursor += 1;
            memcpy(cursor, &role, 4);
        }

        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:MAINBOARD_CMD_TASK_RUN
                                                     param:param];
        free(buffer);
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    self.isStartSuc = [super parseResponseData:data];
    return self.isStartSuc;
}

@end



