//
//  WSReadFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSReadFileOperation : WSBaseOperation

@property (nonatomic,assign) uint32_t filePointer;
@property (nonatomic,assign) uint16_t bytes;

@property (nonatomic,strong) NSData *data;

- (id) initWithFilePointer:(uint32_t)pointer readBytes:(uint16_t)bytes;

@end
