//
//  WSRobotManager+Property.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager+Property.h"
#import "WSBoardVersionOperation.h"
#import "WSOnlineServoOperation.h"
#import "WSReadFileValueOperation.h"
#import "WSWriteFileValueOperation.h"
#import "WSRobotManager+FileOperation.h"

@implementation WSRobotManager (Property)

- (NSString *)getBoardVersion
{
    WSBoardVersionOperation *operation = [[WSBoardVersionOperation alloc] init];
    [self addTask:operation];
    return operation.versionString;
}

- (BOOL)getOnlineServoList
{
    WSOnlineServoOperation *operation = [[WSOnlineServoOperation alloc] init];
    [self addTask:operation];
    
    if (operation.servoList.count > 0) {
        [self.motorIdentifiers addObjectsFromArray:operation.servoList];        
        return YES;
    }
    
    return NO;
}

- (NSString *)getRobotNickname
{
    NSData *data = [self readFile:@"/dat/robot_nickname.txt" bytes:0];
    if (data != nil)
    {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (BOOL)setRobotNickname:(NSString *)nickname
{
    if (nickname == nil || nickname.length < 1)
    {
        NSLog(@"昵称不能为空～！！");
    }
    
    NSData *dataToBeWrite = [nickname dataUsingEncoding:NSUTF8StringEncoding];
    return [self writeFile:@"/dat/robot_nickname.txt" data:dataToBeWrite];
}

- (int32_t)readJsonFile:(NSString *)path name:(NSString *)name
{
    WSReadFileValueOperation *operation = [[WSReadFileValueOperation alloc] initWithPath:path name:name];
    [self addTask:operation];
    return operation.value;
}


- (BOOL)writeJsonFile:(NSString *)path name:(NSString *)name value:(int32_t)value
{
    WSWriteFileValueOperation *operation = [[WSWriteFileValueOperation alloc] initWithPath:path name:name value:value];
    [self addTask:operation];
    return operation.isWriteSuc;
}

@end
