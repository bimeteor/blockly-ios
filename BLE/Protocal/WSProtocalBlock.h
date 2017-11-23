//
//  WSProtocalBlock.h
//  StormtrooperS
//
//  Created by Glen on 2017/7/5.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WSProtocalBlock : NSObject
{
    Byte _type;
    Byte _address;
    uint16_t _command;
    int16_t _length;
    NSMutableData *_param;
}

- (uint16_t)getCommand;

- (id)initWithType:(Byte)type address:(Byte)address cmd:(uint16_t)cmd param:(NSData *)param;

- (int)blockBytes:(Byte **)bytes;

@end
