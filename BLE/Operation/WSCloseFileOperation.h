//
//  WSCloseFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSCloseFileOperation : WSBaseOperation

@property (nonatomic,assign) uint32_t filePointer;  // 文件句柄

@property (nonatomic,assign) BOOL closeSuc;

- (id) initWithFilePointer:(uint32_t)pointer;

@end
