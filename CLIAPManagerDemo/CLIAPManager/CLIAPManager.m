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

@property (nonatomic, strong) NSString *purchID;

@property (nonatomic, copy) IAPCompletionHandle handle;
/**用户唯一标识符*/
@property (nonatomic, copy) NSString *userId;



/**支付凭证*/
@property (nonatomic, strong) NSData *transactionReceiptData;




//**转子*/
//@property (nonatomic, strong) MBProgressHUD *hud;

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
+ (CLIAPManager *)sharedMangerWithUserId:(NSString *)userId {
    _manger = [[self alloc] init];
    _manger.userId = userId;
    return _manger;
}

-(instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manger = [super init];
        //购买监听写在程序入口,程序挂起时移除监听,这样如果有未完成的订单将会自动执行并回调 paymentQueue:updatedTransactions:方法
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
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


#pragma mark - Public Method
- (void)startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle {
    if (purchID) {
        if ([SKPaymentQueue canMakePayments]) {
            // 开始购买服务，请求商品信息
            self.purchID = purchID;
            self.handle = handle;
            NSSet *nsset = [NSSet setWithArray:@[purchID]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            [request start];
        }else {
            [self handleActionWithType:kIAPPurchNotArrow data:nil];
        }
    }
}
#pragma mark - SKProductsRequestDelegate
//MARK:JmoVxia---请求内购商品信息反馈
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *productArray = response.products;
    if([productArray count] <= 0) {
        NSLog(@"--------------没有商品------------------");
        return;
    }
    SKProduct *product = nil;
    for (SKProduct *pro in productArray) {
        if ([pro.productIdentifier isEqualToString:self.purchID]) {
            product = pro;
            break;
        }
    }
    NSLog(@"发送购买请求");
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
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
    CLIAPTransactionModel *model = [self generateTransactionModelWithPaymentTransaction:transaction];
    [CLIAPKeychain savePaymentTransactionModel:model userid:self.userId];
    self.transactionReceiptData = [self fetchTransactionReceiptDataInCurrentDevice];
    if (self.transactionReceiptData.length) {
        NSLog(@"发起后台验证");
        
        //验证成功，删除
        [self finishATransation:transaction];
        
        
        //验证失败
        //1.上传到后台失败，找几乎重新传
        
        //2.后台验证失败
        
        
    }else {
        NSLog(@"支付凭证不存在");
    }
}
// 交易失败.
- (void)transactionFailed:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"购买失败");
    }
    else {
        NSLog(@"用户取消交易");
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
//JmoVxia---请求支付凭证结束
- (void)requestDidFinish:(SKRequest *)request{
    
    NSLog(@"------------反馈信息结束-----------------");
}


#pragma mark - Private Method
- (void)handleActionWithType:(IAPPurchType)type data:(NSData *)data{
#if DEBUG
    switch (type) {
        case kIAPPurchSuccess:
            NSLog(@"购买成功");
            break;
        case kIAPPurchFailed:
            NSLog(@"购买失败");
            break;
        case kIAPPurchCancle:
            NSLog(@"用户取消购买");
            break;
        case KIAPPurchVerFailed:
            NSLog(@"订单校验失败");
            break;
        case KIAPPurchVerSuccess:
            NSLog(@"订单校验成功");
            break;
        case kIAPPurchNotArrow:
            NSLog(@"不允许程序内付费");
            break;
        default:
            break;
    }
#endif
    if(self.handle){
        self.handle(type,data);
    }
}

- (CLIAPTransactionModel *)generateTransactionModelWithPaymentTransaction:(SKPaymentTransaction *)transaction {
    return [[CLIAPTransactionModel alloc] initWithProductIdentifier:transaction.payment.productIdentifier transactionIdentifier:transaction.transactionIdentifier transactionDate:transaction.transactionDate];
}
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

@end
