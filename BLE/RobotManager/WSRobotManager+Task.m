//
//  WSRobotManager+Task.m
//  StormtrooperS
//
//  Created by Glen on 2017/6/26.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import "WSRobotManager+Task.h"
#import "WSRobotManager+Property.h"
#import "WSRobotManager+FileOperation.h"
#import "WSBoardVersionOperation.h"
#import "WSRunTaskOperation.h"
#import "WSCancelTaskOperation.h"
#import "WSRetrieveTaskStateOperation.h"

@implementation WSRobotManager (Task)

- (WSRobotBindState)retrieveRobotBindStateWithUserId:(NSString *)userId
{
    int32_t bindState = [self readJsonFile:@"/sys/config.txt" name:@"bind_0"];
    
    if (bindState == 0) {
        NSLog(@"未绑定");
        return WSRobotUnbind;
    }else {
        NSLog(@"已绑定");
        NSData *accountData = [self readFile:@"/dat/ubt_0.txt" bytes:0];
        
        NSString *account = [[NSString alloc] initWithData:accountData encoding:NSUTF8StringEncoding];
        
        NSLog(@"关联的账号是====== %@", account);
        
        if (account == nil) {
            return WSRobotNotAssociate;
        }else if ([account isEqualToString:userId]) {
            return WSRobotAssociateMaster;
        }else {
            return WSRobotAssociateOtherAccount;
        }
    }
}

- (BOOL)startTask:(WSRoleType)role
{
    //正常流程应该是用这个命令，但是现在这个命令不会开始人脸识别，直接返回成功的状态，所以该用下面的命令开始人脸识别
//    WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"/script/task/task_train.txt" role:role];
 
    WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"/script/task/task_train_save.txt" role:role];
    [self addTask:op];

    BOOL result = op.isStartSuc;
    if (result == YES) {
        NSLog(@"任务开始成功");
    }else {
        NSLog(@"任务开始失败");
    }
    
    return result;
}

- (BOOL)cacelTask
{
//    WSCancelTaskOperation *cancelOp = [[WSCancelTaskOperation alloc] init];
//    [self addTask:cancelOp];
    return YES;
}

- (BOOL)confirmTask:(WSRoleType)role userId:(NSString *)userId
{
    WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"/script/task/task_train_save.txt" role:role];
    [self addTask:op];
    
    BOOL result = op.isStartSuc;
    if (result == YES) {
        NSLog(@"任务开始成功");
        
        if (role == WSRoleMaster) {
            //主人才需要
            if (userId == nil) {
                NSLog(@"关联的账号不能为空～～～～");
                return NO;
            }
            
            NSData *data = [userId dataUsingEncoding:NSUTF8StringEncoding];
            BOOL associateResult = [self writeFile:@"/dat/ubt_0.txt" data:data];
            
            if (associateResult) {
                NSLog(@"关联成功");
            }else {
                NSLog(@"关联失败");
            }
            
            return associateResult;
        }else {
            NSLog(@"确认添加熟人");
        }
    }else {
        NSLog(@"任务开始失败");
    }
    
    return result;
}

- (WSTaskState)retrieveTaskState
{
    WSRetrieveTaskStateOperation *op = [[WSRetrieveTaskStateOperation alloc] init];
    [self addTask:op];
    
    int32_t state = op.state;
    
    return state;
}

- (BOOL)startAssociateTask
{
    WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"/script/task/task_recognize.txt" role:WSRoleMaster];
    [self addTask:op];
    
    BOOL result = op.isStartSuc;
    if (result == YES) {
        NSLog(@"任务开始成功");
    }else {
        NSLog(@"任务开始失败");
    }
    
    return result;
}

- (BOOL)confirmAssociateAccount:(NSString *)userId
{
    if (userId == nil) {
        NSLog(@"关联的账号不能为空～～～～");
        return NO;
    }
    
    NSData *data = [userId dataUsingEncoding:NSUTF8StringEncoding];
    BOOL associateResult = [self writeFile:@"/dat/ubt_0.txt" data:data];

    if (associateResult) {
        NSLog(@"关联成功");
    }else {
        NSLog(@"关联失败");
    }
    
    return associateResult;
}

