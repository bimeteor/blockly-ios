//
//  WSWriteFileValueOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSWriteFileValueOperation : WSBaseOperation

@property (nonatomic,strong) NSString *path;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,assign) int32_t value;

@property (nonatomic,assign) BOOL isWriteSuc;

- (id) initWithPath:(NSString *)path name:(NSString *)name value:(int32_t)value;

@end
