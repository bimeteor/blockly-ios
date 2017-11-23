//
//  HTSFileArchive.c
//  Alpha1S_NewInteractionDesign
//
//  Created by Glen on 16/5/4.
//  Copyright © 2016年 Ubtechinc. All rights reserved.
//

#include "HTSFileArchive.h"

typedef struct {
    char    logo[3];        //logo
    byte     version;        //版本
    int     nRunTime;       //运行时间
    short   nFrameCount;    //总帧数
    byte     motorCount;     //舵机总数
    char    actType[4];     //动作类型
    char    docType[4];     //文档类型
    byte     descLen;         //动作描述长度
} HTSFILEHEAD_NEWVERSION;


bool CreateFramePkgData(int nMotorListLen, ActionFrameData data, int nFrame, byte** pOutData, int *nOutLen)
{
    bool bRet = false;
   
    //数据包封装
    byte byDataPkgLen = 0;  //包长
    short nPkgOption = 0x0000; //包选项 0000 0000 0000 0011
    short nFrameIndex = nFrame; //帧序号
    short nRunTime = data.runtime; //新版hts运行时间使用旧版hts总时间表示;
    
    byte* pMotorData = NULL;        //舵机数据
    int nMotorDataLen = 0;
    
    byte *pEffBit = NULL; //舵机一二级有效位
    int nEffBitLen = 0;
    if(GetEffectiveBit(data.motorIdentifiers, data.motorCount, &pEffBit, &nEffBitLen))
    {
        byDataPkgLen += nEffBitLen;     //舵机一二级有效位长度
        
        int nMotorCount = data.motorCount;
        nMotorDataLen = nMotorCount * sizeof(byte);
        
        pMotorData = malloc(sizeof(byte) * nMotorDataLen);
        memset(pMotorData, 0, nMotorDataLen);
        
        byDataPkgLen += nMotorDataLen;
        
        int len = ((nMotorCount - 1) / 8 + 1) * 8;
        int nTemp = 0;
        for(int m = 1; m <= len * 8; m++)
        {
            for(int n = (m-1)*8+1; n <= (m-1)*8+8; n++)
            {
                for(int k = 0; k < nMotorCount; k++)
                {
                    if(data.motorIdentifiers[k] == n)
                    {
                        nTemp++;
                        
                        byte pData = data.motorAngles[k];
                        
                        memcpy((byte*)pMotorData + (nTemp - 1) * sizeof(byte), &pData, sizeof(byte));
                    }
                }
            }
        }
        
        bRet = true;
    }else
    {
        bRet = false;
        free(pEffBit);
        return bRet;
    }
    
    byDataPkgLen += (1 + 2 + 2 +2);
    
    *pOutData = malloc(sizeof(byte) * byDataPkgLen);
    memset(*pOutData, 0, byDataPkgLen);
    *nOutLen = byDataPkgLen;
    
    byte *pPkgCursor = *pOutData;
    
    memcpy(pPkgCursor, &byDataPkgLen, 1); //20
    pPkgCursor += 1;
    
    memcpy(pPkgCursor, &nPkgOption, 2); //00 00
    pPkgCursor += 2;
    
    memcpy(pPkgCursor, &nFrameIndex, 2); // 01 00
    pPkgCursor += 2;
    
    memcpy(pPkgCursor, &nRunTime, 2); // 14 00
    pPkgCursor += 2;
    
    memcpy(pPkgCursor, pEffBit, nEffBitLen);  //07
    pPkgCursor += nEffBitLen;
    
    memcpy(pPkgCursor, pMotorData, nMotorDataLen);  //角度
    pPkgCursor += nMotorDataLen;
    
    free(pEffBit);
    free(pMotorData);
    
    return bRet;
}

