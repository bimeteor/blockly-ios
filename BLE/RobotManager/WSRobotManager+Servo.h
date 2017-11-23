//
//  WSRobotManager+Servo.h
//  StormtrooperS
//
//  Created by Glen on 2017/7/3.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager.h"

@interface WSRobotManager (Servo)

- (NSDictionary *)readbackServoAngle:(NSArray *)servoList;

- (BOOL)writeServo:(NSArray *)servoList angleList:(NSArray *)angleList runtime:(NSTimeInterval)runtime frameIndex:(NSUInteger)frameIndex;

@end
