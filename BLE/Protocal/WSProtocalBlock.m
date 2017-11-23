//
//  WSProtocalBlock.m
//  StormtrooperS
//
//  Created by Glen on 2017/7/5.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSProtocalBlock.h"

@implementation WSProtocalBlock

- (id)initWithType:(Byte)type address:(Byte)address cmd:(uint16_t)cmd param:(NSData *)param
{
    if (self = [super init])
    {
        _type = type;
        _address = address;
        _command = cmd;
        _length = [param length];
        _param = [[NSMutableData alloc] initWithData:param];
    }
    
    return self;
}

- (uint16_t)getCommand
{
    return _command;
}

- (int)blockBytes:(Byte **)bytes
{
    Byte totalLen = 6 + _length;   //6 = address(1B) + Type(1B) + cmd(2B) + length(2B) + param(nB)
    
    *bytes = malloc(sizeof(Byte) * totalLen);
    if (*bytes)
    {
        memset(*bytes, 0, totalLen);
        
        Byte *cursor = *bytes;
        
        memcpy(cursor, &_address, 1);
        cursor += 1;
        memcpy(cursor, &_type, 1);
        cursor += 1;
        memcpy(cursor, &_command, 2);
        cursor += 2;
        memcpy(cursor, &_length, 2);
        cursor += 2;
        memcpy(cursor, [_param bytes], _length);
    }
    
    return totalLen;
}


@end
