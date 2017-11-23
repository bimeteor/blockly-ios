//
//  WSBLEDataPacket.m
//  WhiteSoldier
//
//  Created by Glen on 2017/6/13.
//  Copyright © 2017年 ubtech. All rights reserved.
//

#import "WSBLEDataPacket.h"
#import "WSBLEProtocalHeader.h"

@interface WSBLEDataPacket ()
{
    uint16_t _CMD;
    Byte _devId;
    Byte _devType;
    NSMutableData *_param;
    uint16_t _paramLen;
}
@end

@implementation WSBLEDataPacket

- (instancetype)init
{
    self = [super init];
    if (self) {
        _param = [NSMutableData new];
    }
    return self;
}

#pragma mark - Public methods
- (void)setDevId:(Byte)devId {
    self->_devId = devId;
}
- (void)setDevType:(Byte)type {
    self->_devType = type;
}
- (void)setCmd:(uint16_t)cmd {
    self->_CMD = cmd;
}
- (void)setParam:(Byte *)param len:(uint16_t)len {
    [_param resetBytesInRange:NSMakeRange(0, [_param length])];
    [_param setLength:0];
    
    if (param == NULL || len == 0) {
        return;
    }
    
    [_param appendBytes:param length:len];
    self->_paramLen = len;
}

- (Byte)getDevId {
    return self->_devId;
}
- (Byte)getDevType{
    return self->_devType;
}
- (uint16_t)getCmd {
    return self->_CMD;
}
- (Byte *)getParams {
    return (Byte *)[self->_param bytes];
}

- (uint16_t)getParamLen {
    return self->_paramLen;
}

- (Byte *)packetData:(Byte)head devId:(Byte)devId devType:(Byte)devType cmd:(uint16_t)cmd param:(Byte *)param paramLen:(uint16_t)len {
  
    Byte tTotal_len = 0;   //单字节
    uint16_t tCRC8 = 0;
    Byte *buf = 0;
    
    tTotal_len = sizeof(tTotal_len) + 1;
    buf = (Byte *)malloc(len + 10); //10 = Header(1B) totallen(1B) + ID(1B) + Type(1B) + cmd(2B) + cmdLen(2B) + CRC8(1B) + End(1B)
    
    if (buf) {
        buf[0] = head;
        sPacket *packet = (sPacket *)&buf[1 + sizeof(tTotal_len)];
        packet->DEV_ID = devId;
        packet->DEV_TYPE = devType;
        packet->CMD = cmd;
        packet->PARAM_LEN = len;
        
        memcpy((void *)((Byte *)packet + sizeof(sPacket)), (void *)param, len);
        
        tTotal_len += len + sizeof(sPacket); //总长
        
        memcpy((void *)&buf[1],(void *)&tTotal_len,sizeof(tTotal_len)); //copy total len
        
        tCRC8 = CRC8_MAXIM(buf, buf[1], 0x8C, 0x12);    //CRC8
        tCRC8 |= ('\n' << 8);  //帧尾
        memcpy((void *)&buf[buf[1]], (void *)&tCRC8,sizeof(tCRC8));	//copy crc
    }
    
    return buf;
}


+ (Byte *)packetData:(Byte)head devId:(Byte)devId devType:(Byte)devType cmd:(uint16_t)cmd param:(Byte *)param paramLen:(uint16_t)len {
    
    Byte tTotal_len = 0;   //单字节
    uint16_t tCRC8 = 0;
    Byte *buf = 0;
    
    tTotal_len = sizeof(tTotal_len) + 1;
    buf = (Byte *)malloc(len + 10); //10 = Header(1B) totallen(1B) + ID(1B) + Type(1B) + cmd(2B) + cmdLen(2B) + CRC8(1B) + End(1B)
    
    if (buf) {
        buf[0] = head;
        sPacket *packet = (sPacket *)&buf[1 + sizeof(tTotal_len)];
        packet->DEV_ID = devId;
        packet->DEV_TYPE = devType;
        packet->CMD = cmd;
        packet->PARAM_LEN = len;
        
        memcpy((void *)((Byte *)packet + sizeof(sPacket)), (void *)param, len);
        
        tTotal_len += len + sizeof(sPacket); //总长
        
        memcpy((void *)&buf[1],(void *)&tTotal_len,sizeof(tTotal_len)); //copy total len
        
        tCRC8 = CRC8_MAXIM(buf, buf[1], 0x8C, 0x12);    //CRC8
        tCRC8 |= ('\n' << 8);  //帧尾
        memcpy((void *)&buf[buf[1]], (void *)&tCRC8,sizeof(tCRC8));	//copy crc
    }
    
    return buf;
}


+ (BOOL)isDataPacketValid:(NSData *)data {

    BOOL pRes = NO;
    if (data != nil) {
        Byte *dataByte = (Byte *)[data bytes];
        Byte dataLen = [data length];
        if (dataByte[0] == 0x53) {
            Byte packetLen = dataByte[1];   //包长
            if (packetLen < dataLen) {
                //帧尾
                if (dataByte[packetLen + 1] == 0x0A) {
                    //校验
                    Byte *packet = (Byte *)malloc(packetLen);
                    memset(packet, 0, packetLen);
                    memcpy(packet, dataByte, packetLen);
                    
                    uint16_t tCRC8 = CRC8_MAXIM(packet, packetLen, 0x8C, 0x12);    //CRC8
                    
                    if (tCRC8 == dataByte[packetLen]) {
                        pRes = YES;
                    }else {
                        NSLog(@"返回数据异常, 校验值不对！！");
                        pRes = NO;
                    }
                    
                    free(packet);
                }else {
                    NSLog(@"返回数据异常, 没找到帧尾！！");
                    pRes = NO;
                }
            }else {
                NSLog(@"返回数据异常, 数据总长小于包长！！");
                pRes = NO;
            }
        }else {
            NSLog(@"返回数据异常, 没找到帧头！！");
            pRes = NO;
        }
    }

    return pRes;
}

- (BOOL)parseResponseData:(NSData *)data {

    BOOL valid = [WSBLEDataPacket isDataPacketValid:data];
    
    if (valid) {
        Byte *dataByte = (Byte *)[data bytes];
        
        Byte *pPkgCursor = dataByte;
        pPkgCursor += 2;    //帧头，总长
        
        //设备号
        [self setDevId:*pPkgCursor];
        
        //设备类型
        pPkgCursor += 1;
        [self setDevType:*pPkgCursor];
        
        //命令号（双字节）
        pPkgCursor += 1;
        [self setCmd:*(uint16_t *)pPkgCursor];
        
        pPkgCursor += 2;
        uint16_t paramLen = *(uint16_t *)pPkgCursor;
        
        pPkgCursor += 2;
        [self setParam:pPkgCursor len:paramLen];
        
        return YES;
    }else {
        return NO;
    }
}
        

@end
