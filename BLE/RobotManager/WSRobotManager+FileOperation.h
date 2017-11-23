//
//  WSRobotManager+FileOperation.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager.h"
#import "WSOpenFileOperation.h"

@interface WSRobotManager (FileOperation)

- (WSOpenFileOperation *)openFile:(NSString *)filename fileMode:(FILEMODE)fileMode;

- (NSData *)readFile:(NSString *)path bytes:(uint32_t)bytes;

- (BOOL)writeFile:(NSString *)path data:(NSData *)data;

- (BOOL)renameFile:(NSString *)oldName newName:(NSString *)newName;

- (BOOL)deleteFile:(NSString *)filename;

- (BOOL)closeFile:(uint32_t)filePointer;

@end
