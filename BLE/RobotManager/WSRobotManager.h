//
//  WSRobotManager.h
//  WhiteSoldier
//
//  Created by Glen on 16/8/6.
//  Copyright © 2016年 ubtech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "WSRobotPeripheral.h"
#import "WSBLEDataPacket.h"
#import "WSSendDataRequest.h"
#import "WSBaseOperation.h"

FOUNDATION_EXPORT NSString * const WSBLEConnectingNotification;
FOUNDATION_EXPORT NSString * const WSBLEFindNewPerpheralNotification;
FOUNDATION_EXPORT NSString * const WSBLEConnectSuccessNotification;
FOUNDATION_EXPORT NSString * const WSBLEConnectFailedNotification;
FOUNDATION_EXPORT NSString * const WSBLEDisconnectNotification;
FOUNDATION_EXPORT NSString * const WSBLEStateUpdateNotification;
FOUNDATION_EXPORT NSString * const WSBLEReadyForCommunicateNotification;
FOUNDATION_EXPORT NSString * const WSBLERecieveResponseNotification;

typedef NS_ENUM(NSInteger, WSBluetoothState) {
    WSBluetoothStateUnknown = 0,
    WSBluetoothStateResetting,
    WSBluetoothStateUnsupported,
    WSBluetoothStateUnauthorized,
    WSBluetoothStatePoweredOff,
    WSBluetoothStatePoweredOn,
};

@interface WSRobotManager : NSObject

@property(nonatomic, getter=isConnect, readonly) BOOL connect;
@property(nonatomic, assign, readonly) BOOL charging;           //是否充电
@property(nonatomic, assign) NSUInteger frameDataMaxLength;      //数据包最大包长
@property(nonatomic, strong) NSMutableArray *motorIdentifiers;  //舵机编号列表
@property(nonatomic, strong, readonly) NSMutableArray *perpheralList;
@property(nonatomic, strong, readonly) NSMutableArray *connectedList;

+ (instancetype)sharedManager;

- (WSBluetoothState)bluetoothState;

- (void)startScan;

- (void)stopScan;

- (void)connectToPeripheral:(WSRobotPeripheral *)peripheral;

- (void)disconnectToPeripheral:(WSRobotPeripheral *)peripheral;

- (void)disconnectToAllPeripheral;

- (void)destroyManager;

- (void)cancelAllTask;

/**
 添加命令操作到队列中

 @param baseOp <#baseOp description#>
 */
- (void)addTask:(WSBaseOperation *)baseOp;

//旧协议（deprecated）
- (void)sendCmd:(Byte)cmd param:(Byte *)param length:(int)length;

//新协议（deprecated）
- (void)sendCmd:(uint16_t)cmd deviceId:(Byte)dev_id deviceType:(Byte)dev_type param:(Byte *)param paramLen:(uint16_t)len;

@end


