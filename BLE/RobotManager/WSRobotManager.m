//
//  WSRobotManager.m
//  WhiteSoldier
//
//  Created by Glen on 16/8/6.
//  Copyright © 2016年 ubtech. All rights reserved.
//

#import "WSRobotManager.h"

#import "BLEManager.h"
#import "UUID.h"
#import "GlobalBLEProtocal.h"
#import "WSBLEProtocalHeader.h"
#import "WSBoardVersionOperation.h"


#import "ProtocalPacket.h"

NSString * const WSBLEConnectingNotification = @"BluetoothConnectingNotification";
NSString * const WSBLEFindNewPerpheralNotification = @"BluetoothFindNewPerpheralNotification";
NSString * const WSBLEConnectSuccessNotification = @"BluetoothConnectSuccessNotification";
NSString * const WSBLEConnectFailedNotification = @"BluetoothConnectFailedNotification";
NSString * const WSBLEDisconnectNotification = @"BluetoothDisconnectNotification";
NSString * const WSBLEStateUpdateNotification = @"BluetoothStateUpdateNotification";
NSString * const WSBLEReadyForCommunicateNotification = @"BluetoothReadyForCommunicateNotification";
NSString * const WSBLERecieveResponseNotification = @"BluetoothRecieveResponseNotification";

static const int kBLEMaxDataPacketLength = 20;      //分包字节数
static const float kHeartbeatTimeInterval = 1.0;    //心跳包时间间隔2.0秒

@interface WSRobotManager () <BLEManagerDelegate>

@property(nonatomic, strong) BLEManager *bleManager;

@property(nonatomic, strong, readwrite) NSMutableArray *perpheralList;
@property(nonatomic, strong, readwrite) NSMutableArray *connectedList;

@property(nonatomic, strong) NSMutableData *buffer;

@property(nonatomic, assign, readwrite) BOOL connect;
@property(nonatomic, assign, readwrite) BOOL charging; //是否充电

@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) WSSendDataRequest *sendingRequest;
@property(nonatomic, strong) WSBLEDataPacket *recieveResponse;

@property(nonatomic, strong) NSDate *lastRecvTime;
@property(nonatomic, strong) NSThread *heartbeatThread;   //发送心跳线程
@property(nonatomic, strong) NSTimer *heartbeatTimer;

@property(nonatomic, strong) NSTimer *connectTimer;
@property(nonatomic, strong) WSRobotPeripheral *connectingPer;

@property(nonatomic, strong) NSCondition *responseCondition;

@property(nonatomic, strong) WSBaseOperation *sendingOperation;

@end


@implementation WSRobotManager

#pragma mark - Init Methods

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.responseCondition = [[NSCondition alloc] init];

        _bleManager = [[BLEManager alloc] initWithDelegate:self];
        _perpheralList = [NSMutableArray arrayWithCapacity:1];
        _connectedList = [NSMutableArray arrayWithCapacity:1];
        
        _motorIdentifiers = [[NSMutableArray alloc] initWithCapacity:1];
        _buffer = [[NSMutableData alloc] init];
        
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        
        //开启心跳线程
        _heartbeatThread = [[NSThread alloc] initWithTarget:self selector:@selector(runHeartbeatThread:) object:nil];
        [_heartbeatThread start];
        
        _connect = NO;
    }
    return self;
}

