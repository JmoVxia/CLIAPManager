//
//  CLIAPTransactionModel.m
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import "CLIAPTransactionModel.h"

@implementation CLIAPTransactionModel

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                    transactionIdentifier:(NSString *)transactionIdentifier
                          transactionDate:(NSDate *)transactionDate {
    NSParameterAssert(productIdentifier);
    NSParameterAssert(transactionIdentifier);
    NSParameterAssert(transactionDate);
    NSString *errorString = nil;
    if (!productIdentifier.length || !transactionIdentifier.length || !transactionDate) {
        errorString = [NSString stringWithFormat:@"致命错误: 初始化贝聊钱包商品交易模型时, productIdentifier: %@, transactionIdentifier: %@, transactionDate: %@ 中有数据为空", productIdentifier, transactionIdentifier, [NSString stringWithFormat:@"%f", transactionDate.timeIntervalSince1970]];
    }
    
    if (errorString) {
        // 报告错误.
        NSLog(@"%@",errorString);
        return nil;
    }
    
    self = [super init];
    if (self) {
        _productIdentifier = productIdentifier;
        _transactionIdentifier = transactionIdentifier;
        _transactionDate = transactionDate;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _productIdentifier = [aDecoder decodeObjectForKey:@"productIdentifier"];
        _transactionIdentifier = [aDecoder decodeObjectForKey:@"transactionIdentifier"];
        _transactionDate = [aDecoder decodeObjectForKey:@"transactionDate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.productIdentifier forKey:@"productIdentifier"];
    [aCoder encodeObject:self.transactionIdentifier forKey:@"transactionIdentifier"];
    [aCoder encodeObject:self.transactionDate forKey:@"transactionDate"];
}

-(BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CLIAPTransactionModel class]]) {
        return NO;
    }
    return [self isEqualToModel:((CLIAPTransactionModel *)object)];
}

- (BOOL)isEqualToModel:(CLIAPTransactionModel *)object {
    BOOL isTransactionIdentifierMatch = [self.transactionIdentifier isEqualToString:object.transactionIdentifier];
    BOOL isProductIdentifierMatch = [self.productIdentifier isEqualToString:object.productIdentifier];
    return isTransactionIdentifierMatch && isProductIdentifierMatch;
}

@end
