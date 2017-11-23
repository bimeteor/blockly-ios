//
//  WSRetrieveTaskStateOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRetrieveTaskStateOperation.h"

@implementation WSRetrieveTaskStateOperation

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_MAIN address:DEVICE_ADDRESS_HOST cmd:MAINBOARD_CMD_TASK_STATE param:NULL];
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    NSData *paramData = [self paramFromResponseProtocalData:data];
    if (paramData)
    {
        Byte *cursor = (Byte *)[paramData bytes];

        self.state = *(int32_t *)cursor;
        
        return YES;
    }else
    {
        NSLog(@"没有舵机参数数据");
        return NO;
    }
}
@end
