//
//  CLIAPKeychain.m
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import "CLIAPKeychain.h"
#import <CommonCrypto/CommonCrypto.h>


@implementation CLIAPKeychain

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:(id)kSecClassGenericPassword,(id)kSecClass,
            [self sha256WithString:service], (id)kSecAttrService,
            [self sha256WithString:service], (id)kSecAttrAccount,
            (id)kSecAttrAccessibleAfterFirstUnlock,(id)kSecAttrAccessible,
            nil];
}

+ (void)saveArray:(NSArray *)array service:(NSString *)service {
    [self saveDate:array service:service];
}

+ (void)saveDictionary:(NSDictionary *)dictionary service:(NSString *)service {
    [self saveDate:dictionary service:service];
}
//MARK:JmoVxia---储存数据，添加与更新 为同一方法, 不进行判断, 直接先删除后添加
+ (void)saveDate:(id)data service:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)keychainQuery);
    NSData *aesData =  [self aes256EncryptWithKey:@"Com.CLIAP.Keychain" dataSource:[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil]];
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:aesData] forKey:(id)kSecValueData];
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
}

+ (NSArray *)readArray:(NSString *)service {
    return (NSArray *)[self readData:service];
}

+ (NSDictionary *)readDictionary:(NSString *)service {
    return (NSDictionary *)[self readData:service];
}

//MARK:JmoVxia---读取
+ (id)readData:(NSString *)service {
    id ret = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [keychainQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            ret = [NSJSONSerialization JSONObjectWithData:[self aes256DecryptWithKey:@"Com.CLIAP.Keychain" dataSource:[NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData]] options:NSJSONReadingMutableLeaves error:nil];
        } @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        } @finally {
        }
    }
    if (keyData)
        CFRelease(keyData);
    return ret;
}
//MARK:JmoVxia---删除
+ (void)delete:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((CFDictionaryRef)keychainQuery);
}

+ (NSString *)sha256WithString:(NSString *)string {
    NSMutableData *shaData = [NSMutableData data];
    
    [shaData appendData:[@"JmoVxia=-CLIAPKeychain-=JmoVxia" dataUsingEncoding:NSUTF8StringEncoding]];
    [shaData appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [shaData appendData:[@"JmoVxia=-CLIAPKeychain-=JmoVxia" dataUsingEncoding:NSUTF8StringEncoding]];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(shaData.bytes, (CC_LONG)shaData.length, digest);
    
    NSMutableString *sha256String = [NSMutableString string];
    
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [sha256String appendFormat:@"%02x", digest[i]];
    }
    return [sha256String uppercaseString];
}


//MARK:JmoVxia---加密
+ (NSData *)aes256EncryptWithKey:(NSString *)key dataSource:(NSData *)source {
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [source length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [source bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }else{
        free(buffer);
        return nil;
    }
}
//MARK:JmoVxia---解密
+ (NSData *)aes256DecryptWithKey:(NSString *)key dataSource:(NSData *)source {
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [source length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [source bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }else{
        free(buffer);
        return nil;
    }
}


+ (BOOL)savePaymentTransactionModel:(CLIAPTransactionModel *)model userid:(NSString *)userid {
    NSMutableArray<CLIAPTransactionModel *> *array = [NSMutableArray arrayWithArray:[self readArray:userid]];
    if (!array) {
        array = [NSMutableArray array];
    }
    __block BOOL isHave = NO;
    [array enumerateObjectsUsingBlock:^(CLIAPTransactionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqual:model]) {
            isHave = YES;
            *stop = YES;
        }
    }];
    if (isHave) {
        return NO;
    }else {
        [array addObject:model];
        [self saveArray:array service:userid];
        return YES;
    }
}

+ (NSArray<CLIAPTransactionModel *> *)getAllPaymentTransactionModelsUsingComparator:(NSComparator)comparator userid:(NSString *)userid {
    NSParameterAssert(userid);
    if (!userid) {
        return nil;
    }
    
    NSArray<CLIAPTransactionModel *> *models = [NSMutableArray arrayWithArray:[self readArray:userid]];
    if (!models.count) {
        return nil;
    }
    
    if (models.count == 1 || !comparator) {
        return models;
    }
    
    if (comparator) {
        return [models sortedArrayUsingComparator:comparator];
    }
    return models;
}

+ (BOOL)deletePaymentTransactionModelWithTransactionIdentifier:(NSString *)transactionIdentifier userid:(NSString *)userid {
    if (!transactionIdentifier || !userid) {
        return NO;
    }
    NSMutableArray<CLIAPTransactionModel *> *models = [NSMutableArray arrayWithArray:[self readArray:userid]];
    if (!models.count) {
        return NO;
    }
    
    __block BOOL isHave = NO;
    __block CLIAPTransactionModel *deleteModel;
    [models enumerateObjectsUsingBlock:^(CLIAPTransactionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.transactionIdentifier isEqualToString:transactionIdentifier]) {
            isHave = YES;
            deleteModel = obj;
            *stop = YES;
        }
    }];
    
    if (!isHave) {
        NSLog(@"%@", [NSString stringWithFormat:@"keychain 不存在 transactionIdentifier 为: %@ 的数据.", transactionIdentifier]);
        return NO;
    }else {
        [models removeObject:deleteModel];
        [self saveArray:models service:userid];
        return YES;
    }
}

@end
