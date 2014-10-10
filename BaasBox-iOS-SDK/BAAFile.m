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

#import "BAAFile.h"

@interface BAAFile  ()

@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, strong) NSURLSessionDataTask *downloadTask;
@property (nonatomic, strong) BAAClient *client;

@end

@implementation BAAFile

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    
    if (self) {
        
        _fileId = dictionary[@"id"];
        _author = dictionary[@"_author"];
        _contentType = dictionary[@"contentType"];
        _creationDate = dictionary[@"_creation_date"];
        _attachedData = dictionary[@"attachedData"];
        _metadataData = dictionary[@"metadata"];
        
    }
    
    return self;
    
}

-(instancetype)initWithData:(NSData *)data {
    
    self = [super init];
    
    if (self) {
        
        _data = data;
        
    }
    
    return self;
    
}

- (BAAClient *) client {
    
    if (_client == nil)
        _client = [BAAClient sharedClient];
    
    return _client;
    
}

- (NSMutableDictionary *) attachedData {
    if (_attachedData == nil)
        _attachedData = [NSMutableDictionary dictionary];
    
    return _attachedData;
    
}

+ (void) getFilesWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client loadFiles:[[self alloc] init]
           completion:completionBlock];
    
}

- (NSURL *) fileURL {
    
    if (self.fileId == nil)
        return nil;
    
    NSString *URLString = [NSString stringWithFormat:@"%@/file/%@", self.client.baseURL, self.fileId];
    return [NSURL URLWithString:URLString];
    
}

+ (void) loadFileWithId:(NSString *)fileId completion:(void(^)(NSData *data, NSError *error))completionBlock {
    
    if (fileId && completionBlock) {
        
        BAAFile *file = [[BAAFile alloc] init];
        file.fileId = fileId;
        [file loadFileWithCompletion:completionBlock];

    }
}

- (void) loadFileWithCompletion:(void(^)(NSData *data, NSError *error))completionBlock {
    
    self.downloadTask = [self.client loadFileData:self
                                       completion:^(NSData *data, NSError *error) {
                                           
                                           if (completionBlock) {
                                               completionBlock(data, error);
                                           }
                                           
                                       }];
    
}

- (void) loadFileWithParameters:(NSDictionary *)parameters completion:(void(^)(NSData *data, NSError *error))completionBlock {
    
    self.downloadTask = [self.client loadFileData:self
                                       parameters:parameters
                                       completion:^(NSData *data, NSError *error) {
                                           
                                           if (completionBlock) {
                                               completionBlock(data, error);
                                           }
                                           
                                       }];
    
}

- (void) stopFileLoading {
    
    [self.downloadTask suspend];
    
}

+ (void) loadFileDetails:(NSString *)fileId completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFileDetails:fileId
                 completion:^(id object, NSError *error) {
                     
                     if (completionBlock)
                         completionBlock(object, error);
                     
                 }];
    
}

+ (void) loadFilesAndDetailsWithCompletion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFilesAndDetailsWithCompletion:^(NSArray *files, NSError *error) {
                     
                     if (completionBlock)
                         completionBlock(files, error);
                     
                 }];
    
}

#pragma mark - ACL

- (void) grantAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock {
    
    [self.client grantAccess:self
                      toRole:roleName
                  accessType:accessType
                  completion:completionBlock];
    
}

- (void) grantAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock {
    
    [self.client grantAccess:self
                      toUser:username
                  accessType:accessType
                  completion:completionBlock];
    
}

- (void) revokeAccessToRole:(NSString *)roleName ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock {
    
    [self.client revokeAccess:self
                       toRole:roleName
                   accessType:accessType
                   completion:completionBlock];
    
}

- (void) revokeAccessToUser:(NSString *)username ofType:(NSString *)accessType completion:(BAAObjectResultBlock)completionBlock {
    
    [self.client revokeAccess:self
                       toUser:username
                   accessType:accessType
                   completion:completionBlock];
    
}

#pragma mark - Upload

- (void) uploadFileWithPermissions:(NSDictionary *)permissions completion:(BAAObjectResultBlock)completionBlock; {
    
    [self.client uploadFile:self
            withPermissions:permissions
                 completion:completionBlock];
    
    
}

#pragma mark - Delete

- (void) deleteFileWithCompletion:(BAABooleanResultBlock)completionBlock {
    
    [self.client deleteFile:self
                 completion:completionBlock];
    
}

+ (void)deleteFileWithId:(NSString *)fileId completion:(BAABooleanResultBlock)completionBlock {
    
    if (fileId && completionBlock) {
        
        BAAFile *file = [[BAAFile alloc] init];
        file.fileId = fileId;
        [file deleteFileWithCompletion:completionBlock];
        
    }
}

@end
