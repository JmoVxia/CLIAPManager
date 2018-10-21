//
//  CLIAPManager.m
//  CLIAPManagerDemo
//
//  Created by AUG on 2018/10/20.
//  Copyright © 2018年 JmoVxia. All rights reserved.
//

#import "CLIAPManager.h"
#import <StoreKit/StoreKit.h>
#import "CLIAPTransactionModel.h"
#import "CLIAPKeychain.h"

//第1步: 存储唯一实例
static CLIAPManager *_manger = nil;

@interface CLIAPManager () <SKPaymentTransactionObserver,SKProductsRequestDelegate,SKRequestDelegate>


@property (nonatomic, copy) IAPBuyProductCompletion buyProductCompletion;
/**内购产品信息回掉*/
@property (nonatomic, copy) IAPGetProductCompletion getProductCompletion;

/**用户唯一标识符*/
@property (nonatomic, copy) NSString *userId;

/**支付凭证*/
@property (nonatomic, strong) NSData *transactionReceiptData;

/**当前内购商品*/
@property (nonatomic, strong) SKPayment *lastPayment;


@end

@implementation CLIAPManager


//第2步: 分配内存空间时都会调用这个方法. 保证分配内存alloc时都相同.
+(id)allocWithZone:(struct _NSZone *)zone{
    //调用dispatch_once保证在多线程中也只被实例化一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [super allocWithZone:zone];
    });
    return _manger;
}
//第3步: 保证init初始化时都相同
+ (CLIAPManager *)sharedManager {
    _manger = [[self alloc] init];
    return _manger;
}

-(instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [super init];
    });
    return _manger;
}
//第4步: 保证copy时都相同
-(id)copyWithZone:(NSZone *)zone{
    return _manger;
}
//第五步: 保证mutableCopy时相同
- (id)mutableCopyWithZone:(NSZone *)zone{
    return _manger;
}
-(NSData *)transactionReceiptData {
    return [self fetchTransactionReceiptDataInCurrentDevice];
}
//MARK:JmoVxia---注册管理者
- (void)registerManagerWithUserId:(NSString *)userId {
    if (self.userId) {
        return;
    }
    if (userId) {
        self.userId = userId;
        //购买监听写在程序入口,程序挂起时移除监听,这样如果有未完成的订单将会自动执行并回调 paymentQueue:updatedTransactions:方法
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [self checkUnverifyTransactionWithUserId:userId];
    }else {
        NSLog(@"userId 不能为空");
    }
}
//MARK:JmoVxia---注销管理者
- (void)logoutPaymentManager {
    self.userId = nil;
    self.getProductCompletion = nil;
    self.buyProductCompletion = nil;
    self.lastPayment = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
//MARK:JmoVxia---所有订单都完成验证
- (BOOL)allVerifyWasSuccess {
    return [self checkUnverifyTransactionWithUserId:self.userId];
}
//MARK:JmoVxia---检查未验证订单
- (BOOL)checkUnverifyTransactionWithUserId:(NSString *)userId {
    //队列中还有
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray<SKPaymentTransaction *> *transactionsWaitingForVerifing = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in transactionsWaitingForVerifing) {
        BOOL success = [CLIAPKeychain savePaymentTransactionModel:[self createTransactionModelWithPaymentTransaction:transaction] userid:userId];
        if (success) {
            [dictionary setObject:transaction forKey:transaction.transactionIdentifier];
        }
    }
    NSArray<CLIAPTransactionModel *> * models = [CLIAPKeychain getAllPaymentTransactionModelsUsingComparator:^NSComparisonResult(CLIAPTransactionModel *obj1, CLIAPTransactionModel *obj2) {
        return [obj1.transactionDate compare:obj2.transactionDate]; // 日期升序排序.
    } userid:userId];
    if (models.count) {
        //钥匙串还有未完成验证的数据
        for (CLIAPTransactionModel *model in models) {
//            NSString *receipts = [self.transactionReceiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
//            NSString *product_id = model.productIdentifier;
//            NSString *transaction_id = model.transactionIdentifier;
            //上传成功，删除
            SKPaymentTransaction *transaction = [dictionary objectForKey:model.transactionIdentifier];
            if (transaction) {
                //队列和钥匙串都有
                //验证成功
                [self buyProductCompletionWithProduct:transaction.payment string:nil];
                //验证失败
                [self buyProductCompletionWithProduct:transaction.payment string:@"验证失败"];
                //上传凭证失败
                [self buyProductCompletionWithProduct:transaction.payment string:@"上传凭证失败"];
                [self finishATransation:[dictionary objectForKey:model.transactionIdentifier]];
            }else {
                //只有钥匙串有
                [CLIAPKeychain deletePaymentTransactionModelWithTransactionIdentifier:model.transactionIdentifier userid:self.userId];
            }
        }
        return NO;
    }else {
        return YES;
    }
}
//MARK:JmoVxia---获取内购商品信息
- (void)getProductInfoWithProductIdentifiers:(NSSet<NSString *> *)productIdentifiers completion:(IAPGetProductCompletion)completion {
    self.getProductCompletion = completion;
    if (productIdentifiers) {
        if ([SKPaymentQueue canMakePayments]) {
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
            request.delegate = self;
            [request start];
        }else {
            if (self.getProductCompletion) {
                NSArray<SKProduct *> *array;
                self.getProductCompletion(array, [self createErrorWithString:@"不支持内购"]);
            }
        }
    }
}
//MARK:JmoVxia---购买内购商品
- (void)buyProduct:(SKProduct *)product completion:(IAPBuyProductCompletion)completion {
    self.buyProductCompletion = completion;
    if (product) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        self.lastPayment = payment;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark - SKProductsRequestDelegate
//MARK:JmoVxia---请求内购商品信息反馈
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray<SKProduct *> *productArray = response.products;
    if([productArray count] <= 0) {
        if (self.getProductCompletion) {
            NSArray<SKProduct *> *array;
            self.getProductCompletion(array, [self createErrorWithString:@"没有商品"]);
        };
    }else {
        if (self.getProductCompletion) {
            NSError *error;
            self.getProductCompletion(productArray,error);
        };
    }
}

