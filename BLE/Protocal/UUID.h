//
//  UUID.h
//  BLEDKSDK
//
//  Created by D500 user on 13/2/19.
//  Copyright (c) 2013年 D500 user. All rights reserved.
//

#ifndef BLEDKSDK_UUID_h
#define BLEDKSDK_UUID_h

//GAP
#define UUIDSTR_GAP_SERVICE @"1800"

//CBCentralManagerOptionRestoreIdentifierKey
#define ISSC_RestoreIdentifierKey               @"ISSC_RestoreIdentifierKey"


//Device Info service
#define UUIDSTR_DEVICE_INFO_SERVICE             @"180A"
#define UUIDSTR_MANUFACTURE_NAME_CHAR           @"2A29"
#define UUIDSTR_MODEL_NUMBER_CHAR               @"2A24"
#define UUIDSTR_SERIAL_NUMBER_CHAR              @"2A25"
#define UUIDSTR_HARDWARE_REVISION_CHAR          @"2A27"
#define UUIDSTR_FIRMWARE_REVISION_CHAR          @"2A26"
#define UUIDSTR_SOFTWARE_REVISION_CHAR          @"2A28"
#define UUIDSTR_SYSTEM_ID_CHAR                  @"2A23"
#define UUIDSTR_IEEE_11073_20601_CHAR           @"2A2A"

#define UUIDSTR_ISSC_PROPRIETARY_SERVICE        @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define UUIDSTR_CONNECTION_PARAMETER_CHAR       @"49535343-6DAA-4D02-ABF6-19569ACA69FE"
#define UUIDSTR_AIR_PATCH_CHAR                  @"49535343-ACA3-481C-91EC-D85E28A60318"
#define UUIDSTR_ISSC_TRANS_TX                   @"49535343-1E4D-4BD9-BA61-23C647249616"
#define UUIDSTR_ISSC_TRANS_RX                   @"49535343-8841-43F4-A8D4-ECBE34729BB3"
#define UUIDSTR_ISSC_MP                         @"49535343-ACA3-481C-91EC-D85E28A60318"

//大白兵
#define BLE_SERVICE_UUID                        @"FFF0"
#define BLE_SERVICE_CHARACTERISTICSS1_UUID      @"FFF1"
#define BLE_SERVICE_CHARACTERISTICSS2_UUID      @"FFF2"

//小白兵／中白兵
#define WS_Q_SERVICEUUID                        @"FF12"     //LSD BLE 串口数传服务 Serial Data Service
#define WS_Q_WRITE_DATA_CHARACTERISTICUUID      @"FF01"     //写
#define WS_Q_READ_DATA_CHARACTERISTICUUID       @"FF02"     // ￼BLE 数传模块给主机端发送的数据,以 Notification 方式实现,最大 20 字节 Serial Data Out



#define WS_S_SCAN_SERVICE1_UUID                  @"FFF0"     //扫描服务
#define WS_S_SCAN_SERVICE2_UUID                  @"FFB0"     //扫描服务
#define WS_S_READ_SERVICE_UUID                   @"FFE0"     //读服务
#define WS_S_WRITE_SERVICE_UUID                  @"FFE5"     //写服务
#define WS_S_READ_DATA_CHARACTERISTIC_UUID       @"FFE4"     //读服务下的读特征值
#define WS_S_WRITE_DATA_CHARACTERISTIC_UUID      @"FFE9"     //写服务下的写特征值



#endif
