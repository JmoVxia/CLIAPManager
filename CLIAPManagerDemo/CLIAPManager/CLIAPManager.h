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

typedef void (^IAPGetProductCompletion)(NSArray<SKProduct *> * _Nullable array, NSError *error);


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
 注销管理者
 */
- (void)logoutPaymentManager;



/**
 获取内购产品信息

 @param productIdentifiers 产品标识符集合
 @param completion 内购产品回掉
 */
- (void)getProductInfoWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers completion:(IAPGetProductCompletion)completion;



/**
 购买内购商品

 @param product 商品
 @param completion 结果回掉
 */
- (void)buyProduct:(SKProduct *)product completion:(IAPBuyProductCompletion)completion;

@end

NS_ASSUME_NONNULL_END
