//
//  CLIAPKeychain.h
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLIAPTransactionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CLIAPKeychain : NSObject

/**
 * 存储交易模型
 */
+ (void)savePaymentTransactionModel:(CLIAPTransactionModel *)model userid:(NSString *)userid;

/**
 * 获取所有交易模型, 并排序
 */
+ (NSArray<CLIAPTransactionModel *> *)getAllPaymentTransactionModelsUsingComparator:(NSComparator)comparator userid:(NSString *)userid;

/**
 * 删除指定 `transactionIdentifier` 的交易模型.
 *
 * @param transactionIdentifier 交易模型唯一标识.
 * @param userid                用户 id.
 *
 * @return 是否删除成功. 失败的原因可能是因为标识无效(已存储数据中没有指定的标识的数据).
 */
+ (BOOL)deletePaymentTransactionModelWithTransactionIdentifier:(NSString *)transactionIdentifier userid:(NSString *)userid;


@end

NS_ASSUME_NONNULL_END
