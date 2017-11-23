//
//  BLEManager.h
//  Alpha1S_NewInteractionDesign
//
//  Created by chenlin on 15/8/25.
//  Copyright (c) 2015年 Ubtechinc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BLEManagerDelegate;

@interface BLEManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, weak) id<BLEManagerDelegate> delegate;

- (instancetype)initWithDelegate:(id<BLEManagerDelegate>)delelgate NS_DESIGNATED_INITIALIZER;

- (void)startScanForServices:(NSArray<CBUUID *> *)serviceUUIDs options:(NSDictionary<NSString *, id> *)options;

- (void)stopScan;

- (void)connectPeripheral:(CBPeripheral *) peripheral;

- (void)disconnectPeripheral:(CBPeripheral *)peripheral;

- (void)sendData:(NSData *)data toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;

- (void)destroy;

@end



@protocol BLEManagerDelegate<NSObject>

@optional

/**
 发现蓝牙设备
 
 @param peripheral 外设
 @param advertisementData adv
 @param RSSI rssi
 */
- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;


- (void)didDiscoverServicesForPeripheral:(CBPeripheral *)peripheral;

/**
 蓝牙状态发生变化
 
 @param state 蓝牙当前状态
 */
- (void)bluetoothStateDidChanged:(NSInteger)state;

/**
 蓝牙已连接成功
 
 @param peripheral 连接成功的外设
 */
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;

/**
 蓝牙连接失败
 
 @param peripheral 连接失败的外设
 */
- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral;

/**
 蓝牙已断开连接
 
 @param peripheral 断开连接的外设
 */
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral;


/**
 确认外设的读和写特征值（收发指令需要指定的特征值，这个回调表明可以向外设收发送指令）
 
 @param peripheral 外设
 @param service 特征值所属服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service;

/**
 下机位回复回调
 
 @param peripheral 外设
 @param data 回复数据包
 */
- (void)peripheral:(CBPeripheral *)peripheral didReceiveTransparentData:(NSData *)data;

@end

