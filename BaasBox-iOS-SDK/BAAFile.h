//
//  BAAFile.h
//
//  Created by Cesare Rocchi on 12/11/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

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

@end
