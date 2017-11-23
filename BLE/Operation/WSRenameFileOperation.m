//
//  WSRenameFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRenameFileOperation.h"

@implementation WSRenameFileOperation

- (id) initWithOldName:(NSString *)oldName newName:(NSString *)newName
{
    if (self = [super init])
    {
        self.oldName = oldName;
        self.name = newName;        
        self.renameSuc = NO;
    
        const char *oldName = [self.oldName UTF8String];
        const char *newName = [self.name UTF8String];
        
        uint16_t oldPathLen = strlen(oldName) + 1;
        uint16_t newPathLen = strlen(newName) + 1;
        
        uint16_t totalLen = oldPathLen + newPathLen + 2 + 2;
        
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        
        memcpy(cursor, &oldPathLen, 2);
        cursor += 2;
        memcpy(cursor, oldName, oldPathLen);
        cursor += oldPathLen;
        memcpy(cursor, &newPathLen, 2);
        cursor += 2;
        memcpy(cursor, newName, newPathLen);
        
        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_RENAME
                                                     param:param];
        free(buffer);
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    self.renameSuc = [super parseResponseData:data];
    return self.renameSuc;
}

@end
