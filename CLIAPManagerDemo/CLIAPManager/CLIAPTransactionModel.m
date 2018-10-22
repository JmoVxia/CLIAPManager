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
                          transactionDate:(NSDate *)transactionDate userId:(NSString *)userId{
    if (!productIdentifier.length || !transactionIdentifier.length || !transactionDate || userId) {
        return nil;
    }
    self = [super init];
    if (self) {
        _productIdentifier = productIdentifier;
        _transactionIdentifier = transactionIdentifier;
        _transactionDate = transactionDate;
        _userId = userId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _productIdentifier = [aDecoder decodeObjectForKey:@"productIdentifier"];
        _transactionIdentifier = [aDecoder decodeObjectForKey:@"transactionIdentifier"];
        _transactionDate = [aDecoder decodeObjectForKey:@"transactionDate"];
        _userId = [aDecoder decodeObjectForKey:@"userId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.productIdentifier forKey:@"productIdentifier"];
    [aCoder encodeObject:self.transactionIdentifier forKey:@"transactionIdentifier"];
    [aCoder encodeObject:self.transactionDate forKey:@"transactionDate"];
    [aCoder encodeObject:self.userId forKey:@"userId"];
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
    BOOL isTransactionDate = [self.transactionDate isEqualToDate:object.transactionDate];
    BOOL isUserId = [self.userId isEqualToString:object.userId];
    return isTransactionIdentifierMatch && isProductIdentifierMatch && isTransactionDate && isUserId;
}

@end
