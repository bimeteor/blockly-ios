//
//  WSBLEProtocalHeader.c
//  WhiteSoldier
//
//  Created by Glen on 2017/6/16.
//  Copyright © 2017年 ubtech. All rights reserved.
//

#include "WSBLEProtocalHeader.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


unsigned char CRC8_MAXIM(unsigned char *buf, unsigned char len,unsigned char poly,unsigned char init)
{
    //MAXIM CRC8
    unsigned char reg_crc = init;//0x00;//0xFF;	//CRC预设,初值
    unsigned char i,j;
    
    for(j = 0; j < len; j++)
    {
        reg_crc  ^=  buf[j];    //处理一个字节（异或
        for(i = 0; i < 8; i++)	//循环处理字节中的每一位
        {
            if(reg_crc & 0x80)	//低位在前，高位在后（低位----高位
            {
                reg_crc = (reg_crc << 1) ^ poly;
            }
            else
            {
                reg_crc = (reg_crc << 1);
            }
        }
    }
    return  reg_crc;
}

unsigned short  CRC16_CCITT(unsigned char * src, unsigned short len,unsigned short poly,unsigned short init)
{
    unsigned short crc = init;
    unsigned char i;
    
    while(len--)
    {
        crc ^= *src++ << 8;
        for(i = 0; i< 8; ++i)
        {
            if(crc & 0x8000)
            {
                crc = (crc << 1) ^ poly;
            } else
            {
                crc <<= 1;
            }
        }
    }
    return crc;
}

