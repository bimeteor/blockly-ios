//
//  WSBLEProtocalHeader.h
//  WhiteSoldier
//
//  Created by Glen on 2017/6/13.
//  Copyright © 2017年 ubtech. All rights reserved.
//
//  新版本蓝牙协议V1.01

#ifndef WSBLEProtocalHeader_h
#define WSBLEProtocalHeader_h

#pragma pack(push,1)

//设备类型
typedef enum {
    //0 保留
    DEVICE_HOST = 0x01,	//主机,PC,iphone,android
    DEVICE_MAIN,		//主板,整机,看具体使用情况,主板可以占用多个ID
    DEVICE_HUB,         //集线器
    DEVICE_SERVO,		//舵机
    DEVICE_Infrared,	//红外 IR
    DEVICE_Temperature,	//温度
    DEVICE_Humidity,	//湿度
    DEVICE_LED,         //灯光
    DEVICE_Ultrasound,	//超声
    DEVICE_Gyro,		//陀螺仪  单个
    DEVICE_SW_PUSH_BOTTON,	//按键开关
    DEVICE_OUTPUT,		//输出设备
    DEVICE_DISPLAY,		//显示设备
    //...
    DEVICE_OTHER = 0xFB,	//其它类型
    DEVICE_TYPE_REQ = 0xFC,	//请求分配设备类型
    DEVICE_Broadcast = 0xFD,//广播消息	//无需应答
    DEVICE_Extended = 0xFE,	//扩展设备
    DEVICE_TYPE_MAX_ERR = 0xFF,	//错误设备 最大设备类型
}DEVICE_TYPE;

//设备地址（ID）
typedef enum {
    //0保留
    DEVICE_ADDRESS_HOST = 0X01,	//HOST
    //...
    DEVICE_ADDRESS_MAX = 0XF0,	//最大值
    //... 0XF0~0XFA 保留
    DEVICE_ADDRESS_MULTICAST = 0XFB,//多播消息	//根据内部SUB OPT实现是否要应答
    DEVICE_ADDRESS_REQ = 0XFC,	//ID请求分配设备号
    DEVICE_ADDRESS_BROADCAST = 0XFD,//广播消息	//无需应答
    DEVICE_ADDRESS_EXRENDED = 0XFE,//ID扩展
    DEVICE_ADDRESS_ERR = 0XFF,	//错误 ID 最大设备号
}DEVICE_ADDRESS;



//数据包结构(帧内容结构)
typedef	struct PACKET_STRUCTURE {
    //    unsigned  char HEAD;        //包头 'M' ==Mastr, 'S' == Slave
    //    unsigned  short TOTAL_LEN;	//总包长 3~255 , 除了结束符和校验位的总长度
    unsigned  char DEV_ID;     //设备地址
    unsigned  char DEV_TYPE;    //设备类型
    unsigned  short CMD;        //命令号
    unsigned  short PARAM_LEN;  //命令长度, 4 == byte , 5 == word , 7 == dwors, other == 0
}sPacket;


//opt 和sub opt 暂时统一标记描述
typedef	struct _OPT_Struct_
{
    unsigned  char nW_R		: 1;	//读标记
    unsigned  char not_ComPara	: 1;	//没有公共参数
    unsigned  char ack		: 1;	//应答标记,发送方发送此位表示不要求接收方应答,或者表示自己应答对方;
    unsigned  char res2		: 2;
    unsigned  char res3		: 3;
}sOPT;

typedef	struct _Multicast_Compression_Pack_V002_Struct_	//多播压缩包 V0.02
{
    //unsigned  char LEN;		//总长,包含自身,不使用
    union{
        sOPT BIT;
        unsigned  char Data;	//sub opt
    }SUB_OPT;
    unsigned  char PARA_TYPE;	//参数类型
    union{
        unsigned  long Data32;	//32位公共数据
        struct _SERVO_t_
        {
            unsigned  short FRAME_NO;	//帧号
            unsigned  short RUN_TIME16;	//运行时间
        }SERVO;	//舵机数据
    }COM_DATA;
    unsigned  char Para;		//数据定位位置
}sMulticast_Compression_Pack_V002;


