//
//  HTSFileArchive.h
//  Alpha1S_NewInteractionDesign
//
//  Created by Glen on 16/5/4.
//  Copyright © 2016年 Ubtechinc. All rights reserved.
//

#ifndef HTSFileArchive_h
#define HTSFileArchive_h

#include <stdio.h>
#include <stdbool.h>
#include "string.h"
#include <stdlib.h>

#include "CRC32.h"


typedef unsigned char byte;

//动作帧数据
typedef struct {
    int *motorAngles;        //舵机角度
    int *motorIdentifiers;   //舵机id列表
    int motorCount;          //舵机个数
    int runtime;              //运行时长
    int totaltime;            //总时长
}ActionFrameData;


/**
 *  创建HTS文件，输出文件16进制编码内容
 *
 *  @param fdata    动作帧数据
 *  @param fdataLen 帧数据长度
 *  @param actType  动作类型
 *  @param docType  文档类型
 *  @param pOutData 输出（在外部释放）
 *  @param nOutLen  输出数据长度
 *
 *  @return 是否创建成功
 */
bool CreateHTSFile(ActionFrameData *fdata,int fdataLen, int actType, int docType, byte **pOutData,int *nOutLen);


/**
 *
 *  HTS文件解析
 *
 */
bool ReadFrameDataFromBuf(byte* hts_buf, unsigned long hts_buf_size, ActionFrameData** rtn, int* rtn_size);


/**
 *  返回一级、二级有效位
 *
 *  @param motorList    舵机编号列表
 *  @param motorListLen 舵机列表长度
 *  @param pOutData     输出（在外部释放内存）
 *  @param nOutLen      输出长度
 *
 *  @return 是否成功
 */
bool GetEffectiveBit(int *motorList, int motorListLen, byte** pOutData, int *nOutLen);


/**
 *  获取回读舵机角度指令(0x25)的参数（新版协议中使用B7的话需要回读指定舵机的角度）
 *
 *  @param motorList    舵机编号列表
 *  @param motorListLen 舵机数量
 *  @param isSingleBit  是否单子节
 *  @param pOutData     输出 （在外部释放内存）
 *  @param nOutLen      输出长度
 *
 *  @return 是否创建成功
 */
bool GetCmdParamByMotorList(int *motorList, int motorListLen, bool isSingleBit, byte **pOutData, int *nOutLen);

/**
 *  拼装动作帧数据(0x23)的参数（预览动作帧数据下发参数）
 *
 *  @param frameIndex  帧数据下标
 *  @param fdata    帧数据列表
 *  @param isSingleBit 是否单子节
 *  @param pOutData    输出（在外部释放内存）
 *  @param nOutLen     输出长度
 *
 *  @return 是否创建成功
 */
bool GetCmdParamByFrameData(int frameIndex, ActionFrameData fdata, bool isSingleBit, byte **pOutData, int *nOutLen);



#endif /* HTSFileArchive_h */
