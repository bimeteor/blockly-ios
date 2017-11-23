//
//  WSRobotManager+Task.h
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager.h"
#import "WSRoleInfo.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WSRobotBindState) {
    WSRobotUnbind = 0,              //未绑定
    WSRobotNotAssociate = 1,        //已绑定未关联账号
    WSRobotAssociateMaster = 2,     //已绑定并关联当前帐号
    WSRobotAssociateOtherAccount    //已绑定并关联其他账号
};

typedef NS_ENUM(NSUInteger, WSTaskState) {
    WSTaskStateNone = 0,        //无操作
    WSTaskStateWillStart,       //接收到启动任务命令
    WSTaskStateStarting,        //启动任务中
    WSTaskStateStartFailed,     //任务启动失败
    WSTaskStateProcess,         //任务处理中
    WSTaskStateSuccess,         //任务成功
    WSTaskStateFailed,          //任务失败
    WSTaskStateTimeout,         //任务超时
    
    WSTaskStateWillCancel = 8,  //接收到取消任务命令
    WSTaskStateStartCancel,     //启动取消任务中
    WSTaskStateCancelStartFailed,    //取消任务启动失败
    WSTaskStateCancelling,      //启动取消任务中
    WSTaskStateCancelProcess,   //取消任务处理中
    WSTaskStateCancelSuccess,   //取消任务成功
    WSTaskStateCancelFailed,    //取消任务失败
    WSTaskStateCancelTimeout    //取消任务超时
};


@interface WSRobotManager (Task)

/**
 查询机器人绑定状态

 @param userId 当前登录的用户id
 @return 绑定状态
 */
- (WSRobotBindState)retrieveRobotBindStateWithUserId:(NSString *)userId;

/**
 发起任务【包括绑定主人任务、添加熟人任务】

 @param role 角色【0---主人，1、2、3、4分别为熟人下标】
 @return 任务是否开始成功
 */
- (BOOL)startTask:(WSRoleType)role;

/**
 取消当前进行的任务
 */
- (BOOL)cacelTask;

/**
 开始确认任务【包括确认绑定主人、确认添加熟人】
 */
- (BOOL)confirmTask:(WSRoleType)role userId:(NSString *)userId;

/**
  查询任务状态

 @return 任务状态
 */
- (WSTaskState)retrieveTaskState;

/**
 开始关联任务

 @return 任务是否开启成功
 */
- (BOOL)startAssociateTask;

/**
 确认关联账号

 @param userId 账号
 @return 确认关联任务的状态
 */
- (BOOL)confirmAssociateAccount:(NSString *)userId;

/**
 解除绑定账号

 @param userId 账号
 @return 解绑结果
 */
- (BOOL)unbindTask:(NSString *)userId;

/**
 删除角色

 @param role 角色下标
 @return 删除结果
 */
- (BOOL)deleteRole:(WSRoleType)role;

/**
 设置角色昵称
 
 @param nickname 昵称
 @param role 角色id
 @return 是否设置成功
 */
- (BOOL)setRoleNickname:(NSString *)nickname roleId:(WSRoleType)role;

/**
 获取角色昵称
 
 @param role 角色id
 @return 昵称字符串
 */
- (NSString *)getRoleNickname:(WSRoleType)role;

/**
 获取角色列表
 
 @return 角色对象数组
 */
- (NSArray<WSRoleInfo *> *)getRoleList;

/**
 获取用户头像
 
 @param role 角色
 @return 图像对象
 */
- (UIImage *)getRoleAvatar:(WSRoleType)role;

@end
