//
//  WSRobotManager+Property.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager.h"

@interface WSRobotManager (Property)

/**
 获取版本号
 
 @return 版本号string格式
 */
- (NSString *)getBoardVersion;

/**
 获取可用舵机列表
 
 @return 命令是否回复（舵机数据保存于RobotManager单例中）
 */
- (BOOL)getOnlineServoList;

/**
 获取机器人昵称
 
 @return 昵称string
 */
- (NSString *)getRobotNickname;

/**
 设置机器人昵称
 
 @param nickname 昵称
 @return 设置是否成功
 */
- (BOOL)setRobotNickname:(NSString *)nickname;

/**
 读数据
 
 @param path 文件路径
 @param name 文件名称
 @return 值
 */
- (int32_t)readJsonFile:(NSString *)path name:(NSString *)name;

/**
 写数据

 @param path 路径
 @param name 文件名称
 @param value 值（编码问题，暂时不支持json）
 */
- (BOOL)writeJsonFile:(NSString *)path name:(NSString *)name value:(int32_t)value;

@end
