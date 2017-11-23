//
//  WSRobotManager+Servo.m
//  StormtrooperS
//
//  Created by Glen on 2017/7/3.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager+Servo.h"
#import "WSReadServoOperation.h"
#import "WSWriteServoOperation.h"

@implementation WSRobotManager (Servo)

- (NSDictionary *)readbackServoAngle:(NSArray *)servoList
{
    WSReadServoOperation *op = [[WSReadServoOperation alloc] initWithServoList:servoList];
    [self addTask:op];
    
    return op.angleDict;
}

- (BOOL)writeServo:(NSArray *)servoList angleList:(NSArray *)angleList runtime:(NSTimeInterval)runtime frameIndex:(NSUInteger)frameIndex
{
    WSWriteServoOperation *op = [[WSWriteServoOperation alloc] initWithServoList:servoList angles:angleList runtime:runtime frameIndex:frameIndex];
    op.remainSendCount = 1;
    [self addTask:op];
    
    return op.isSuc;
}

@end
