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