bool CreateHTSFile(ActionFrameData *fdata,int fdataLen, int actType, int docType, byte **pOutData,int *nOutLen)
{
    bool bRet = false;
    char* pszActDesc = NULL; //动作描述信息
    char* pMotorList = NULL; //舵机列表信息
    int nBufSize = 0; //缓冲区长度
    
    do
    {
        int nFrameCount = fdataLen;  //帧数
        if(nFrameCount > 65535)
        {
            break;
        }
        
        //头部信息
        HTSFILEHEAD_NEWVERSION htsfilehead;
        nBufSize = sizeof(htsfilehead);
        
        *pOutData = (byte *)malloc(nBufSize);
        memset(*pOutData, 0, nBufSize);
        
        byte *pDataCursor = *pOutData;
        
        memcpy(htsfilehead.logo, "HTS", 3);
        htsfilehead.version = 02;
        
        int nAllTime = 0;//总时间
        for(int i = 0; i < fdataLen; i++)
        {
            nAllTime += fdata[i].runtime;
        }
        
        htsfilehead.nRunTime = nAllTime; //运行总时间，单位ms
        htsfilehead.nFrameCount = nFrameCount; //总帧数
        
        //舵机总数
        int nMotorCount = fdata[0].motorCount;
        
        htsfilehead.motorCount = nMotorCount; //舵机数
        memcpy(htsfilehead.actType, &actType, 4);  //动作类型
        memcpy(htsfilehead.docType, &docType, 4);  //文档类型
        
        int nActDesc = 0;
        if(nActDesc <= 0) {
            nActDesc = 3; //最小3字节
        }
        memcpy(&htsfilehead.descLen, &nActDesc, 1); //描述信息长度
        
        //头部信息
        memcpy(pDataCursor, &htsfilehead, sizeof(htsfilehead));
        
        pDataCursor += sizeof(htsfilehead);
        
        //扩容
        int nTempSize = nBufSize;
        nBufSize += nActDesc;
        *pOutData = (byte *)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, nActDesc);
        
        if(nActDesc > 3) {
            memcpy(pDataCursor, pszActDesc, nActDesc); //描述信息
        }
        pDataCursor += nActDesc;
        
        //------舵机信息------------------------------------
        nTempSize = nBufSize;
        nBufSize += 1;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, 1);
        
        int nMotorListLen = (nMotorCount - 1) / 8 + 1;
        memcpy(pDataCursor, &nMotorListLen, 1); //舵机列表有效长度
        pDataCursor += 1;
        
        //扩容
        nTempSize = nBufSize;
        nBufSize += nMotorListLen;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, nMotorListLen);
        
        pMotorList = malloc(sizeof(char) * nMotorListLen);
        memset(pMotorList, 0, nMotorListLen);
        
        for(int i = 0; i < nMotorListLen * 8; i++)
        {
            //int nOffset = (i / 8 + 1) * 8 - (i+1);
            int nOffset = i % 8;
            pMotorList[i/8] |= 1 << nOffset;
        }
        memcpy(pDataCursor, pMotorList, nMotorListLen); //舵机列表信息（二级有效位）
        pDataCursor += nMotorListLen;
        
        //扩容
        nTempSize = nBufSize;
        nBufSize += 8;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, 8);
        
        pDataCursor += 8; //预留8字节跳过
        
        //扩容
        nTempSize = nBufSize;
        nBufSize += 4;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, 4);
        
        int nMotorDataSizeOffset = nTempSize;   //舵机数据长度的偏移位置
        //留到末尾设置
        //int nMotorDataLen = (nMotorCount-1) / 8 + 1;
        //memcpy(pDataCursor, &nMotorDataLen, 4);//数据总长度
        pDataCursor += 4;
        
        //扩容
        nTempSize = nBufSize;
        nBufSize += 4;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, 4);
        
        int nCRCOffset = nTempSize; //CRC数据的偏移位置
        //留到末尾设置
        
        //char* pCRCBuf = pDataCursor;
        //int nCRC = 0;
        //memcpy(&nCRC, pDataCursor, 4);
        pDataCursor += 4;
        memset(pDataCursor, 0, 4);
        
        //-------------------------- 舵机角度开始
        int nFrameIndex = 0;  //帧序号
        int nMotorDataLen = 0;
        for(int i = 0; i < fdataLen; i++)
        {
            nFrameIndex++;
            ActionFrameData frameData = fdata[i];
            
            //数据包封装
            byte *pFrameData = NULL;
            int nFrameLen = 0;
            if(CreateFramePkgData(nMotorListLen, frameData, nFrameIndex, &pFrameData, &nFrameLen))
            {
                //扩容
                nTempSize = nBufSize;
                nBufSize += nFrameLen;
                *pOutData = (byte*)realloc(*pOutData, nBufSize);
                pDataCursor = *pOutData + nTempSize;
                memset(pDataCursor, 0, nFrameLen);
                memcpy(pDataCursor, pFrameData, nFrameLen);
                
                pDataCursor += nFrameLen;
                
                nMotorDataLen += nFrameLen;
            }
            
            free(pFrameData);
        }
        
        //舵机数据4字节对齐
        if(nMotorDataLen % 4 != 0)
        {
            int nAdd = 4 - (nMotorDataLen % 4);
            nMotorDataLen += nAdd;
            
            //扩容
            nTempSize = nBufSize;
            nBufSize += nAdd;
            *pOutData = (byte*)realloc(*pOutData, nBufSize);
            pDataCursor = *pOutData + nTempSize;
            memset(pDataCursor, 0, nAdd);
        }

        //扩容
        nTempSize = nBufSize;
        nBufSize += 32;
        *pOutData = (byte*)realloc(*pOutData, nBufSize);
        pDataCursor = *pOutData + nTempSize;
        memset(pDataCursor, 0, 32);
        
        byte* pMotorDataSizeBuf = *pOutData + nMotorDataSizeOffset;
        memcpy(pMotorDataSizeBuf, &nMotorDataLen, 4);
        
        //计算CRC
        byte* pCRCBuf = *pOutData + nCRCOffset;
        int nCRC = crc32_custom(CRC32_INIT_VALUE, (byte *)pCRCBuf + 4, nMotorDataLen);
        memcpy(pCRCBuf, &nCRC, 4);
        
        bRet = true;
        
    }while(0);
    
    if (!bRet) {
        free(*pOutData);
    }
    
    free(pszActDesc);
    free(pMotorList);
    
    *nOutLen = nBufSize;
    
    return bRet;
}


