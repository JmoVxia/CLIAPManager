//
//  CLIAPTransactionModel.h
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLIAPTransactionModel : NSObject


/**
 * 交易编号.
 */
@property(nonatomic, copy, nonnull, readonly) NSString *transactionIdentifier;

/**
 * 交易时间(添加到交易队列时的时间).
 */
@property(nonatomic, strong, readonly) NSDate *transactionDate;

/**
 * 内购产品编号.
 */
@property(nonatomic, copy, readonly) NSString *productIdentifier;


/**
 * 初始化方法(没有收据的).
 *
 * @warning: 所有数据都必须有值, 否则会报错, 并返回 nil.
 *
 * @param productIdentifier       内购产品编号.
 * @param transactionIdentifier   交易编号.
 * @param transactionDate         交易时间(添加到交易队列时的时间).
 */
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                    transactionIdentifier:(NSString *)transactionIdentifier
                          transactionDate:(NSDate *)transactionDate;

@end

NS_ASSUME_NONNULL_END
