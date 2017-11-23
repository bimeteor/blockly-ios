//
//  WSWriteServoOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/7/1.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSWriteServoOperation : WSBaseOperation

@property (nonatomic,strong) NSArray *servoList;
@property (nonatomic,strong) NSArray *angleList;
@property (nonatomic,assign) NSTimeInterval runtime;
@property (nonatomic,assign) NSUInteger frameIndex; //当前帧下标

@property (nonatomic,assign) BOOL isSuc;


- (id) initWithServoList:(NSArray *)servoList angles:(NSArray *)angles runtime:(NSTimeInterval)runtime frameIndex:(NSUInteger)frameIndex;

@end
