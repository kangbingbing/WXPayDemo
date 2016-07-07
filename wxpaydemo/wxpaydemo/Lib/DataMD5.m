//
//  DataMD5.m
//  wxpaydemo
//
//  Created by kangbing on 16/7/5.
//  Copyright © 2016年 kangbing. All rights reserved.
//

#import "DataMD5.h"
#import <CommonCrypto/CommonDigest.h>
@interface DataMD5()
@property (nonatomic,strong) NSString *appid;
@property (nonatomic,strong) NSString *mch_id;
@property (nonatomic,strong) NSString *nonce_str;
@property (nonatomic,strong) NSString *partnerkey;
@property (nonatomic,strong) NSString *body;
@property (nonatomic,strong) NSString *out_trade_no;
@property (nonatomic,strong) NSString *total_fee;
@property (nonatomic,strong) NSString *spbill_create_ip;
@property (nonatomic,strong) NSString *notify_url;
@property (nonatomic,strong) NSString *trade_type;
@end

@implementation DataMD5
// 初始化
-(instancetype)initWithAppid:(NSString *)appid_key
                      mch_id:(NSString *)mch_id_key
                   nonce_str:(NSString *)noce_str_key
                  partner_id:(NSString *)partner_id
                        body:(NSString *)body_key
               out_trade_no :(NSString *)out_trade_no_key
                   total_fee:(NSString *)total_fee_key
            spbill_create_ip:(NSString *)spbill_create_ip_key
                  notify_url:(NSString *)notify_url_key
                  trade_type:(NSString *)trade_type_key{
    self = [super init];
    if (self) {
        _appid = appid_key;
        _mch_id = mch_id_key;
        _nonce_str = noce_str_key;
        _partnerkey = partner_id;
        _body = body_key;
        _out_trade_no = out_trade_no_key;
        _total_fee = total_fee_key;
        _spbill_create_ip = spbill_create_ip_key;
        _notify_url = notify_url_key;
        _trade_type = trade_type_key;
        
    }
    return self;
}
///获取sign签名
- (NSString *)getSignForMD5{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:_appid forKey:@"appid"];
    [dic setValue:_mch_id forKey:@"mch_id"];
    [dic setValue:_nonce_str forKey:@"nonce_str"];
    [dic setValue:_body forKey:@"body"];
    [dic setValue:_out_trade_no forKey:@"out_trade_no"];
    [dic setValue:_total_fee forKey:@"total_fee"];
    [dic setValue:_spbill_create_ip forKey:@"spbill_create_ip"];
    [dic setValue:_notify_url forKey:@"notify_url"];
    [dic setValue:_trade_type forKey:@"trade_type"];
    return [self createMd5Sign:dic];
}

//创建签名
-(NSString*) createMd5Sign:(NSMutableDictionary*)dict
{
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [dict allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串,
    for (NSString *categoryId in sortedArray) {
        if (   ![[dict objectForKey:categoryId] isEqualToString:@""]
            && ![[dict objectForKey:categoryId] isEqualToString:@"sign"]
            && ![[dict objectForKey:categoryId] isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [dict objectForKey:categoryId]];
        }
    }
    //添加商户密钥key字段
    [contentString appendFormat:@"key=%@", _partnerkey];
    //得到MD5 sign签名
    NSString *md5Sign =[self md5:contentString];
    
    return md5Sign;
}

//创建发起支付时的sign签名
-(NSString *)createMD5SingForPay:(NSString *)appid_key partnerid:(NSString *)partnerid_key prepayid:(NSString *)prepayid_key package:(NSString *)package_key noncestr:(NSString *)noncestr_key timestamp:(UInt32)timestamp_key{
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    [signParams setObject:appid_key forKey:@"appid"];
    [signParams setObject:noncestr_key forKey:@"noncestr"];
    [signParams setObject:package_key forKey:@"package"];
    [signParams setObject:partnerid_key forKey:@"partnerid"];
    [signParams setObject:prepayid_key forKey:@"prepayid"];
    [signParams setObject:[NSString stringWithFormat:@"%u",timestamp_key] forKey:@"timestamp"];
    
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [signParams allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串   从字典里面查找对应的value, 如果不等于这几个就开始拼接 key=value&
    for (NSString *categoryId in sortedArray) {
        if (   ![[signParams objectForKey:categoryId] isEqualToString:@""]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"sign"]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [signParams objectForKey:categoryId]];
        }
    }
    //添加商户密钥key字段, 最后拼接上商户密钥, 然后 MD5
#warning 注意此处一定要添加上商户密钥
    [contentString appendFormat:@"key=%@", @"PwAsFHNp20QaoDZZ0t1cP6y6oYMC7x5d"];
    
    // 拼接完成之后, MD5一下
    NSString *result = [self md5:contentString];
    return result;
}

-(NSString *) md5:(NSString *)str
{   // 必须大写
    const char *cStr = [str UTF8String];
    
    unsigned char result[16]= "0123456789abcdef";
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    //  注意, MD5后大写
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
