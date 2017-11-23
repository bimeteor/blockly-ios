//
//  WSSendDataRequest.m
//  WhiteSoldier
//
//  Created by Glen on 2017/6/13.
//  Copyright © 2017年 ubtech. All rights reserved.
//

#import "WSSendDataRequest.h"

@implementation WSSendDataRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.remainSendCount = 2;
        self.resendTimeInterval = 300.00;
        self.receiveAck = NO;
        self.completionAck = NO;
    }
    return self;
}

@end
