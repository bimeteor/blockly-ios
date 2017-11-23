//
//  WSBaseOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@implementation WSBaseOperation


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.remainSendCount = 2;
        self.resendTimeInterval = 500.00;
        self.receiveAck = NO;
        self.completionAck = NO;
        
        self.condition = [[NSCondition alloc] init];
        
    }
    return self;
}

- (NSData *)packageRequestData
{
    if (self.block == nil)
    {
        NSLog(@"没有命令消息块，无法打包!!!, %@", self);
        return nil;
    }
    
    Byte head = 0x4D;
    //Byte end = 0x0A;

    Byte *blockContent = NULL;
    int blockSize = [self.block blockBytes:&blockContent];
    
    int totalLen = blockSize + 2;   //2 = head(1B) + totalLen(1B)
    
    Byte *buffer = malloc(sizeof(Byte) * totalLen);
    
    if (buffer)
    {
        Byte *cursor = buffer;
        memset(cursor, 0, totalLen);
        
        memcpy(cursor, &head, 1);
        cursor += 1;
        memcpy(cursor, &totalLen, 1);
        cursor += 1;
        
        memcpy(cursor, blockContent, blockSize);
        cursor += blockSize;
        
        //CRC
        uint16_t crc8 = CRC8_MAXIM(buffer, totalLen, 0x8C, 0x12);    //CRC8
        crc8 |= ('\n' << 8);  //帧尾

        memcpy(cursor, &crc8,sizeof(crc8));     //copy crc
        
        NSUInteger nLens = totalLen + 2;  //总长 + 校验(1B) + 0A(1B)
        NSData *pData = [NSData dataWithBytes:buffer length:nLens];
        
        free(buffer);
        free(blockContent);
        
        return pData;
    }else
    {
        NSLog(@"内存开辟失败！！");
        free(blockContent);
        return nil;
    }
}

//校验
+ (BOOL)isDataPacketValid:(NSData *)data
{
    if (data == nil)
    {
        return NO;
    }
    
    BOOL pRes = NO;
    Byte *dataByte = (Byte *)[data bytes];
    Byte dataLen = [data length];
    if (dataByte[0] == 0x53)
    {
        Byte packetLen = dataByte[1];   //包长
        if (packetLen < dataLen)
        {
            //帧尾
            if (dataByte[packetLen + 1] == 0x0A)
            {
                //校验
                Byte *packet = (Byte *)malloc(packetLen);
                memset(packet, 0, packetLen);
                memcpy(packet, dataByte, packetLen);
                
                uint16_t tCRC8 = CRC8_MAXIM(packet, packetLen, 0x8C, 0x12);    //CRC8
                
                if (tCRC8 == dataByte[packetLen])
                {
                    pRes = YES;
                }else
                {
                    NSLog(@"返回数据异常, 校验值不对！！");
                    pRes = NO;
                }
                
                free(packet);
            }else
            {
                NSLog(@"返回数据异常, 没找到帧尾！！");
                pRes = NO;
            }
        }else
        {
            NSLog(@"返回数据异常, 数据总长小于包长！！");
            pRes = NO;
        }
    }else
    {
        NSLog(@"返回数据异常, 没找到帧头！！");
        pRes = NO;
    }
    
    return pRes;
}

//拆包
- (BOOL)parseResponseData:(NSData *)data
{
    //Override by subclass
    if (data != nil)
    {
        return YES;
    }
    return NO;
}

- (NSData *)paramFromResponseProtocalData:(NSData *)responseData
{
    if (responseData == nil)
    {
        return nil;
    }
    
    if (![WSBaseOperation isDataPacketValid:responseData])
    {
        NSLog(@"数据格式不正确！！");
        return nil;
    }
    
    Byte *dataByte = (Byte *)[responseData bytes];
    Byte length = [responseData length];
    
    Byte blockSize = dataByte[1] - 2;   //减掉帧头0x53和长度本身
    if (blockSize >= length)
    {
        NSLog(@"数据总长度不对！！！");
        return nil;
    }else
    {
        Byte offset = 6;  //head(1B) + totalLen(1B) + address(1B) + Type(1B) + cmd(2B)
        if (offset < length)
        {
            int16_t paramLen = ((dataByte[offset] & 0xFF) | ((dataByte[offset+1] & 0xFF)<<8));
            if (paramLen < 0)
            {
                NSLog(@"消息块参数长度为负值，不解析参数内容");
                return nil;
            }else
            {
                if (offset + 2 + paramLen <= responseData.length)
                {
                    NSData *paramData = [responseData subdataWithRange:NSMakeRange(offset+2, paramLen)];
                    return paramData;
                }else
                {
                    NSLog(@"消息块参数长度不对！data = %@", responseData);
                    return nil;
                }
            }
        }else
        {
            NSLog(@"消息块长度不对！！");
            return nil;
        }
    }
}



@end
