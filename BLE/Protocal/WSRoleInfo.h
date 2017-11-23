//
//  WSRoleInfo.h
//  StormtrooperS
//
//  Created by Glen on 2017/7/11.
//  Copyright © 2017年 UBTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WSRoleType) {
    WSRoleMaster = 0,
    WSRoleFriend1 = 1,
    WSRoleFriend2 = 2,
    WSRoleFriend3 = 3,
    WSRoleFriend4 = 4,
};


@interface WSRoleInfo : NSObject

@property (nonatomic,assign) WSRoleType role;
@property (nonatomic,copy) NSString  *nickname;
@property (nonatomic,strong) NSData *imageData; //头像信息

@end