#pragma mark - SKPaymentTransactionObserver
//MARK:JmoVxia---内购订单回掉
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 这里的事务包含之前没有完成的.
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                [self transactionPurchasing:transaction];
                break;
                
            case SKPaymentTransactionStatePurchased:
                [self transactionPurchased:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self transactionFailed:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self transactionRestored:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                [self transactionDeferred:transaction];
                break;
        }
    }
}
// 交易中.
- (void)transactionPurchasing:(SKPaymentTransaction *)transaction {
    NSLog(@"交易中...");
}
// 交易成功.
- (void)transactionPurchased:(SKPaymentTransaction *)transaction {
    NSLog(@"交易成功...");
    //收到交易成功，先写入钥匙串，钥匙串内部自动判断是否存在
    CLIAPTransactionModel *model = [self createTransactionModelWithPaymentTransaction:transaction];
    [CLIAPKeychain savePaymentTransactionModel:model userid:self.userId];
    if (self.transactionReceiptData.length) {
        [self checkUnverifyTransactionWithUserId:self.userId];
    }else {
        [self buyProductCompletionWithProduct:transaction.payment string:@"支付凭证不存在"];
    }
}
// 交易失败.
- (void)transactionFailed:(SKPaymentTransaction *)transaction {
    if(transaction.error.code == SKErrorPaymentCancelled) {
        [self buyProductCompletionWithProduct:transaction.payment string:@"取消购买"];
    }
    else {
        [self buyProductCompletionWithProduct:transaction.payment string:@"购买失败"];
    }
    [self finishATransation:transaction];
}

// 已经购买过该商品.
- (void)transactionRestored:(SKPaymentTransaction *)transaction {
    NSLog(@"已经购买过该商品...");
}

// 交易延期.
- (void)transactionDeferred:(SKPaymentTransaction *)transaction {
    NSLog(@"交易延期...");
}

//MARK:JmoVxia---获取支付凭证
- (NSData *)fetchTransactionReceiptDataInCurrentDevice {
    NSURL *appStoreReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *data = [NSData dataWithContentsOfURL:appStoreReceiptURL];
    if(!data){
        //刷新支付凭证
        SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
        request.delegate = self;
        [request start];
    }
    return data;
}
//MARK:JmoVxia---SKRequestDelegate
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"------------------错误-----------------:%@", error);
}
- (void)requestDidFinish:(SKRequest *)request{
    
    NSLog(@"------------反馈信息结束-----------------");
}
//MARK:JmoVxia---创建订单模型
- (CLIAPTransactionModel *)createTransactionModelWithPaymentTransaction:(SKPaymentTransaction *)transaction {
    return [[CLIAPTransactionModel alloc] initWithProductIdentifier:transaction.payment.productIdentifier transactionIdentifier:transaction.transactionIdentifier transactionDate:transaction.transactionDate];
}
//MARK:JmoVxia---结束订单
- (void)finishATransation:(SKPaymentTransaction *)transaction {
    NSParameterAssert(transaction);
    if (!transaction) {
        return;
    }
    // 不能完成一个正在交易的订单.
    if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
        return;
    }
    //删除队列和钥匙串中订单
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [CLIAPKeychain deletePaymentTransactionModelWithTransactionIdentifier:transaction.transactionIdentifier userid:self.userId];
}
//MARK:JmoVxia---创建错误
- (NSError *)createErrorWithString:(NSString *)string {
    NSError *error = [NSError errorWithDomain:@"com.CLIAPManager.error" code:0 userInfo:@{NSLocalizedDescriptionKey : string}];
    return error;
}
//MARK:JmoVxia---是否是当前的订单
- (BOOL)isEqualProduct:(SKPayment *)payment {
    if ([self.lastPayment.productIdentifier isEqualToString:payment.productIdentifier] && [self.lastPayment.requestData isEqualToData:payment.requestData]) {
        return YES;
    }else {
        return NO;
    }
}
//MARK:JmoVxia---回掉
- (void)buyProductCompletionWithProduct:(SKPayment *)payment string:(NSString *)string {
    if ([self isEqualProduct:payment]) {
        if (string) {
            if (self.buyProductCompletion) {
                self.buyProductCompletion([self createErrorWithString:string]);
            }
        }else {
            NSError *error;
            if (self.buyProductCompletion) {
                self.buyProductCompletion(error);
            }
        }
    }
}

@end
