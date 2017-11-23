//
//  GlobalBLEProtocal.h
//  alpha1s
//
//  Created by juntian on 15/2/2.
//  Copyright (c) 2015年 ubtechinc. All rights reserved.
//
//  蓝牙协议的头文件，统一定义在此
//

#ifndef alpha1s_Globle_h
#define alpha1s_Globle_h

/**
 * 握手
 */
#define DV_HANDSHAKE  0x01
/**
 * 获取动作表名
 */
#define  DV_GETACTIONFILE  0x02
/**
 * 执行动作表
 */
#define  DV_PLAYACTION  0x03
/**
 * 停止播放
 */
#define  DV_STOPPLAY  0x05
/**
 * 声音控制：0x06
	参数：	00 － 静音
 01 - 打开声音
 */
#define  DV_VOICE  0x06
/**
 * 播放控制：0x07
	参数：00 － 暂停
 01 － 继续
 */
#define  DV_PAUSE  0x07

/**
 * 心跳
 */
#define  DV_XT 0x08

/**
 * 修改设备名
 * 参数：新的设备名
 */
#define  DV_MODIFYNAME  0x09
/**
 * 读取状态：0x0a
 下位机返回：声音状态(00+声音状态(01 静音 00有声音))
 播放状态(01+(播放状态00 暂停 01非暂停))
 音量（02+音量大小(1B)）
 舵机灯状态（03 +状态 01 亮 00 灭）
 TF卡插入（04  +状态  01 插入  00 拔出）
 */
#define  DV_READSTATUS  0x0a

/**
 * 调整音量
 * 参数：(0~255)
 */
#define  DV_VOLUME  0x0b

/**
 * 所有舵机掉电
 */
#define  DV_DIAODIAN  0x0c

/**
 * 灯控制
 * 参数：0-关
 * 		1 开
 */
#define  DV_LIGHT  0x0d

/** 时间校准 **/
#define DV_ADJUST_TIME 0x0e

/** 读取闹铃时间 **/
#define DV_READ_ALARM 0x0f
/** 设置闹铃时间 **/
#define DV_WRITE_ALARM 0x10
/** 读版本号：0x11 */
#define DV_READVERSION 0x91
/** 删除文件:0x12 */
#define DV_DELETE_ACTION    0x12
/** 修改文件0x13*/
#define DV_MODIFY_ACTION_NAME 0x13

/** 传输文件开始：0x14
 参数1：1B          文件名长度
 参数2：nB          文件名
 参数3：2B          文件总帧数
 **/
#define DV_TRANSFER_FILE_START  0x14


/**
 传输文件中：0x15
 参数1：2B    当前帧数
 参数2：245B   文件数据
 **/
#define DV_TRANSFER_FILE_PROGRESS  0x15

/**
 传输文件结束：0x16
 参数1：2B            当前帧数
 参数2：nB <=245B  文件数据
 **/
#define DV_TRANSFER_FILE_FINISH  0x16

/**
 取消传输文件
 **/
#define DV_TRANSFER_FILE_CANCEL  0x17

/** 电量 */
#define DV_READBAT      0x18

/** 读取硬件版本号 */
#define DV_READ_HARDWARE_VERSION 0x20

/** 执行动作列表需要插入复位动作:0x21
 参数1：1B   0-需要   1-不需要
 **/
#define DV_NEED_DEFAULT_ACTION 0x21

#pragma mark - 控制舵机
/** 控制单一舵机：0x22
 参数1 1B：舵机ID
 参数2 1B：舵机角度
 参数3 1B：舵机运行时间
 参数4 2B：舵机运行总时间
 
 应答：
 参数1：舵机ID
 参数2:0，OK，1，舵机ID不对，2舵机角度超出允许，3，舵机没应答
 **/
#define DV_CONTROL_SINGLE_STEERING 0x22

/** 控制16个舵机：0x23
 参数1 16B：1-16号舵机的角度
 参数2 1B： 舵机运行时间
 参数3 2B： 舵机运行总时间
 
 应答：参数16B（分别对应各舵机）:0，OK，1，舵机ID不对，2舵机角度超出允许，3，舵机没应答
 **/
#define DV_CONTROL_TOTOAL_STEERINGS 0x23

/** 回读单个舵机角度（并掉电）：0x24
 参数1 1B：舵机ID
 
 应答：
 参数1：舵机ID
 参数2：FF，舵机没应答，FE，舵机ID不对，2，舵机角度
 **/
#define DV_READ_SINGLE_STEERING_ANGLE 0x24

/** 回读16个舵机角度（并掉电）：0x25
 应答：
 参数1 16B（对应1-16号舵机的角度）：FF，舵机没应答，FE，舵机ID不对，2，舵机角度
 **/
