//
//  CLIAPManager.h
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

NS_ASSUME_NONNULL_BEGIN

typedef void (^IAPBuyProductCompletion)(NSError *error);

typedef void (^IAPGetProductCompletion)(NSArray<SKProduct *> *array, NSError *error);


@interface CLIAPManager : NSObject


/**
 单例创建管理者
 
 @return 管理者
 */
+ (CLIAPManager *)sharedManager;


/**
 注册管理者

 @param userId 用户id
 */
- (void)registerManagerWithUserId:(NSString *)userId;


/**
 * 获取产品信息.
 */
- (void)getProductInfoWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers completion:(IAPGetProductCompletion)completion;


/**
 * 购买某个产品.
 */
- (void)buyProduct:(SKProduct *)product completion:(IAPBuyProductCompletion)completion;

@end

NS_ASSUME_NONNULL_END
