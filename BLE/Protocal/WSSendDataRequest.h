//
//  WSSendDataRequest.h
//  WhiteSoldier
//
//  Created by Glen on 2017/6/13.
//  Copyright © 2017年 ubtech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WSSendDataRequest : NSObject

//haed
//T
//L
//V
//block（TLV）   -------

@property(nonatomic, strong) NSData *packet;                    // 要发送的数据包
@property(nonatomic, assign) uint16_t cmd;                      // 要发送的数据包命令号
@property(nonatomic, assign) NSTimeInterval resendTimeInterval; // 重发时间间隔
@property(nonatomic, assign) NSInteger remainSendCount;         // 剩下重发的次数
@property(nonatomic, assign) BOOL receiveAck;                   //是否收到ack
@property(nonatomic, assign) BOOL completionAck;                //是否收到完整数据包ack

@end