bool ReadFrameDataFromBuf(byte* hts_buf, unsigned long hts_buf_size, ActionFrameData** rtn, int* rtn_size)
{
    const int size = ((int)hts_buf_size - 66) / 33;
    
    if (size <= 0)
    {
        return false;
    }
    
    *rtn = (ActionFrameData*)malloc(sizeof(ActionFrameData)*size);
    
    int start = 0;
    for (int i = 0; i < size; i++)
    {
        start += 33;
        int r_start = start + 8;
        
        (*rtn)[i].motorAngles = malloc(sizeof(int) * 16);
        (*rtn)[i].motorIdentifiers = malloc(sizeof(int) * 16);
        for (int j = 0; j < 16; j++)
        {
            (*rtn)[i].motorIdentifiers[j] = j + 1;
            (*rtn)[i].motorAngles[j] = ((unsigned char)hts_buf[r_start + j]);
        }
        (*rtn)[i].runtime = hts_buf[start + 28] * 20;
        (*rtn)[i].totaltime = ((hts_buf[start + 29] << 8) | hts_buf[start + 30]) * 20;
        (*rtn)[i].motorCount = 16;
    }
    
    *rtn_size = size;
    return true;
}


bool GetEffectiveBit(int *motorList, int motorListLen, byte** pOutData, int *nOutLen)
{
    bool bRet = true;
    
    byte *pEffBit1 = NULL; //舵机一级有效位
    byte *pEffBit2 = NULL; //舵机二级有效位
    
    int nMotorListLen = (motorListLen - 1) / 8 + 1;
    int nEffBit1Len = (nMotorListLen - 1) / 8 + 1;  //一级有效位长度
    
    pEffBit1 =  malloc(sizeof(byte) * nEffBit1Len); //舵机一级有效位
    memset(pEffBit1, 0, nEffBit1Len);
    
    int nEffBit2Len = 0; //二级有效位(位1的个数)
    for(int m = 1; m <= nEffBit1Len * 8; m++)
    {
        bool bExist = false;
        for(int n = (m-1)*8+1; n <= (m-1)*8+8; n++)
        {
            for(int k = 0; k < motorListLen; k++)
            {
                if(motorList[k] == n)
                {
                    int nOffset = (motorList[k]-1) / 8;
                    pEffBit1[(m-1)/8] |= 1 << nOffset;
                    
                    nEffBit2Len++;
                    bExist = true;
                    break;
                }
            }
            if(bExist) {
                break;
            }
        }
    }
    
     //ERROR
    if(nEffBit2Len <= 0) {
        free(pEffBit1);
        return false;
    }

    pEffBit2 = malloc(sizeof(byte) * nEffBit2Len);; //舵机二级有效位
    memset(pEffBit2, 0, nEffBit2Len);
    
    int nTemp = 0;
    for(int m = 1; m <= nEffBit1Len * 8; m++)
    {
        if(pEffBit1[(m-1)/8] & (1 << (m - 1)))
        {
            nTemp++;
            for(int n = (m-1)*8+1; n <= (m-1)*8+8; n++)
            {
                for(int k = 0; k < motorListLen; k++)
                {
                    if(motorList[k] == n)
                    {
                        pEffBit2[nTemp-1] |= 1 << (n-1) % 8;
                    }
                }
            }
        }
    }
    
    int effectiveBitTotalLen = (nEffBit1Len + nEffBit2Len);
    *pOutData = malloc(sizeof(byte) * effectiveBitTotalLen);
    memset(*pOutData, 0, effectiveBitTotalLen);
    
    byte *pPkgCursor = *pOutData;
    
    memcpy(pPkgCursor, pEffBit1, nEffBit1Len);
    pPkgCursor += nEffBit1Len;
    
    memcpy(pPkgCursor, pEffBit2, nEffBit2Len);
    pPkgCursor += nEffBit2Len;
    
    *nOutLen = effectiveBitTotalLen;
    
    return bRet;
}


