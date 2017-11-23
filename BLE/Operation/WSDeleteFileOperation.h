//
//  WSDeleteFileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/29.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSBaseOperation.h"

@interface WSDeleteFileOperation : WSBaseOperation

@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,assign) BOOL deleteSuc;

- (id) initWithPath:(NSString *)path;

@end
