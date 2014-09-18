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

+ (NSError *)authenticationErrorForResponse:(NSDictionary *)response {

    if (response == nil) {
        NSDictionary *errorDetail = @{NSLocalizedDescriptionKey:@"Server returned an empty response.",
                                      @"BaasBox API Version": @[response[@"API_version"]],
                                      @"iOS SDK Version" : VERSION};
        return [NSError errorWithDomain:[BaasBox errorDomain]
                                   code:-22222
                               userInfo:errorDetail];
    }

    NSDictionary *errorDetail = @{NSLocalizedDescriptionKey:response[@"message"],
                                  @"BaasBox_API_version": @[response[@"API_version"]],
                                  @"iOS SDK Version" : VERSION};
    NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                         code:-22222
                                     userInfo:errorDetail];
    return error;
    
}

+ (NSDateFormatter *)dateFormatter {
    
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
    });
    
    return _dateFormatter;
    
}

@end