typedef enum {
    BASE_CMD_VERSION = 0x0001,          //读版本号
    BASE_CMD_OPEN_FILE = 0x1100,        //打开文件
    BASE_CMD_CLOSE_FILE = 0x1101,       //关闭文件
    BASE_CMD_READ_FILE = 0x1102,        //读文件
    BASE_CMD_WRITE_FILE = 0x1103,       //写文件
    BASE_CMD_SEEK_FILE = 0x1104,        //文件指针
    BASE_CMD_OPEN_DIR = 0x1105,         //打开文件夹
    BASE_CMD_CLOSE_DIR = 0x1106,        //关闭文件夹
    BASE_CMD_READ_DIR = 0x1107,         //读文件中的项目
    BASE_CMD_FIND_FIRST = 0x1108,       //查找第一项
    BASE_CMD_FIND_NEXT = 0x1109,        //查找下一项
    BASE_CMD_STAT = 0x1110,             //检查文件或文件夹属性
    BASE_CMD_DELETE = 0x1111,           //删除文件／文件夹
    BASE_CMD_RENAME = 0x1112,           //重命名
    BASE_CMD_MKDIR = 0x1113,            //新建文件夹
    BASE_CMD_ONLINE_SERVO = 0x00B7,     //读取在线舵机编号
    BASE_CMD_BROADCAST = 0x0023,        //多播操作(回读舵机数据／下发舵机角度)
    BASE_CMD_FORWARD = 0x02C,           //串口转发
    
    //主板命令号
    MAINBOARD_CMD_RECOVER = 0x6000,            //恢复出厂设置
    MAINBOARD_CMD_TRAIN_START = 0x6100,        //提取特征
    MAINBOARD_CMD_TRAIN_CANCEL = 0x6101,       //取消提取操作
    MAINBOARD_CMD_TRAIN_SAVE = 0x6102,         //保存特征
    MAINBOARD_CMD_TRAIN_DELETE = 0x6103,       //删除特征
    MAINBOARD_CMD_TRAIN_STATE = 0x6104,        //获取当前提取状态
    MAINBOARD_CMD_RECOGNIZE_START = 0x6110,    //认别指定人脸
    MAINBOARD_CMD_RECOGNIZE_CANCEL = 0x6111,   //取消识别操作
    MAINBOARD_CMD_RECOGNIZE_STATE = 0x6112,    //获取当前识别状态
    MAINBOARD_CMD_JSON_FILE_READ = 0x6200,     //获取指定文件下对应字段的值
    MAINBOARD_CMD_JSON_FILE_WRITE = 0x6201,    //设置指定文件下对应字段的值
    
    MAINBOARD_CMD_TASK_RUN = 0x6300,            //运行指定任务
    MAINBOARD_CMD_TASK_CANCEL = 0x6301,         //取消当前任务
    MAINBOARD_CMD_TASK_STATE = 0x6302,          //当前任务状态
    
}COMMAND;


typedef enum {
    FILEMODE_RDONLY = 0X0000,           //只读
    FILEMODE_WRONLY = 0X0001,           //只写
    FILEMODE_RDWR = 0X0002,             //读写
    FILEMODE_ACCMODE = 0X0003,          //读写文件，从文件尾部开始移动，所写入的数据追加到文件尾
    FILEMODE_TRUNC = 0X0200,            //若文件存在并且以可写方式打开，此标志会将文件长度清0，数据被清空
    FILEMODE_CREATE = 0X0400,           //若路径中的文件不存在，自动创建该文件
    FILEMODE_EXCL = 0X4000,             //
    
}FILEMODE;

//
//typedef struct _Multicast_Compression_Pack_V002_Struct_ //多播压缩包 V0.02
//{
//    union{
//        struct _OPT_Struct_
//        {
//            unsigned  char nW_R  : 1; //读标记 ,
//            unsigned  char not_ComPara : 1; //没有公共参数
//            unsigned  char ack  : 1; //应答标记,发送方发送此位表示不要求接收方应答,或者表示自己应答对方;
//            unsigned  char res2  : 2;
//            unsigned  char res3  : 3;
//        }BIT;
//        unsigned  char Data; //sub opt
//    }SUB_OPT;
//    unsigned  char PARA_TYPE; //参数类型
//    union{
//        unsigned  long Data32; //32位公共数据
//        struct _SERVO_t_
//        {
//            unsigned  short FRAME_NO; //帧号
//            unsigned  short RUN_TIME16; //运行时间
//        }SERVO; //舵机数据 
//    }COM_DATA;
//    unsigned  char Para[];  //数据 
//}sMulticast_Compression_Pack_V002;



#pragma pack(pop)


/**
 CRC8校验

 @param buf 数据buffer
 @param len buffer长度
 @param poly CRC多项式
 @param init CRC初始值
 @return CRC8校验值
 */
unsigned char CRC8_MAXIM(unsigned char *buf, unsigned char len,unsigned char poly,unsigned char init);

/**
 CRC16校验
 
 @param src 数据buffer
 @param len buffer长度
 @param poly CRC多项式
 @param init CRC初始值
 @return CRC16校验值
 */
unsigned short  CRC16_CCITT(unsigned char * src, unsigned short len,unsigned short poly,unsigned short init);


#endif /* WSBLEProtocalHeader_h */