- (BOOL)unbindTask:(NSString *)userId
{
    BOOL deleteMasterInfo = [self deleteRole:WSRoleMaster];
    if (deleteMasterInfo)
    {
        BOOL deleteAssociateAccount = [self deleteFile:@"/dat/ubt_0.txt"];
        if (deleteAssociateAccount)
        {
            NSLog(@"解绑成功");
            //删除熟人列表
            [self deleteFile:@"/dat/nickname_1.txt"];
            [self deleteFile:@"/dat/nickname_2.txt"];
            [self deleteFile:@"/dat/nickname_3.txt"];
            [self deleteFile:@"/dat/nickname_4.txt"];
            [self deleteFile:@"/dat/robot_nickname.txt"];
            
            return YES;
        }else
        {
            NSLog(@"解绑失败");
            return NO;
        }
    }else
    {
        NSLog(@"解绑失败");
        return NO;
    }
    
    /*下面是正常的流程，目前解绑命令无效（删除不了绑定状态也不会删除关联的账号），所以暂时先用上面的流程处理*/
    /*
    NSData *accountData = [self readFile:@"/dat/ubt_0.txt" bytes:0];
    NSString *account = [[NSString alloc] initWithData:accountData encoding:NSUTF8StringEncoding];
    
    if ([userId isEqualToString:account]) {
        
        WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"script/task/task_recover.txt" role:WSRoleMaster];
        [self addTask:op];
        
        BOOL result = op.isStartSuc;
        if (result == YES) {
            NSLog(@"解绑成功");
        }else {
            NSLog(@"解绑失败");
        }
        return result;
    }else
    {
        NSLog(@"没有权限");
        return NO;
    }
     */
}

- (BOOL)deleteRole:(WSRoleType)role
{
    WSRunTaskOperation *op = [[WSRunTaskOperation alloc] initWithPath:@"/script/task/task_train_delete.txt" role:role];
    
    [self addTask:op];
    
    BOOL result = op.isStartSuc;
    if (result == YES) {
        NSLog(@"任务开始成功");
    }else {
        NSLog(@"任务开始失败");
    }
    
    return result;
}

- (BOOL)setRoleNickname:(NSString *)nickname roleId:(WSRoleType)role
{
    if (nickname == nil || nickname.length < 1)
    {
        NSLog(@"昵称不能为空！！");
        return NO;
    }
    
    if (role < WSRoleMaster || role > WSRoleFriend4)
    {
        NSLog(@"角色id越界～～");
        return NO;
    }
    
    NSString *bind_x = [NSString stringWithFormat:@"bind_%d", (int)role];
    int32_t bindState = [self readJsonFile:@"/sys/config.txt" name:bind_x];
    if (bindState != 1)
    {
        NSLog(@"尚未绑定该角色，无法设置昵称！！！");
        return NO;
    }
    
    NSString *path = [NSString stringWithFormat:@"/dat/nickname_%d.txt", (int)role];
    NSData *dataToBeWrite = [nickname dataUsingEncoding:NSUTF8StringEncoding];
    return [self writeFile:path data:dataToBeWrite];
}

- (NSString *)getRoleNickname:(WSRoleType)role
{
    if (role < WSRoleMaster || role > WSRoleFriend4)
    {
        NSLog(@"角色id越界～～");
        return nil;
    }
    
    NSString *bind_x = [NSString stringWithFormat:@"bind_%d", (int)role];
    int32_t bindState = [self readJsonFile:@"/sys/config.txt" name:bind_x];
    if (bindState != 1)
    {
        NSLog(@"尚未绑定该角色，无法获取昵称！！！");
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"/dat/nickname_%d.txt", (int)role];
    NSData *data = [self readFile:path bytes:0];
    if (data != nil)
    {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else
    {
        return nil;
    }
}

- (NSArray<WSRoleInfo *> *)getRoleList
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:WSRoleFriend4];
    for (WSRoleType role = WSRoleMaster; role <= WSRoleFriend4; role++)
    {
        NSString *bind_x = [NSString stringWithFormat:@"bind_%d", (int)role];
        int32_t bindState = [self readJsonFile:@"/sys/config.txt" name:bind_x];
        if (bindState == 1)
        {
            NSString *path = [NSString stringWithFormat:@"/dat/nickname_%d.txt", (int)role];
            NSData *data = [self readFile:path bytes:0];
            if (data != nil)
            {
                NSString *nickname = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                WSRoleInfo *info = [[WSRoleInfo alloc] init];
                info.nickname = nickname;
                info.role = role;
                [list addObject:info];
            }
        }
    }
    return list;
}

- (UIImage *)getRoleAvatar:(WSRoleType)role
{
    //TODO
    return nil;
}

@end