+ (instancetype)sharedManager {
    static WSRobotManager *sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (void)destroyManager {
    
    [self disconnectToAllPeripheral];
    
    [self.bleManager destroy];
    self.bleManager = nil;
    
    [self.perpheralList removeAllObjects];
    [self.connectedList removeAllObjects];
    
    self.buffer = nil;
    [self.motorIdentifiers removeAllObjects];
    self.motorIdentifiers = nil;
    
    [self.queue cancelAllOperations];
    self.queue = nil;
    
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
    [self.heartbeatThread cancel];
    self.heartbeatThread = nil;
    
    self.connect = NO;
}

#pragma mark - Scan
- (WSBluetoothState)bluetoothState {
    
    WSBluetoothState state = WSBluetoothStateUnknown;

    if (@available(iOS 10.0, *)) {
        switch (self.bleManager.manager.state) {
            case CBManagerStateResetting:
                state = WSBluetoothStateResetting;
                break;
            case CBManagerStateUnsupported:
                state = WSBluetoothStateUnsupported;
                break;
            case CBManagerStateUnauthorized:
                state = WSBluetoothStateUnauthorized;
                break;
            case CBManagerStatePoweredOff:
                state = WSBluetoothStatePoweredOff;
                break;
            case CBManagerStatePoweredOn:
                state = WSBluetoothStatePoweredOn;
                break;
            default:
                break;
        }
    } else {
        // Fallback on earlier versions
        switch (self.bleManager.manager.state) {
            case CBCentralManagerStateUnknown:
                state = WSBluetoothStateUnknown;
                break;
            case CBCentralManagerStateResetting:
                state = WSBluetoothStateResetting;
                break;
            case CBCentralManagerStateUnsupported:
                state = WSBluetoothStateUnsupported;
                break;
            case CBCentralManagerStateUnauthorized:
                state = WSBluetoothStateUnauthorized;
                break;
            case CBCentralManagerStatePoweredOff:
                state = WSBluetoothStatePoweredOff;
                break;
            case CBCentralManagerStatePoweredOn:
                state = WSBluetoothStatePoweredOn;
                break;
            default:
                break;
        }
    }
    
    return state;
}

- (void)startScan {
    
    @synchronized (self.perpheralList) {
        [self.perpheralList removeAllObjects];
    }
    
    if (self.bleManager.delegate == nil) {
        self.bleManager.delegate = self;
    }
    
    NSArray<CBUUID *> *servicesUUIDs = @[[CBUUID UUIDWithString:WS_Q_SERVICEUUID],
                                          [CBUUID UUIDWithString:WS_S_SCAN_SERVICE1_UUID],
                                          [CBUUID UUIDWithString:WS_S_SCAN_SERVICE2_UUID],
                                         [CBUUID UUIDWithString:WS_S_READ_SERVICE_UUID],
                                         [CBUUID UUIDWithString:WS_S_WRITE_SERVICE_UUID]];

    [self.bleManager startScanForServices:servicesUUIDs options:nil];
}

- (void)stopScan {
    [self.bleManager stopScan];
}

#pragma mark - Connected/Disconnect to Peripheral

- (void)connectToPeripheral:(WSRobotPeripheral *)peripheral {
    
    peripheral.transparentDataWriteChar = nil;
    peripheral.transparentDataReadChar = nil;

    [self.bleManager connectPeripheral:peripheral.peripheral];
    
    if (self.connectTimer != nil) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
    
    self.connectingPer = peripheral;
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(connectTimeout) userInfo:nil repeats:NO];
}

- (void)connectTimeout
{
    self.connect = NO;
    [self disconnectToPeripheral:self.connectingPer];
}

- (void)disconnectToPeripheral:(WSRobotPeripheral *)peripheral {
    
    //NSLog(@"断开与蓝牙设备的连接 %@", peripheral);
    [self.bleManager disconnectPeripheral:peripheral.peripheral];
}

- (void)disconnectToAllPeripheral {
    
    NSArray *list = [self.connectedList copy];
    
    __weak __typeof(&*self)weakSelf = self;
    [list enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf disconnectToPeripheral:obj];
    }];
}

- (BOOL)isConnect {
    return self.connectedList.count > 0 ? YES : NO;
}

#pragma mark - 发送命令
- (void)cancelAllTask
{
    if (self.queue.operationCount > 0)
    {
        [self.queue cancelAllOperations];
    }
}

- (void)addTask:(WSBaseOperation *)baseOp
{
    //用队列queue处理
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processOperation:) object:baseOp];
    [self.queue addOperation:operation];

    if ([baseOp isKindOfClass:NSClassFromString(@"WSWriteServoOperation")])
    {
        //NSLog(@"写舵机，不等待回复");
    }else
    {
        [self.responseCondition lock];
        [self.responseCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:baseOp.remainSendCount * baseOp.resendTimeInterval / 1000.00]];
        [self.responseCondition unlock];
    }
}

