//
//  BLEManager.m
//  Alpha1S_NewInteractionDesign
//
//  Created by chenlin on 15/8/25.
//  Copyright (c) 2015年 Ubtechinc. All rights reserved.
//

#import "BLEManager.h"
#import "UUID.h"

@implementation BLEManager

#pragma mark - Init Methods

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

- (instancetype)initWithDelegate:(id<BLEManagerDelegate>)delelgate
{
    if (self = [super init])
    {
        self.delegate = delelgate;
        
        NSDictionary *options = @{CBCentralManagerOptionRestoreIdentifierKey: ISSC_RestoreIdentifierKey};
        
        dispatch_queue_t queue = dispatch_queue_create("com.ubt.ble.communication", DISPATCH_QUEUE_SERIAL);
        
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
    }
    
    return self;
}


#pragma mark - Start / Stop Scan

- (void)startScanForServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options
{
    NSLog(@"[BLEManager] start scan");
    
    [self.manager scanForPeripheralsWithServices:serviceUUIDs options:options];
}

- (void) stopScan
{
    NSLog(@"[BLEManager] stop scan");
    [self.manager stopScan];
}

#pragma mark - Connect / Disconnect

- (void)connectPeripheral:(CBPeripheral *) peripheral
{
    [self.manager connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"[BLEManager] disconnectPeripheral %@", peripheral);
    
    [self.manager cancelPeripheralConnection:peripheral];
}

#pragma mark - Send Data
- (void)sendData:(NSData *)data toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [peripheral writeValue:data forCharacteristic:characteristic type:type];
}

#pragma mark - Destroy
- (void)destroy
{
    [self.manager stopScan];
    
    self.manager.delegate = nil;
    self.manager = nil;
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bluetoothStateDidChanged:)])
    {
        [self.delegate bluetoothStateDidChanged:central.state];
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSLog(@"willRestoreState %@",[dict description]);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"发现蓝牙外设 name = %@, adv.name = %@", peripheral.name, advertisementData[@"kCBAdvDataLocalName"]);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didDiscoverPeripheral:advertisementData:RSSI:)])
    {
        [self.delegate didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    if([peripherals count] > 0)
    {
        [self.manager connectPeripheral:[peripherals objectAtIndex:0] options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didConnectPeripheral:)])
    {
        [self.delegate didConnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"蓝牙断开 error = %@", error);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didDisconnectPeripheral:)])
    {
        [self.delegate didDisconnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToConnectPeripheral:)])
    {
        [self.delegate didFailToConnectPeripheral:peripheral];
    }
}

#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didDiscoverServicesForPeripheral:)])
    {
        [self.delegate didDiscoverServicesForPeripheral:peripheral];
    }    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:)])
    {
        [self.delegate peripheral:peripheral didDiscoverCharacteristicsForService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(peripheral:didReceiveTransparentData:)])
    {
        [self.delegate peripheral:peripheral didReceiveTransparentData:characteristic.value];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //NSLog(@"写数据成功回调 %@ %@", characteristic.UUID, characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"  %s ", __func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"  %s ", __func__);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //NSLog(@"Notification方式  characteristic.UUID = %@, characteristic.value = %@",characteristic.UUID, characteristic.value);
}

@end
