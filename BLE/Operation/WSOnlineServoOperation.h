//
//  WSOnlineServoOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSOnlineServoOperation : WSBaseOperation

@property (nonatomic,assign) NSUInteger maxServoCount;

@property (nonatomic,strong) NSArray *servoList;

@end