- (void)processOperation:(WSBaseOperation *)operation
{
    if (operation == nil)
    {
        return ;
    }

    @autoreleasepool {
        WSRobotPeripheral *peripheral = [self.connectedList firstObject];   //发第一个机器人
        self.sendingOperation = operation;
        NSData *pData = [operation packageRequestData]; //数据包
        NSDate *lastSendTime = nil;
        
        BOOL stop = NO;
        while (!stop)
        {
            if (self.sendingOperation.receiveAck && self.sendingOperation.completionAck)
            {
                stop = YES;
                continue;
            }
            
            //距离上一次发送命令间隔1000ms没有收到ack，重发条命令
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceDate:lastSendTime];
            
            if (lastSendTime == nil || currentTime * 1000 >= self.sendingOperation.resendTimeInterval)
            {
                if (self.sendingOperation.remainSendCount > 0)
                {
                    //分包
                    NSUInteger totalLen = [pData length];
                    NSUInteger count = totalLen % kBLEMaxDataPacketLength == 0 ? (totalLen / kBLEMaxDataPacketLength) : (totalLen / kBLEMaxDataPacketLength) + 1;
                    NSInteger currentLength = 0;
                    for (int i = 0; i < count; i++)
                    {
                        if (i == count - 1)
                        {
                            currentLength = totalLen - i * kBLEMaxDataPacketLength;
                        }else
                        {
                            currentLength = kBLEMaxDataPacketLength;
                        }
                        
                        NSRange currentRange = NSMakeRange(i * kBLEMaxDataPacketLength, currentLength);
                        NSData *currentData = [pData subdataWithRange:currentRange];
                        [self.bleManager sendData:currentData
                                     toPeripheral:peripheral.peripheral
                                forCharacteristic:peripheral.transparentDataWriteChar
                                             type:CBCharacteristicWriteWithoutResponse];
                        NSLog(@"发送指令第 %d 包: %@", i, currentData);
                    }
                    
                    lastSendTime = [NSDate date];
                    self.sendingOperation.remainSendCount --;
                }else
                {
                    NSLog(@"********************************** 命令 %02X 超时了", [self.sendingOperation.block getCommand]);
                    
                    [self.responseCondition lock];
                    
                    [self.sendingOperation parseResponseData:nil];
                    
                    [self.responseCondition signal];
                    [self.responseCondition unlock];
                    
                    //心跳超时，发送断开连接通知
                    if ([self.sendingOperation.block getCommand] == DV_READBAT)
                    {
                        [self communicateTimeout];
                    }
                    break;
                }
            }else
            {
                //  NSLog(@"时间间隔 %f", currentTime * 1000);
            }
            
            [NSThread sleepForTimeInterval:0.001];
        }
        //NSLog(@"该任务结束，开始发下一条指令～～～～～～");
    }
}

- (void)sendCmd:(Byte)cmd param:(Byte *)param length:(int)length {
    
    NSLog(@"旧协议发送命令 :  %d", cmd);
    
    ProtocalPacket *packet = [[ProtocalPacket alloc] init];
    [packet setCmd:cmd];
    [packet setParam:param lens:length];
    
    int nLens = 0;
    Byte *commandData = [packet packetData:&nLens head:0xCF];
    NSData *pData = [NSData dataWithBytes:commandData length:nLens];
    
    WSSendDataRequest *request = [[WSSendDataRequest alloc] init];
    request.packet = pData;
    request.cmd = cmd;
    
    //    用队列queue处理
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendCmdRequestTask:) object:request];
    [self.queue addOperation:operation];
}

- (void)sendCmd:(uint16_t)cmd deviceId:(Byte)dev_id deviceType:(Byte)dev_type param:(Byte *)param paramLen:(uint16_t)len {
    
    NSLog(@"用新协议发送 %04X 命令 ", cmd);
    
    WSBLEDataPacket *packet = [[WSBLEDataPacket alloc] init];
    [packet setCmd:cmd];
    [packet setDevId:dev_id];
    [packet setDevType:dev_type];
    [packet setParam:param len:len];
    
    Byte *commandData = [packet packetData:'M' devId:dev_id devType:dev_type cmd:cmd param:param paramLen:len];
    
    NSUInteger nLens = commandData[1] + 2;  //总长+校验和0A
    
    NSData *pData = [NSData dataWithBytes:commandData length:nLens];
    
    WSSendDataRequest *request = [[WSSendDataRequest alloc] init];
    request.packet = pData;
    request.cmd = [packet getCmd];
    
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sendCmdRequestTask:) object:request];
    [self.queue addOperation:operation];
    
    free(commandData);
}

