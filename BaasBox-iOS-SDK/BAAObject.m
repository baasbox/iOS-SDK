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

#import "BAAObject.h"
#import "BAAClient.h"
#import "BaasBox.h"
#import <objc/runtime.h>

@implementation BAAObject

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    
    if (self) {
    
        _objectId = dictionary[@"id"];
        
    }
    
    return self;
    
}

+ (void) getObjectsWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client loadCollection:[[self alloc] init]
                completion:completionBlock];
    
}

+ (void) getObjectsWithParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadCollection:[[self alloc] init]
                withParams:parameters
                completion:completionBlock];
    
}

+ (void) getObjectWithId:(NSString *)objectID completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    id c = [self class];
    id resultObject = [[c alloc] init];
    [resultObject setValue:objectID
                  forKey:@"objectId"];
    [client loadObject:resultObject
            completion:completionBlock];
    
}

- (void) saveObjectWithCompletion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    
    if (self.objectId == nil) {
    
        [client createObject:self
                  completion:completionBlock];
        
    } else {
    
        [client updateObject:self
                  completion:completionBlock];
        
    }
    
}

- (void) deleteObjectWithCompletion:(BAABooleanResultBlock)completionBlock; {

    BAAClient *client = [BAAClient sharedClient];
    
    [client deleteObject:self
              completion:completionBlock];
    
}

- (NSString *) collectionName {
    
    return @"OVERWRITE THIS METHOD";
    
}

- (NSDictionary*) objectAsDictionary {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    unsigned int outCount, i;
    
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for(i = 0; i < outCount; i++) {
        
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        
        if(propName) {
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            id value = [self valueForKey:propertyName];
            
            if ([value isKindOfClass:[NSArray class]]) {
                
                NSArray *array = (NSArray *)value;
                NSMutableArray *tmp = [NSMutableArray array];
                for (id object in array) {
                    
                    if ([object respondsToSelector:@selector(objectAsDictionary)]) {
                        
                        [tmp addObject:[object objectAsDictionary]];
                        
                    } else {
                        
                        [tmp addObject:object];
                        
                    }
                    
                }
                
                [dict setValue:tmp forKey:propertyName];
                
            }
            
            else if ([value respondsToSelector:@selector(objectAsDictionary)]) {
                
                [dict setValue:[value objectAsDictionary]
                        forKey:propertyName];
                
            }
            
            else if (value && (id)value != [NSNull null]) {
                
                [dict setValue:value forKey:propertyName];
                
            }
        }
    }
    
    free(properties);
    
    return dict;
    
}

- (NSString *)jsonString {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self objectAsDictionary]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    NSString *res = [[NSString alloc] initWithData:jsonData
                                          encoding:NSUTF8StringEncoding];
    
    return res;
    
}

+ (NSString *) assetsEndPoint {

    NSString *s = [BaasBox baseURL];
    return  [NSString stringWithFormat:@"%@%@", s, @"/asset/"];
    
}

-(NSString *)description {

    return [NSString stringWithFormat:@"<%@> - %@", NSStringFromClass([self class]),  self.objectId];
    
}

@end