#define DV_READ_TOTAL_STEERINGS_ANGLE 0x25

/** 设置单个舵机偏移值：0x26
 参数1 1B:舵机ID
 参数2 2B：偏移值
 
 应答：
 参数1 1B:舵机ID
 参数2 1B：0，设置成功，1，设置失败，2，舵机没应答。
 **/
#define DV_SET_SINGLE_STEERING_OFFSET 0x26

/** 设置16个舵机偏移值：0x27
 参数1 32B，2B为一个偏移值分别对应1-16号舵机
 
 应答：
 参数1 16B（分别对应1-16号舵机）：0，设置成功，1，设置失败，2，舵机没应答。
 **/
#define DV_SET_TOTAL_STEERINGS_OFFSET 0x27

/** 读取单个舵机偏移值：0x28
 参数1 1B：舵机ID
 
 应答：
 参数1 1B：舵机ID
 参数2 2B：0X8888舵机没应答，其他为偏移值
 **/
#define DV_READ_SINGLE_STEERING_OFFSET 0x28

/** 读取16个舵机偏移值：0x29
 应答：
 参数1 32B，2B为一个偏移值分别对应1-16号舵机：0X8888舵机没应答，其他为偏移值
 **/
#define DV_READ_TOTAL_STEERINGS_OFFSET 0x29

/** 动作完成命令:0x31
 下位机主动发送参数1：完成动作文件名
 **/
#define DV_FINISH_PLAY_ACTION 0x31

/** 是否允许边充边玩 0x32
 参数1 1 允许 0 禁止
 
 允许、禁止充电动作命令： 0x32
 PC主动发送
 参数1：  ==  1允许充电动作命令
 == 0禁止充电动作命令
 
 设备应答32：
 参数1和主机发送相同,回复的是当前的状态
 当主机发送动作执行时,如果在锁定状态时:回复0
 没有锁定回复1.
 **/
#define DV_PLAY_DURING_CHARGING 0x32

/** 读写SN命令： 0x33
 参数（可选）
 P1 == 0,表示读SN,无P2参数
 P1 == 1,表示写SN,P2为写入的设备SN, 不定长度,最大16字节字符串
 设备应答：
 P1 == 0,表示读SN,P2为读取的设备SN, 不定长度,最大16字节字符串
 P1 == 1,表示写SN. P2为写入状态,P2==0成功,P2==1失败. 如果下发的SN和设备端一样,设备端不会进行写操作,但会反回成功标志.
 **/
#define DV_SN_READWRITE 0x33

/** 读UDID(Unique device ID register)命令： 0x34
 参数：
 ==  空,表示读UDID,不提供写操作
 设备应答：
 参数
 ==设备MCU UDID, 不定长度,最大16字节.
 **/
#define DV_READ_MCU_UDID 0x34



/** 音源写/读命令: 0x35
 参数1（1B）：音源状态选择(0音源为TF卡内mp3文件, 1音源为手机APP蓝牙音频)
 设备应答：
 参数1(1B) ： 设置后的音源状态
 
 例：
    发送：FB CF 06 35 01 3C ED    //切换音源为手机APP蓝牙音频
    应答：FB BF 06 35 01 3C ED    //与发送相同
 
 音源读命令0xB5=0x35+0x80：
 无参数
 应答：
 参数1(1B)：机器人当前的音源状态
 例：
 发送：FB CF 05 B5 BA ED    //读取音源状态
 应答：FB BF 06 B5 01 BC ED //返回音源状态为手机APP蓝牙音频
 **/
#define DV_AUDIO_SOURCE 0x35


/**
 * 读动作表回复命令[正在回复动作以及回复完成]
 */
#define  UV_GETACTIONFILE  0x80
#define  UV_STOPACTIONFILE 0x81


/**
 *  读取舵机个数以及UTF-8状态
 *
 *  @return <#return value description#>
 */
#define  UV_STEERING_NUMBER 0xB7

/**
 *  设置闹钟参数
 */
#define UV_WRITE_ALARM 0x10

/**
 *  读取闹钟参数
 */
#define UV_READ_ALARM 0x90

/**
 *  设置男女音色
 */
#define UV_WRITE_PEOPLE_TONE 0x1b

/**
 *  读取男女音色
 */
#define UV_READ_PEOPLE_TONE 0x9b


/**
 *  读取／重置最大包长
 *  参数1（2B）: 数据包长度，小端
 */
#define DV_READ_PACKET_LENGTH 0x9E
#define DV_RESET_PACKET_LENGTH 0x1E


#endif




