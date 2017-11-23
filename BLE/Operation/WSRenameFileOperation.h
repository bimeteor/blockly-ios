//
//  WSRenameFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSRenameFileOperation : WSBaseOperation

@property (nonatomic,strong) NSString *oldName;
@property (nonatomic,strong) NSString *name;    //newName

@property (nonatomic,assign) BOOL renameSuc;

- (id) initWithOldName:(NSString *)oldName newName:(NSString *)newName;

@end
