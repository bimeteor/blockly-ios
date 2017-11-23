//
//  WSRobotPeripheral.h
//  WhiteSoldier
//
//  Created by Glen on 2017/6/21.
//  Copyright © 2017年 ubtech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBPeripheral.h>

//typedef NS_ENUM(NSUInteger, WSBLEConnectState) {
//    WSBLEConnectingState,   //连接中
//    WSBLEConnectedState,    //已连接
//    WSBLEUnconnectedState,  //未连接
//    WSBLEConnectTimeoutState,//连接超时
//};

@interface WSRobotPeripheral : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, strong) NSDictionary *advertisementData;

@property (nonatomic, strong) CBCharacteristic *transparentDataWriteChar;
@property (nonatomic, strong) CBCharacteristic *transparentDataReadChar;

@property (nonatomic, assign) BOOL isSelected;

//@property (nonatomic, assign) BOOL connectStatus;

@end
