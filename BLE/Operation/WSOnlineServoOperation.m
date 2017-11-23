//
//  WSOnlineServoOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSOnlineServoOperation.h"


@implementation WSOnlineServoOperation

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN address:DEVICE_ADDRESS_HOST cmd:BASE_CMD_ONLINE_SERVO param:NULL];
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    NSData *paramData = [self paramFromResponseProtocalData:data];
    if (paramData)
    {
        Byte paramLen = [paramData length];
        Byte *cursor = (Byte *)[paramData bytes];
        //最大支持舵机个数（40）
        self.maxServoCount = *cursor;

        cursor += 1;
  
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:paramLen - 1];
        for (int i = 1; i < paramLen; i++)
        {
            int identifier = *cursor;
            if (identifier > 0)
            {
                [temp addObject:@(identifier)];
            }
            
            cursor += 1;
        }
        
        if (temp.count >= 1)
        {
            NSLog(@"舵机列表 === %@", temp);
            self.servoList = [NSArray arrayWithArray:temp];
        }
        
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}

@end