bool GetCmdParamByMotorList(int *motorList, int motorCount, bool isSingleBit, byte **pOutData, int *nOutLen)
{
    bool bRet = true;

    int nDataTotalLen = 0;

    byte *pMotorData = NULL;
    
    byte *pEffBit = NULL; //舵机一二级有效位
    int nEffBitLen = 0;
    if(GetEffectiveBit(motorList, motorCount, &pEffBit, &nEffBitLen))
    {
        nDataTotalLen += nEffBitLen;     //舵机一二级有效位长度

        pMotorData = malloc(sizeof(byte) * motorCount);
        memset(pMotorData, 0, motorCount);

        nDataTotalLen += motorCount;    //舵机长度
        
        int len = ((motorCount - 1) / 8 + 1) * 8;
        int nTemp = 0;
        for(int m = 1; m <= len; m++)
        {
            for(int n = (m-1)*8+1; n <= (m-1)*8+8; n++)
            {
                for(int k = 0; k < motorCount; k++)
                {
                    if(motorList[k] == n)
                    {
                        nTemp++;
                        byte tempdata = motorList[k];
                        memcpy((byte*)pMotorData + (nTemp - 1) * sizeof(byte), &tempdata, sizeof(byte));
                    }
                }
            }
        }
        
        nDataTotalLen += (2 + 4);
        
        *pOutData = malloc(sizeof(byte) * nDataTotalLen);
        memset(*pOutData, 0, nDataTotalLen);
        
        byte *pPkgCursor = *pOutData;
        
        byte opt = 0x01;
        memcpy(pPkgCursor, &opt, 1);
        pPkgCursor += 1;

        byte deviceType = 0x04;
        memcpy(pPkgCursor, &deviceType, 1);
        pPkgCursor += 1;
        
        long temp = 0xFFFFFFFF;
        memcpy(pPkgCursor, &temp, 4);
        pPkgCursor += 4;    //预留
        
        memcpy(pPkgCursor, pEffBit, nEffBitLen);
        pPkgCursor += nEffBitLen;
        
        memcpy(pPkgCursor, pMotorData, motorCount); //舵机编号
        
        *nOutLen = nDataTotalLen;
        
        free(pEffBit);
        free(pMotorData);

        bRet = true;
    }else
    {
        bRet = false;
    }
    
    return bRet;
}



bool GetCmdParamByFrameData(int frameIndex, ActionFrameData fdata, bool isSingleBit, byte **pOutData, int *nOutLen)
{
    bool bRet = true;
    
    int nDataTotalLen = 0;
    
    byte *pMotorData = NULL;   //舵机数据
    
    byte *pEffBit = NULL; //舵机一二级有效位
    int nEffBitLen = 0;
    if(GetEffectiveBit(fdata.motorIdentifiers, fdata.motorCount, &pEffBit, &nEffBitLen))
    {
        nDataTotalLen += nEffBitLen;     //舵机一二级有效位长度
        
        pMotorData = malloc(sizeof(byte) * fdata.motorCount);
        memset(pMotorData, 0, fdata.motorCount);
        
        nDataTotalLen += fdata.motorCount;    //舵机长度
        
        int nTemp = 0;
        int len = ((fdata.motorCount - 1) / 8 + 1) * 8;
        for(int m = 1; m <= len; m++)
        {
            for(int n = (m-1)*8+1; n <= (m-1)*8+8; n++)
            {
                for(int k = 0; k < fdata.motorCount; k++)
                {
                    if(fdata.motorIdentifiers[k] == n)
                    {
                        nTemp++;
                        byte tempdata = fdata.motorAngles[k];
                        memcpy((byte*)pMotorData + (nTemp - 1) * sizeof(byte), &tempdata, sizeof(byte));
                    }
                }
            }
        }
        
        nDataTotalLen += (2 + 2 + 2);
        
        *pOutData = malloc(sizeof(byte) * nDataTotalLen);
        memset(*pOutData, 0, nDataTotalLen);
        
        byte *pPkgCursor = *pOutData;
        
        byte opt = 0x00;
        memcpy(pPkgCursor, &opt, 1);
        pPkgCursor += 1;
        
        byte deviceType = 0x04;
        memcpy(pPkgCursor, &deviceType, 1);
        pPkgCursor += 1;
        
        
        long temp = 0xFFFF;
        memcpy(pPkgCursor, &temp, 2); //默认小端在前，不需要再转换
        pPkgCursor += 2;
        
        memcpy(pPkgCursor, &fdata.runtime, 2);  //默认小端在前，不需要再转换
        pPkgCursor += 2;
        
        memcpy(pPkgCursor, pEffBit, nEffBitLen);
        pPkgCursor += nEffBitLen;
        
        memcpy(pPkgCursor, pMotorData, fdata.motorCount); //舵机角度列表
        
        *nOutLen = nDataTotalLen;
        
        free(pEffBit);
        free(pMotorData);
        
        bRet = true;
    }else
    {
        bRet = false;
    }
 
    return bRet;
}


