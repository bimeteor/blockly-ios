//
//  WSReadServoOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/7/1.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSReadServoOperation.h"
#import "HTSFileArchive.h"

@implementation WSReadServoOperation

- (id) initWithServoList:(NSArray *)list
{
    if (self = [super init])
    {
        self.validServoList = [NSArray arrayWithArray:list];
        
        if (self.validServoList.count <= 0)
        {
            NSLog(@"请传入需要回读的舵机列表");
        }else
        {
            int servoListLen = (int)self.validServoList.count;
            int *servoIds = malloc(sizeof(int) * servoListLen);
            for (int i = 0; i < servoListLen; i++)
            {
                NSNumber *idNumber = self.validServoList[i];
                servoIds[i] = [idNumber intValue];
            }
            
            byte *param = NULL;
            int paramLen = 0;
            bool ret = GetCmdParamByMotorList(servoIds, servoListLen, true, &param, &paramLen);
            if (ret)
            {
                NSData *paramData = [NSData dataWithBytes:param length:paramLen];
                self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_SERVO
                                                           address:DEVICE_ADDRESS_MULTICAST
                                                               cmd:BASE_CMD_BROADCAST
                                                             param:paramData];
            }else
            {
                NSLog(@"回读命令转换失败，请检查舵机列表是否为空！");
            }
            
            free(param);
            free(servoIds);
        }
    }
    return self;
}

- (BOOL)parseResponseData:(NSData *)data
{
    NSData *paramData = [self paramFromResponseProtocalData:data];
    if (paramData)
    {
        Byte *cursor = (Byte *)[paramData bytes];
        
        cursor += 6;    //0104 FFFF FFFF (opt和设备类型，以及4位占位符)
        
        //参数内容
        NSMutableDictionary *motorAnglesDict = [NSMutableDictionary dictionaryWithCapacity:1];
        int bit2Len = 0;    //二级有效位长度
        Byte *bit1P = cursor; //一级有效位
        int bit1Value = *bit1P;
        while (bit1Value > 0)
        {
            bit2Len++;
            bit1Value >>= 1;
        }
        
        Byte *bit2P = bit1P + 1; //二级有效位
        Byte *angleP = bit2P + bit2Len; //角度起始位置
        for (int ii = 0; ii < 8; ii++)
        {
            if (*bit1P & 1 << ii)
            {
                //如果一级有效位为1，检查二级有效位
                for (int jj = 0; jj < 8; jj++)
                {
                    if (*bit2P & 1 << jj)
                    {
                        //如果二级有效位位1，读取对应的角度
                        int motorId = ii*8+jj + 1;  //舵机角度从1号开始
                        int motorAngle = *angleP++;
                        
                        //参数1 16B（对应1-16号舵机的角度）：FF，舵机没应答，FE，舵机ID不对，2，舵机角度
                        if (motorAngle != 0xFF && motorAngle != 0xFE)
                        {
                            [motorAnglesDict setObject:@(motorAngle) forKey:[NSString stringWithFormat:@"%d", motorId]];
                            printf("  %d (%d)", motorAngle, motorId);
                        }
                    }
                }
                
                printf("\n");
                
                bit2P++;
            }
        }
        
        if (motorAnglesDict.allKeys.count <= 0)
        {
            NSLog(@"回读失败,下机位返回舵机角度位0或无角度参数");
            return NO;
        }else
        {
            self.angleDict = [NSDictionary dictionaryWithDictionary:motorAnglesDict];
            NSLog(@"回读成功");
            return YES;
        }
    }else
    {
        NSLog(@"没有舵机参数数据,读取失败");
        return NO;
    }
}



@end
