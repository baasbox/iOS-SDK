//
//  BAAObject.h
//
//  Created by Cesare Rocchi on 8/21/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAAGlobals.h"

@interface BAAObject : NSObject

@property (nonatomic, copy, readonly) NSString *objectId;

- (instancetype) initWithDictionary:(NSDictionary *)dictionary;

+ (void) getObjectsWithCompletion:(BAAArrayResultBlock)completionBlock;
+ (void) getObjectsWithParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
+ (void) getObjectWithId:(NSString *)objectID completion:(BAAObjectResultBlock)completionBlock;
- (void) saveObjectWithCompletion:(BAAObjectResultBlock)completionBlock;
- (void) deleteObjectWithCompletion:(BAABooleanResultBlock)completionBlock;
+ (NSString *) assetsEndPoint;
- (NSString *) collectionName;
- (NSDictionary*) objectAsDictionary;
- (NSString *) jsonString;

@end
