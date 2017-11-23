//
//  WSBoardVersionOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSBoardVersionOperation : WSBaseOperation

@property (nonatomic,assign) NSUInteger bufferSize;
@property (nonatomic,copy) NSString *versionString;

@end
