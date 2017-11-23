//
//  WSRunTaskOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"
#import "WSRoleInfo.h"
 
@interface WSRunTaskOperation : WSBaseOperation
{
    int32_t s32params[10];
}

@property (nonatomic,strong) NSString *path;
@property (nonatomic,assign) WSRoleType role;
@property (nonatomic,assign) BOOL isStartSuc;

- (id) initWithPath:(NSString *)path role:(WSRoleType)role;

@end
