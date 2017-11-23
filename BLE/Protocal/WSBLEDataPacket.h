//
//  WSBLEDataPacket.h
//  WhiteSoldier
//
//  Created by Glen on 2017/6/13.
//  Copyright © 2017年 ubtech. All rights reserved.
//
//  新版协议数据结构

#import <Foundation/Foundation.h>

@interface WSBLEDataPacket : NSObject

- (void)setDevId:(Byte)devId;
- (void)setDevType:(Byte)type;
- (void)setCmd:(uint16_t)cmd;
- (void)setParam:(Byte *)param len:(uint16_t)len;

- (Byte)getDevId;
- (Byte)getDevType;
- (uint16_t)getCmd;
- (Byte *)getParams;
- (uint16_t)getParamLen;

//封包
- (Byte *)packetData:(Byte)head devId:(Byte)devId devType:(Byte)devType cmd:(uint16_t)cmd param:(Byte *)param paramLen:(uint16_t)len;

+ (Byte *)packetData:(Byte)head devId:(Byte)devId devType:(Byte)devType cmd:(uint16_t)cmd param:(Byte *)param paramLen:(uint16_t)len;

//校验
+ (BOOL)isDataPacketValid:(NSData *)data;

//拆包
- (BOOL)parseResponseData:(NSData *)data;

@end
