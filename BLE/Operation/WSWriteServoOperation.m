//
//  WSWriteServoOperation.m
//  StormtrooperS
//
//  Created by Glen on 2017/7/1.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSWriteServoOperation.h"
#import "HTSFileArchive.h"


@implementation WSWriteServoOperation

- (id) initWithServoList:(NSArray *)servoList angles:(NSArray *)angles runtime:(NSTimeInterval)runtime frameIndex:(NSUInteger)frameIndex
{
    if (self = [super init])
    {
        self.servoList = servoList;
        self.angleList = angles;
        self.runtime = runtime;
        self.frameIndex = frameIndex;
        
        [self setupBlock];
    }
    return self;
}

- (void)setupBlock
{
    if (self.servoList == nil || self.angleList == nil || self.servoList.count != self.angleList.count)
    {
        NSLog(@"舵机列表、角度列表不能为空，并且长度必须一致");
    }else
    {
        ActionFrameData fdata;
        int angleListLen = (int)self.angleList.count;
        fdata.motorAngles = malloc(sizeof(int) * angleListLen);
        fdata.motorIdentifiers = malloc(sizeof(int) * angleListLen);
        
        int index = 0;
        for (int i = 0; i < angleListLen; i++, index++)
        {
            NSNumber *angle = self.angleList[i];
            if ([angle intValue] > 0)
            {
                fdata.motorIdentifiers[i] = [self.servoList[i] intValue];
                fdata.motorAngles[i] = [angle intValue];
            }
        }
        
        fdata.runtime = self.runtime;
        fdata.totaltime = self.runtime;
        fdata.motorCount = index;
        
        int frameIndex = (int)self.frameIndex;
        byte *param = NULL;
        int paramLen = 0;
        bool ret = GetCmdParamByFrameData(frameIndex, fdata, true, &param, &paramLen);
        if (ret)
        {
            NSData *paramData = [NSData dataWithBytes:param length:paramLen];
            self.block = [[WSProtocalBlock alloc] initWithType:DEVICE_SERVO
                                                       address:DEVICE_ADDRESS_MULTICAST
                                                           cmd:BASE_CMD_BROADCAST
                                                         param:paramData];
        }else
        {
            NSLog(@"0x23命令参数转换失败,请检查舵机数据是否为空！可用舵机列表 %@, 该帧动作舵机角度数据 %@", self.servoList, self.angleList);
        }
        
        free(fdata.motorAngles);
        free(fdata.motorIdentifiers);
        free(param);
    }
}

- (BOOL)parseResponseData:(NSData *)data
{
    BOOL valid = [WSBaseOperation isDataPacketValid:data];
    if (valid)
    {
        self.isSuc = YES;
        return YES;
    }else
    {
        return NO;
    }
}

@end

