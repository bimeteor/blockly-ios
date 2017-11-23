//
//  WSBaseOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSBLEProtocalHeader.h"
#import "WSProtocalBlock.h"

@interface WSBaseOperation : NSObject

@property (nonatomic,strong) WSProtocalBlock *block;    //消息块（一个request应该可以扩展成多个block，但目前没有这种多发的情况，暂时不用数组）

@property(nonatomic, assign) NSTimeInterval resendTimeInterval; // 重发时间间隔
@property(nonatomic, assign) NSInteger remainSendCount;         // 剩下重发的次数
@property(nonatomic, assign) BOOL receiveAck;                   //是否收到ack
@property(nonatomic, assign) BOOL completionAck;                //是否收到完整数据包ack

@property (nonatomic,strong) NSCondition *condition;

//校验
+ (BOOL)isDataPacketValid:(NSData *)data;

//封包
- (NSData *)packageRequestData;

//拆包
- (BOOL)parseResponseData:(NSData *)data;

//从数据包中解析出param
- (NSData *)paramFromResponseProtocalData:(NSData *)responseData;

@end