- (void)sendCmdRequestTask:(WSSendDataRequest *)request {
    if (request == nil) {
        return ;
    }
    @autoreleasepool {
        WSRobotPeripheral *peripheral = [self.connectedList firstObject];   //发第一个机器人
        self.sendingRequest = request;
        NSData *pData = request.packet; //数据包
        NSDate *lastSendTime = nil;
        
        BOOL stop = NO;
        while (!stop) {
            if (self.sendingRequest.receiveAck && self.sendingRequest.completionAck) {
                stop = YES;
                continue;
            }
            
            //距离上一次发送命令间隔1000ms没有收到ack，重发条命令
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceDate:lastSendTime];
            
            if (lastSendTime == nil || currentTime * 1000 >= request.resendTimeInterval) {
                
                if (request.remainSendCount > 0) {
                    //分包
                    NSUInteger totalLen = [pData length];
                    NSUInteger count = totalLen % kBLEMaxDataPacketLength == 0 ? (totalLen / kBLEMaxDataPacketLength) : (totalLen / kBLEMaxDataPacketLength) + 1;
                    NSInteger currentLength = 0;
                    for (int i = 0; i < count; i++) {
                        if (i == count - 1) {
                            currentLength = totalLen - i * kBLEMaxDataPacketLength;
                        }else {
                            currentLength = kBLEMaxDataPacketLength;
                        }
                        
                        NSRange currentRange = NSMakeRange(i * kBLEMaxDataPacketLength, currentLength);
                        NSData *currentData = [pData subdataWithRange:currentRange];
                        [self.bleManager sendData:currentData
                                     toPeripheral:peripheral.peripheral
                                forCharacteristic:peripheral.transparentDataWriteChar
                                             type:CBCharacteristicWriteWithoutResponse];
                        NSLog(@"发送指令第 %d 包: %@", i, currentData);
                    }
                    
                    lastSendTime = [NSDate date];
                    request.remainSendCount --;
                }else {
                    //NSLog(@"********************************** 命令 %02X 超时了", request.cmd);
                    //心跳超时，发送断开连接通知
                    if (request.cmd == DV_READBAT) {
                        [self communicateTimeout];
                    }
                    break;
                }
            }else {
                //  NSLog(@"时间间隔 %f", currentTime * 1000);
            }
            
            [NSThread sleepForTimeInterval:0.001];
        }
        //NSLog(@"该任务结束，开始发下一条指令～～～～～～");
    }
}

- (void)communicateTimeout
{
    NSLog(@"通讯超时");
    
    [self stopCommunicate];
    
    NSArray *list = [self.perpheralList copy];
    
    __weak __typeof(&*self)weakSelf = self;
    [list enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf disconnectToPeripheral:obj];
        [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEConnectFailedNotification object:obj];
    }];
}

