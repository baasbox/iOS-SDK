//
//  BAAObject.m
//
//  Created by Cesare Rocchi on 8/21/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

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

-(NSDictionary*) objectAsDictionary {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    unsigned int outCount, i;
    
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSValue *value = [self valueForKey:propertyName];
            
            if ([value isKindOfClass:[NSArray class]]) { // TODO: review this
                
                NSArray *a = (NSArray *)value;
                NSMutableArray *tmp = [NSMutableArray array];
                for (BAAObject *b in a) {
                
                    [tmp addObject:[b objectAsDictionary]];
                    
                }
                
                [dict setValue:tmp forKey:propertyName];
                
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
