/*
 * Copyright (C) 2014. BaasBox
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <AppKit/AppKit.h>
#endif

#define VERSION @"0.9.0"
#define BASE_URL_KEY @"baseURLKey"
#define APP_CODE_KEY @"appCodeKey"

@interface BaasBox : NSObject

+ (void) setBaseURL:(NSString *)URL appCode:(NSString *)code;
+ (NSString *) baseURL;
+ (NSString *) appCode;
+ (NSString *) errorDomain;
+ (NSInteger) errorCode;
+ (NSError *)authenticationErrorForResponse:(NSDictionary *)response;
+ (NSDateFormatter *)dateFormatter;

@end
