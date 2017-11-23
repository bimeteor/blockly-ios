//
//  WSDeleteFileOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSDeleteFileOperation.h"

@implementation WSDeleteFileOperation

- (id) initWithPath:(NSString *)path
{
    if (self = [super init])
    {
        self.filePath = path;
        self.deleteSuc = NO;

        const char *path = [self.filePath UTF8String];
        uint16_t pathLen = strlen(path) + 1;

        uint16_t totalLen = pathLen + 2;
        Byte *buffer = malloc(sizeof(Byte *) * totalLen);
        memset(buffer, 0, totalLen);
        
        Byte *cursor = buffer;
        memcpy(cursor, &pathLen, 2);
        cursor += 2;
        memcpy(cursor, path, pathLen);

        NSData *param = [NSData dataWithBytes:buffer length:totalLen];
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN
                                                   address:DEVICE_ADDRESS_HOST
                                                       cmd:BASE_CMD_DELETE
                                                     param:param];
        free(buffer);
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    self.deleteSuc = [super parseResponseData:data];
    return self.deleteSuc;
}


@end
