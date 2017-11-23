//
//  CRC32.h
//  WhiteSoldier
//
//  Created by Glen on 16/8/24.
//  Copyright © 2016年 ubtech. All rights reserved.
//

#ifndef CRC32_h
#define CRC32_h

#include <stdio.h>

#define CRC32_INIT_VALUE 0xFFFFFFFF

unsigned int crc32_standard(unsigned char *buffer, unsigned int size);

unsigned int crc32_custom(unsigned int crc, unsigned char *buffer, unsigned int size);



#endif /* CRC32_h */
