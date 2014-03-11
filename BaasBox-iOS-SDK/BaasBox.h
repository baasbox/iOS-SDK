//
//  Baasbox.h
//
//  Created by Cesare Rocchi on 11/22/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BASE_URL_KEY @"baseURLKey"
#define APP_CODE_KEY @"appCodeKey"

@interface BaasBox : NSObject

+ (void) setBaseURL:(NSString *)URL appCode:(NSString *)code;
+ (NSString *) baseURL;
+ (NSString *) appCode;
+ (NSString *) errorDomain;
+ (NSInteger) errorCode;

@end
