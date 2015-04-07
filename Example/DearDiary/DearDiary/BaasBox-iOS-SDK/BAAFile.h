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
#import "BAAClient.h"

@interface BAAFile : NSObject

@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic, copy) NSString *fileId;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSString *creationDate;
@property (nonatomic, strong) NSMutableDictionary *attachedData;
@property (nonatomic, strong) NSMutableDictionary *metadataData;

- (instancetype) initWithData:(NSData *)data;
- (instancetype) initWithDictionary:(NSDictionary *)dictionary;

+ (void) getFilesWithCompletion:(BAAArrayResultBlock)completionBlock;
- (NSURL *) fileURL;
+ (void) loadFileWithId:(NSString *)fileId completion:(void(^)(NSData *data, NSError *error))completionBlock;
- (void) loadFileWithCompletion:(void(^)(NSData *data, NSError *error))completionBlock;
- (void) loadFileWithParameters:(NSDictionary *)parameters completion:(void(^)(NSData *data, NSError *error))completionBlock;
+ (void) loadFileDetails:(NSString *)fileId completion:(BAAObjectResultBlock)completionBlock;
+ (void) loadFilesAndDetailsWithCompletion:(BAAArrayResultBlock)completionBlock;
- (void) stopFileLoading;
- (void) uploadFileWithPermissions:(NSDictionary *)permissions completion:(BAAObjectResultBlock)completionBlock;
- (void) grantAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) grantAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock;
- (void) deleteFileWithCompletion:(BAABooleanResultBlock)completionBlock;
+ (void) deleteFileWithId:(NSString *)fileId completion:(BAABooleanResultBlock)completionBlock;

@end
