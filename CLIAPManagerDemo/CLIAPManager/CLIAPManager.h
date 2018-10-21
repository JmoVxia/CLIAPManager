//
//  CLIAPManager.h
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kIAPPurchSuccess = 0,       // 购买成功
    kIAPPurchFailed = 1,        // 购买失败
    kIAPPurchCancle = 2,        // 取消购买
    KIAPPurchVerFailed = 3,     // 订单校验失败
    KIAPPurchVerSuccess = 4,    // 订单校验成功
    kIAPPurchNotArrow = 5,      // 不允许内购
}IAPPurchType;

typedef void (^IAPCompletionHandle)(IAPPurchType type,NSData *data);


@interface CLIAPManager : NSObject


/**
 单例创建管理者
 
 @return 缓存管理者
 */
+ (CLIAPManager *)sharedMangerWithUserId:(NSString *)userId;

- (void)startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle;


@end

NS_ASSUME_NONNULL_END