- (void)stopCommunicate
{
    NSLog(@"停止通讯～～～～");
    self.connect = NO;
    if (self.heartbeatTimer)
    {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    
    [self.queue cancelAllOperations];
    [self.motorIdentifiers removeAllObjects];
}

#pragma mark - Heartbeat
- (void)runHeartbeatThread:(NSThread *)thread
{
    @autoreleasepool {
        //让这个线程常驻
        [[NSThread currentThread] setName:@"com.ubtech.stormtrooper.ble.heartbeat"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
        [runLoop run];
    }
}

- (void)beginHeartbeatTimer
{
    if (self.heartbeatTimer)
    {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    
    self.heartbeatTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(sendHeartbeatPacket) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.heartbeatTimer forMode:NSDefaultRunLoopMode];
    [self.heartbeatTimer fire];
}

- (void)sendHeartbeatPacket
{
    if (self.queue.operationCount == 0)
    {
        if ([[NSDate date] timeIntervalSinceDate:self.lastRecvTime] >= kHeartbeatTimeInterval)
        {
            WSBoardVersionOperation *op = [[WSBoardVersionOperation alloc] init];
            [self addTask:op];
//            [self sendCmd:DV_READBAT param:NULL length:0];
        }
    }
}

#pragma mark - BLEManagerDelegate
- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (peripheral != nil && peripheral.name != nil && peripheral.name.length > 0)
    {
        //过滤蓝牙设备
        //         if ([peripheral.name.lowercaseString rangeOfString:@"alpha"].location != NSNotFound)
        //         {
        //
        //         }
        
        @synchronized (self.perpheralList) {
            __block WSRobotPeripheral *target = nil;
            [self.perpheralList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (obj.peripheral == peripheral) {
                    obj.advertisementData = advertisementData;
                    obj.RSSI = RSSI;
                    target = obj;
                    *stop = YES;
                }
            }];
            
            if (target == nil)
            {
                target = [[WSRobotPeripheral alloc] init];
                target.peripheral = peripheral;
                target.advertisementData = advertisementData;
                target.RSSI = RSSI;
                
                [self.perpheralList addObject:target];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEFindNewPerpheralNotification object:nil];
    }
}


- (void)didDiscoverServicesForPeripheral:(CBPeripheral *)peripheral
{
    //查找特征值
    for (CBService *aService in peripheral.services)
    {
        if ([[aService.UUID UUIDString] isEqualToString:WS_Q_SERVICEUUID])
        {
            NSArray *chara = @[[CBUUID UUIDWithString:WS_Q_READ_DATA_CHARACTERISTICUUID],
                               [CBUUID UUIDWithString:WS_Q_WRITE_DATA_CHARACTERISTICUUID]];
            [peripheral discoverCharacteristics:chara forService:aService];
        }else if ([[aService.UUID UUIDString] isEqualToString:WS_S_READ_SERVICE_UUID]) {
            NSArray *chara = @[[CBUUID UUIDWithString:WS_S_READ_DATA_CHARACTERISTIC_UUID]];
            [peripheral discoverCharacteristics:chara forService:aService];
        }else if ([[aService.UUID UUIDString] isEqualToString:WS_S_WRITE_SERVICE_UUID]) {
            NSArray *chara = @[[CBUUID UUIDWithString:WS_S_WRITE_DATA_CHARACTERISTIC_UUID]];
            [peripheral discoverCharacteristics:chara forService:aService];
        }
    }
}

- (void)bluetoothStateDidChanged:(NSInteger)state
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEStateUpdateNotification object:@(state)];
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral
{
    @synchronized (self.perpheralList) {
        __block WSRobotPeripheral *target = nil;
        [self.perpheralList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.peripheral == peripheral)
            {
                target = obj;
                *stop = YES;
            }
        }];
        
        if (target == nil)
        {
            target = [[WSRobotPeripheral alloc] init];
            target.peripheral = peripheral;
            target.isSelected = YES;
            [self.perpheralList addObject:target];
        }
        
        [self.connectedList addObject:target];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEConnectSuccessNotification object:target];
    }
    
    //查找服务
    NSArray *uuids = @[[CBUUID UUIDWithString:WS_Q_SERVICEUUID],
                       [CBUUID UUIDWithString:WS_S_READ_SERVICE_UUID],
                       [CBUUID UUIDWithString:WS_S_WRITE_SERVICE_UUID]];
    [peripheral discoverServices:uuids];
}

- (void)didFailToConnectPeripheral:(CBPeripheral *)peripheral
{
    @synchronized (self.connectedList) {
        __block WSRobotPeripheral *target = nil;
        [self.connectedList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.peripheral == peripheral)
            {
                target = obj;
                *stop = YES;
            }
        }];
        
        if (target != nil)
        {
            [self.connectedList removeObject:target];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEConnectFailedNotification object:target];
    }
}

- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral
{
    @synchronized (self.connectedList) {
        __block WSRobotPeripheral *target = nil;
        [self.connectedList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.peripheral == peripheral)
            {
                target = obj;
                *stop = YES;
            }
        }];
        
        if (target != nil)
        {
            NSLog(@"删除已连接外设");
            [self.connectedList removeObject:target];
        }else
        {
            [self.perpheralList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.peripheral == peripheral) {
                    target = obj;
                    *stop = YES;
                }
            }];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEConnectFailedNotification object:target];
    }
    
    [self stopCommunicate];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
{
    __block WSRobotPeripheral *target = nil;
    [self.connectedList enumerateObjectsUsingBlock:^(WSRobotPeripheral *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.peripheral == peripheral)
        {
            target = obj;
            *stop = YES;
        }
    }];
    
    if (target == nil)
    {
        return ;
    }
    
    CBCharacteristic *aChar = nil;
    if ([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]])
    {
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]])
            {
                NSLog(@"写特征值");
                target.transparentDataWriteChar = aChar;
            }else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]])
            {
                target.transparentDataReadChar = aChar;
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                
                NSLog(@"读特征值");
            } else
            {
                //Other characteristics
            }
        }
    }else if ([service.UUID isEqual:[CBUUID UUIDWithString:BLE_SERVICE_UUID]]) {
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_SERVICE_CHARACTERISTICSS2_UUID]])
            {
                target.transparentDataWriteChar = aChar;
            }else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BLE_SERVICE_CHARACTERISTICSS1_UUID]])
            {
                target.transparentDataReadChar = aChar;
                NSLog(@"开启通知监听。。。。。。");
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
            } else
            {
                //Other characteristics
            }
        }
    }else if ([service.UUID isEqual:[CBUUID UUIDWithString:WS_Q_SERVICEUUID]]) {
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:WS_Q_WRITE_DATA_CHARACTERISTICUUID]])
            {
                target.transparentDataWriteChar = aChar;
            }else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:WS_Q_READ_DATA_CHARACTERISTICUUID]])
            {
                target.transparentDataReadChar = aChar;
                NSLog(@"开启通知监听。。。。。。");
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
            } else
            {
                //Other characteristics
            }
        }
    }else if ([service.UUID isEqual:[CBUUID UUIDWithString:WS_S_READ_SERVICE_UUID]]) {
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:WS_S_READ_DATA_CHARACTERISTIC_UUID]])
            {
                target.transparentDataReadChar = aChar;
                NSLog(@"开启通知监听。。。。。。");
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
            } else
            {
                //Other characteristics
            }
        }
    }else if ([service.UUID isEqual:[CBUUID UUIDWithString:WS_S_WRITE_SERVICE_UUID]]) {
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:WS_S_WRITE_DATA_CHARACTERISTIC_UUID]])
            {
                target.transparentDataWriteChar = aChar;
            } else
            {
                //Other characteristics
            }
        }
    }
    
    if (target.transparentDataWriteChar != nil && target.transparentDataReadChar != nil)
    {
        NSLog(@"读取特征值成功～～～～");
        self.connect = YES;
        
       [[NSNotificationCenter defaultCenter] postNotificationName:WSBLEReadyForCommunicateNotification object:nil];
        //开启心跳计时器
        [self performSelector:@selector(beginHeartbeatTimer) onThread:self.heartbeatThread withObject:nil waitUntilDone:NO];
    }else
    {
        //NSLog(@"读取不到特征值，无法通讯");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReceiveTransparentData:(NSData *)data
{
    NSLog(@"蓝牙下机位回复 %@", data);
    
    if ([data length] <= 0)
    {
        NSLog(@"数据包长小于0，不添加到buffer中！！");
        return ;
    }
    
    if ([self.connectTimer isValid])
    {
        //如果是正在连接，停止连接计时器
        [self.connectTimer invalidate];
        self.connectingPer = nil;
    }
    
    self.lastRecvTime = [NSDate date];  //记录最近一次接收到数据包的时间

    [_buffer appendData:data];   //添加到buffer末尾
    
    //查找完整的数据包
    NSRange range = [self validRangeResponseData:_buffer];
    if (range.location != NSNotFound && range.length > 0)
    {
        self.sendingOperation.receiveAck = YES;
        
        NSData *completePacketData = [[_buffer subdataWithRange:range] copy];
        [self parseResponseData:completePacketData];

        NSUInteger clearLen = range.length;
        if (range.location != 0)
        {
            NSLog(@"buffer不是0x53开头，一起清除掉");
            clearLen += range.location;
        }
        
        [_buffer replaceBytesInRange:NSMakeRange(0, clearLen) withBytes:NULL length:0];
        
        //NSLog(@"清空数据后buffer = %@", _buffer);
    }else
    {
        NSLog(@"没有找到完整的数据包");
    }
    
    /*
    if ([_buffer length] >= 6)
    {
        Byte *dataByte = (Byte *)[_buffer bytes];
        Byte dataLen = [_buffer length];
        
        int startIndex = 0;
        for (int i = 0; i < dataLen; i++)
        {
            if (dataByte[i] == 0x53)
            {
                startIndex = i;
                if (startIndex != 0)
                {
                    NSLog(@"不是53开头，清除掉");
                    [_buffer replaceBytesInRange:NSMakeRange(0, startIndex) withBytes:NULL length:0];
                    dataByte = (Byte *)[_buffer bytes];
                    dataLen = [_buffer length];
                }

                break;
            }
        }
        
        //新协议 // 53080102 2300efff b00a
        Byte *cursor = dataByte;
        
        Byte head = *cursor;
        cursor += 1;
        Byte totalLen = *cursor;
        
        cursor += 4;
        uint16_t cmd = *(uint16_t *)cursor;
        if (cmd == [self.sendingOperation.block getCommand])
        {
            self.sendingOperation.receiveAck = YES;
        }
        
        
        BOOL isValid = [WSBLEDataPacket isDataPacketValid:_buffer];
        if (isValid)
        {
            Byte packetLen = dataByte[1];   //包长
            //解析数据
            NSData *completePacketData = [[_buffer subdataWithRange:NSMakeRange(0, packetLen + 2)] copy];
            [self parseResponseData:completePacketData isOldProtocal:NO];
            
            [_buffer replaceBytesInRange:NSMakeRange(0, packetLen + 2) withBytes:NULL length:0];
            
            //NSLog(@"清空数据后buffer = %@", _buffer);
        }else {
            NSLog(@"数据不完整，等待下一包");
        }
        
      
        }else {
            //跳到下一个字节继续查找帧头
            [_buffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
            //continue;
        }
        
        // [NSThread sleepForTimeInterval:0.1];
    }
     
     */
}


- (NSRange)validRangeResponseData:(NSData *)buffer
{
    Byte *dataByte = (Byte *)[buffer bytes];
    Byte dataLen = [buffer length];
    
    NSInteger startIndex = NSNotFound, length = 0;
    for (int i = 0; i < dataLen; i++)
    {
        //查找可用head
        if (startIndex == NSNotFound && dataByte[i] == 0x53)
        {
            startIndex = i;

            //查找可用的尾部
            length = dataByte[i+1] + 2; //crc + 帧尾
            if (length <= dataLen && dataByte[startIndex + length - 1] == 0x0A)
            {
                break;
            }else
            {
                length = 0;
            }
        }
    }

    return NSMakeRange(startIndex, length);
}

#pragma mark - Parse Response Data
- (void)parseResponseData:(NSData *)data
{
    Byte *dataByte = (Byte *)[data bytes];

    dataByte += 4;  //head(1B) + totalLen(1B) + addr(1B) + type(1B)
    
    uint16_t cmd = *(uint16_t *)dataByte;

    if (cmd == [self.sendingOperation.block getCommand])
    {
        [self.responseCondition lock];
        
        self.sendingOperation.completionAck = YES;
        [self.sendingOperation parseResponseData:data];
        
        [self.responseCondition signal];
        [self.responseCondition unlock];
    }else
    {
       NSLog(@"下机位传回的数据指令 = %04x, 正在发送并等待回复的指令 = %04x",cmd, [self.sendingOperation.block getCommand]);
    }
    
    //本次回复数据接收完成
//    ProtocalPacket *packet = [[ProtocalPacket alloc] init];
//    [packet parseData:data];
//    [[NSNotificationCenter defaultCenter] postNotificationName:WSBLERecieveResponseNotification object:packet];
}

@end

