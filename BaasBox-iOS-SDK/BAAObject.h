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
#import "BAAGlobals.h"

@interface BAAObject : NSObject

@property (nonatomic, copy, readonly) NSString *objectId;
@property (nonatomic, assign, readonly) NSInteger version;
@property (nonatomic, strong, readonly) NSDate *creationDate;

- (instancetype) initWithDictionary:(NSDictionary *)dictionary __attribute((objc_designated_initializer)); // Will be NS_DESIGNATED_INITIALIZER in Xcode6

+ (void) getObjectsWithCompletion:(BAAArrayResultBlock)completionBlock;
+ (void) getObjectsWithParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
+ (void) getObjectWithId:(NSString *)objectID completion:(BAAObjectResultBlock)completionBlock;
- (void) saveObjectWithCompletion:(BAAObjectResultBlock)completionBlock;
- (void) deleteObjectWithCompletion:(BAABooleanResultBlock)completionBlock;
- (void) grantAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) grantAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
+ (void) fetchCountForObjectsWithCompletion:(BAAIntegerResultBlock)completionBlock;
+ (NSString *) assetsEndPoint;
- (NSString *) collectionName;
- (NSDictionary*) objectAsDictionary;
- (NSString *) jsonString;

// Experimental
+ (void) getRandomObjectsWithParams:(NSDictionary *)parameters bound:(NSInteger)bound completion:(BAAArrayResultBlock)completionBlock;

@end
