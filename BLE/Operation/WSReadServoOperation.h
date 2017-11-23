//
//  WSReadServoOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/7/1.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSReadServoOperation : WSBaseOperation

@property (nonatomic,strong) NSArray *validServoList;   //回读舵机编号列表

@property (nonatomic,strong) NSDictionary *angleDict;

- (id) initWithServoList:(NSArray *)list;

@end
