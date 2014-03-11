//
//  Baasbox.m
//
//  Created by Cesare Rocchi on 11/22/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "BaasBox.h"

@implementation BaasBox

+ (void) setBaseURL:(NSString *)URL appCode:(NSString *)code {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:URL forKey:BASE_URL_KEY];
    [userDefaults setObject:code forKey:APP_CODE_KEY];
    [userDefaults synchronize];
    
}

+ (NSString *) baseURL {

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return (NSString *) [userDefaults objectForKey:BASE_URL_KEY];
    
}

+ (NSString *) appCode {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return (NSString *) [userDefaults objectForKey:APP_CODE_KEY];
    
}

+ (NSString *) errorDomain {
    return @"com.baasbox.error";
}

+ (NSInteger) errorCode {
    return -13579;
}

@end
