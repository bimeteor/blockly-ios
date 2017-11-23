//
//  WSWriteFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSWriteFileOperation : WSBaseOperation

@property (nonatomic,assign) uint32_t filePointer;
@property (nonatomic,strong) NSData *bytesForWrite;

@property (nonatomic,assign) uint16_t writeResult;

- (id) initWithFilePointer:(uint32_t)pointer writeData:(NSData *)bytes;

@end
