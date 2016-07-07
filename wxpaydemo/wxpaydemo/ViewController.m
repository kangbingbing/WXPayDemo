//
//  ViewController.m
//  wxpaydemo
//
//  Created by kangbing on 16/7/5.
//  Copyright © 2016年 kangbing. All rights reserved.
//

#import "ViewController.h"
#import "getIPhoneIP.h"
#import "AFNetworking.h"
#import "DataMD5.h"
#import "XMLDictionary.h"
#import "WXApi.h"

// 统一下单 url
#define url @"https://api.mch.weixin.qq.com/pay/unifiedorder"
//微信支付分配的商户号
#define PID  @"1900000109"
//开户邮件中的（公众账号APPID或者应用APPID）
#define AppID @"wx49b373290112309f"
//安全校验码（MD5）密钥，商户平台登录账户和密码登录http://pay.weixin.qq.com 平台设置的“API密钥”，为了安全，请设置为以数字和字母组成的32字符串。
#define WX_PartnerKey @"YOUR_WX_PartnerKey"
//获取用户openid，可使用APPID对应的公众平台登录开发者中心获取AppSecret。
//#define WX_AppSecret @"d1e3bdb8768e2427077264594471341f" // 好像没有什么用


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btnClick;

@end

@implementation ViewController
#pragma mark 点击进行支付
- (IBAction)btnClick:(id)sender {
    
    NSLog(@"点击支付");
    NSString *appid,*mch_id,*nonce_str,*sign,*body,*out_trade_no,*total_fee,*spbill_create_ip,*notify_url,*trade_type,*partner;
    //应用APPID
    appid = AppID;
    //微信支付商户号
    mch_id = PID;
    //产生随机字符串
    nonce_str =[self generateTradeNO];
    body =@"支付时候看到的支付信息";
    //随机产生订单号用于测试，正式使用请换成你从自己服务器获取的订单号
    out_trade_no = nonce_str;
    //以分为单位, 支付宝是以元
    total_fee = @"1";
    //获取本机IP地址，请再wifi环境下测试，否则获取的ip地址为error，正确格式应该是8.8.8.8
    spbill_create_ip =[getIPhoneIP getIPAddress];
    //交易结果通知网站此处用于测试，随意填写，正式使用时填写正确网站
    notify_url =@"www.baidu.com";
    trade_type =@"APP";
    //商户密钥
    partner = WX_PartnerKey;
    //获取sign签名, // 1进行字典赋值, 2排序, 3拼接商户partnerkey, 4 MD5大写加密
    DataMD5 *data = [[DataMD5 alloc] initWithAppid:appid mch_id:mch_id nonce_str:nonce_str partner_id:partner body:body out_trade_no:out_trade_no total_fee:total_fee spbill_create_ip:spbill_create_ip notify_url:notify_url trade_type:trade_type];
    // 根据字典进行MD5  key 已写死, 直接赋值以上 value (notify_url)
    sign = [data getSignForMD5];
    //设置参数并转化成xml格式
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:appid forKey:@"appid"];//公众账号ID
    [dic setValue:mch_id forKey:@"mch_id"];//商户号
    [dic setValue:nonce_str forKey:@"nonce_str"];//随机字符串
    [dic setValue:sign forKey:@"sign"];//签名
    [dic setValue:body forKey:@"body"];//商品描述
    [dic setValue:out_trade_no forKey:@"out_trade_no"];//订单号
    [dic setValue:total_fee forKey:@"total_fee"];//金额
    [dic setValue:spbill_create_ip forKey:@"spbill_create_ip"];//终端IP,
    [dic setValue:notify_url forKey:@"notify_url"];//通知地址
    [dic setValue:trade_type forKey:@"trade_type"];//交易类型
    // 转换成xml字符串
    NSString *string = [dic XMLString];
    [self http:string];
    
}



#pragma mark - 用转换好的 xml去请求
- (void)http:(NSString *)xml {
    // 开始支付, 调用统一下单 API
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 记得转义
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    [manager.requestSerializer setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:url forHTTPHeaderField:@"SOAPAction"];
    [manager.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        return xml;
    }];
    // 统一下单发起请求
    [manager POST:url parameters:xml progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] ;
        NSLog(@"%@",responseString);
        //将微信返回的xml数据解析成字典
        NSDictionary *dic = [NSDictionary dictionaryWithXMLString:responseString];
        //判断返回的许可
        if ([[dic objectForKey:@"result_code"] isEqualToString:@"SUCCESS"] &&[[dic objectForKey:@"return_code"] isEqualToString:@"SUCCESS"] ) {
            //发起微信支付，设置参数
            PayReq *request = [[PayReq alloc] init];
            request.openID = [dic objectForKey:@"appid"]; // 应用ID,好像可以不设置
            request.partnerId = [dic objectForKey:@"mch_id"]; // 商户号
            request.prepayId= [dic objectForKey:@"prepay_id"]; // 预支付交易会话ID 2个小时有效
            request.package = @"Sign=WXPay"; // 扩展字段(固定)
            request.nonceStr= [dic objectForKey:@"nonce_str"]; // 随机字符串，不长于32位
            //将当前事件转化成时间戳
            NSDate *datenow = [NSDate date];
            NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]]; // 秒级别, 毫秒级*1000即可
            UInt32 timeStamp =[timeSp intValue];
            request.timeStamp= timeStamp;  // 要求10位数, 秒级
            
            DataMD5 *md5 = [[DataMD5 alloc] init];
            // 开始签名加密 , 再次调用, 把以上信息排序, MD5, 给 sign 赋值
            request.sign=[md5 createMD5SingForPay:request.openID partnerid:request.partnerId prepayid:request.prepayId package:request.package noncestr:request.nonceStr timestamp:request.timeStamp];
            // 调用微信支付请求
            [WXApi sendReq:request];
            
            
            
        }else{
            NSLog(@"参数不正确，请检查参数");
         
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"网络请求失败%@",error);
    }];
    
   
}

#pragma mark - 产生随机订单号
- (NSString *)generateTradeNO
{
    static int kNumber = 15; // 限制订单号位数
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length]; // 取余肯定小于sourceStr的长度
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    NSLog(@"随机订单号:%@  IP地址:%@",[self generateTradeNO], [getIPhoneIP getIPAddress]);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//    用0调用时间函数time()，将其返回值强制转换为unsigned型，作为参数来调用srand( )函数。srand( )是为rand( )函数初始化随机发生器的启动状态，以产生伪随机数，所以常把srand( )称为种子函数。用time()返回的时间值做种子的原因是time()返回的是实时时间值搜索，每时毎刻都在变化，这样产生的伪随机数就有以假乱真的效果

// srand是产生随机数的种子，是的调用rand()函数时，每次产生的随机数不一样；也就是说，如果不加上srand，那么rand()函数产生的随机数是一样的

@end
