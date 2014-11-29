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

#import "BAAClient.h"
#import "BaasBox.h"
#import "BAAMutableURLRequest.h"

NSString * const kPageNumberKey = @"page";
NSString * const kPageSizeKey = @"recordsPerPage";
NSString * const kSkipKey = @"skip";
NSInteger const kPageLength = 50;

NSString * const kAclAnonymousRole = @"anonymous";
NSString * const kAclRegisteredRole = @"registered";
NSString * const kAclAdministratorRole = @"administrator";

NSString * const kAclReadPermission = @"read";
NSString * const kAclDeletePermission = @"delete";
NSString * const kAclUpdatePermission = @"update";
NSString * const kAclAllPermission = @"all";

NSString * const kPushNotificationMessageKey = @"message";
NSString * const kPushNotificationCustomPayloadKey = @"custom";

static NSString * const boundary = @"BAASBOX_BOUNDARY_STRING";

static NSString * const kBAACharactersToBeEscapedInQuery = @"@/:?&=$;+!#()',*";

static NSString * BAAPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kBAACharactersToLeaveUnescapedInQueryStringPairKey = @"[].";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kBAACharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kBAACharactersToBeEscapedInQuery, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * BAAPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kBAACharactersToBeEscapedInQuery, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark - URL Serialization borrowed from AFNetworking

@interface BAAQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation BAAQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return BAAPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", BAAPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), BAAPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end


extern NSArray * BAAQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * BAAQueryStringPairsFromKeyAndValue(NSString *key, id value);

static NSString * BAAQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (BAAQueryStringPair *pair in BAAQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * BAAQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return BAAQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * BAAQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:BAAQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:BAAQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in set) {
            [mutableQueryStringComponents addObjectsFromArray:BAAQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[BAAQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}


#pragma mark - Client

@interface BAAClient ()

@property (nonatomic, copy) NSString *appCode;
@property (nonatomic, strong) NSURLSession *session;

- (BAAUser *) loadUserFromDisk;
- (void)_initSession;

@end

NSString* const BAAUserKeyForUserDefaults = @"com.baaxbox.user";

@implementation BAAClient

+ (instancetype)sharedClient {
    
    static BAAClient *sharedBAAClient = nil;
    static dispatch_once_t onceBAAToken;
    dispatch_once(&onceBAAToken, ^{
        sharedBAAClient = [[BAAClient alloc] init];
    });
    
    return sharedBAAClient;
}

- (id) init {
    
    if (self = [super init]) {
        
        _baseURL = [NSURL URLWithString:[BaasBox baseURL]];
        _appCode = [BaasBox appCode];
        [self _initSession];
        
	}
    
    return self;
}

- (void) _initSession {
    
    self.currentUser = [self loadUserFromDisk];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSDictionary *headers = @{@"Accept": @"application/json",
                              @"User-Agent": [NSString stringWithFormat:@"BaasBox iOS SDK %@", VERSION]};
    sessionConfiguration.HTTPAdditionalHeaders = headers;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                             delegate:nil
                                        delegateQueue:[NSOperationQueue mainQueue]];
    
}

#pragma mark - Authentication

- (void)authenticateUser:(NSString *)username
                password:(NSString *)password
              completion:(BAABooleanResultBlock)completionHandler {
    
    [self postPath:@"login"
        parameters:@{@"username" : username, @"password": password, @"appcode" : self.appCode}
           success:^(NSDictionary *responseObject) {
               
               NSString *token = responseObject[@"data"][@"X-BB-SESSION"];
               
               if (token) {
                   
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   user.authenticationToken = token;
                   self.currentUser = user;
                   [self saveUserToDisk:user];
                   completionHandler(YES, nil);
                   
               } else {
                   
                   NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                   [errorDetail setValue:responseObject[@"message"]
                                  forKey:NSLocalizedDescriptionKey];
                   NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                        code:[BaasBox errorCode]
                                                    userInfo:errorDetail];
                   completionHandler(NO, error);
                   
               }
               
           } failure:^(NSError *error) {
               
               completionHandler(NO, error);
               
           }];
    
}

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                    completion:(BAABooleanResultBlock)completionHandler {
    
    [self createUserWithUsername:username
                        password:password
                visibleByTheUser:nil
                visibleByFriends:nil
        visibleByRegisteredUsers:nil
         visibleByAnonymousUsers:nil
                      completion:completionHandler];
    
}

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
              visibleByTheUser:(NSDictionary *)visibleByTheUser
              visibleByFriends:(NSDictionary *)visibleByFriends
      visibleByRegisteredUsers:(NSDictionary *)visibleByRegisteredUsers
       visibleByAnonymousUsers:(NSDictionary *)visibleByAnonymousUsers
                    completion:(BAABooleanResultBlock)completionHandler {
    
    [self postPath:@"user"
        parameters:@{
                     @"username" : username,
                     @"password": password,
                     @"appcode" : self.appCode,
                     @"visibleByTheUser" : visibleByTheUser ?: @{},
                     @"visibleByFriends" : visibleByFriends ?: @{},
                     @"visibleByRegisteredUsers" : visibleByRegisteredUsers ?: @{},
                     @"visibleByAnonymousUsers" : visibleByAnonymousUsers ?: @{}}
           success:^(NSDictionary *responseObject) {
               
               NSString *token = responseObject[@"data"][@"X-BB-SESSION"];
               
               if (token) {
                   
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   user.authenticationToken = token;
                   self.currentUser = user;
                   [self saveUserToDisk:user];
                   
                   completionHandler(YES, nil);
                   
               } else {
                   
                   NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                   [errorDetail setValue:responseObject[@"message"]
                                  forKey:NSLocalizedDescriptionKey];
                   NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                        code:[BaasBox errorCode]
                                                    userInfo:errorDetail];
                   completionHandler(NO, error);
                   
               }
               
           } failure:^(NSError *error) {
               
               completionHandler(NO, error);
               
           }];
    
}

- (void) logoutWithCompletion:(BAABooleanResultBlock)completionHandler {
    
    NSString *path = @"logout";
    
    if (self.currentUser.pushNotificationToken) {
        path = [NSString stringWithFormat:@"logout/%@", self.currentUser.pushNotificationToken];
    }
    
    [self postPath:path
        parameters:nil
           success:^(id responseObject) {
               
               if (completionHandler) {
                   self.currentUser = nil;
                   [self saveUserToDisk:self.currentUser];
                   completionHandler(YES, nil);
               }
               
           } failure:^(NSError *error) {
               
               if (completionHandler) {
                   completionHandler(NO, error);
               }
               
           }];
    
}

#pragma mark - Objects

- (void) loadObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock {
    
    [self getPath:[NSString stringWithFormat:@"%@/%@", object.collectionName, object.objectId]
       parameters:nil
          success:^(id responseObject) {
              
              NSDictionary *d = responseObject[@"data"];
              
              if (d) {
                  
                  id c = [object class];
                  id newObject = [[c alloc] initWithDictionary:d];
                  completionBlock(newObject, nil);
                  
              } else {
                  
                  NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                  [errorDetail setValue:responseObject[@"message"]
                                 forKey:NSLocalizedDescriptionKey];
                  NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                       code:[BaasBox errorCode]
                                                   userInfo:errorDetail];
                  completionBlock(nil, error);
                  
              }
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
          }];
    
}

- (void) loadCollection:(BAAObject *)object withParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {
    
    [self getPath:object.collectionName
       parameters:parameters
          success:^(id responseObject) {
              
              NSArray *objects = responseObject[@"data"];
              NSMutableArray *result = [NSMutableArray array];
              
              for (NSDictionary *d in objects) {
                  
                  id c = [object class];
                  id newObject = [[c alloc] initWithDictionary:d];
                  [result addObject:newObject];
                  
              }
              
              completionBlock(result, nil);
              
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
          }];
    
}


- (void) loadCollection:(BAAObject *)object completion:(BAAArrayResultBlock)completionBlock {
    
    [self loadCollection:object
              withParams:@{kPageNumberKey : @0,
                           kPageSizeKey : [NSNumber numberWithInteger:kPageLength]}
              completion:completionBlock];
    
}

- (void) createObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock {
    
    [self postPath:object.collectionName
        parameters:object.objectAsDictionary
           success:^(id responseObject) {
               
               NSDictionary *d = responseObject[@"data"];
               id c = [object class];
               id newObject = [[c alloc] initWithDictionary:d];
               completionBlock(newObject, nil);
               
           } failure:^(NSError *error) {
               
               completionBlock(nil, error);
               
           }];
    
}

- (void) updateObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock {
    
    [self putPath:[NSString stringWithFormat:@"%@/%@", object.collectionName, object.objectId]
       parameters:object.objectAsDictionary
          success:^(id responseObject) {
              
              NSDictionary *d = responseObject[@"data"];
              id c = [object class];
              id newObject = [[c alloc] initWithDictionary:d];
              completionBlock(newObject, nil);
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
              
          }];
    
}


- (void) deleteObject:(BAAObject *)object completion:(BAABooleanResultBlock)completionBlock {
    
    [self deletePath:[NSString stringWithFormat:@"%@/%@", object.collectionName, object.objectId]
          parameters:nil
             success:^(id responseObject) {
                 
                 //BOOL res = operation.response.statusCode == 200;
                 completionBlock(YES, nil);
                 
             } failure:^(NSError *error) {
                 
                 completionBlock(NO, error);
                 
                 
             }];
    
}

- (void) fetchCountForObjects:(BAAObject *)object completion:(BAAIntegerResultBlock)completionBlock {
    
    [self getPath:[NSString stringWithFormat:@"%@/count", object.collectionName]
       parameters:nil
          success:^(id responseObject) {
              
              NSInteger result = [responseObject[@"data"][@"count"] intValue];
              
              if (completionBlock) {
                  completionBlock(result, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(-1, error);
              }
              
          }];
    
}

#pragma Files

- (void) loadFiles:(BAAFile *)file completion:(BAAArrayResultBlock)completionBlock {
    
    [self loadFiles:file
         withParams:@{@"orderBy" :@"_creation_date%20desc"}
         completion:completionBlock];
    
}

- (void) loadFiles:(BAAFile *)file withParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {
    
    [self getPath:@"/file/details"
       parameters:parameters
          success:^(id responseObject) {
              
              NSArray *objects = responseObject[@"data"];
              NSMutableArray *result = [NSMutableArray array];
              
              for (NSDictionary *d in objects) {
                  
                  id c = [file class];
                  id newObject = [[c alloc] initWithDictionary:d];
                  [result addObject:newObject];
                  
              }
              
              completionBlock(result, nil);
              
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
          }];
    
}

- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file completion:(void(^)(NSData *data, NSError *error))completionBlock {
    
    return [self loadFileData:file parameters:nil completion:completionBlock];
    
}

- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file parameters:(NSDictionary *)parameters completion:(void(^)(NSData *data, NSError *error))completionBlock {
    
    NSURLSession *s = [NSURLSession sharedSession];
    NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
    BAAMutableURLRequest *request = [self requestWithMethod:@"GET" URLString:path parameters:parameters];
    NSURLSessionDataTask *task = [s dataTaskWithRequest:request
                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                          
                                          NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
                                          if (error == nil && r.statusCode == 200) {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  completionBlock(data, nil);
                                                  
                                              });
                                              
                                              
                                              
                                          } else {
                                              
                                              completionBlock(nil, error);
                                              
                                          }
                                          
                                      }];
    
    [task resume];
    return task;
    
}

- (void) uploadFile:(BAAFile *)file withPermissions:(NSDictionary *)permissions completion:(BAAObjectResultBlock)completionBlock {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.baseURL, @"file"]]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:self.appCode forHTTPHeaderField:@"X-BAASBOX-APPCODE"];
    [request setValue:self.currentUser.authenticationToken forHTTPHeaderField:@"X-BB-SESSION"];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    // image
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"photo\"; filename=\"%@\"\r\n", [[NSUUID UUID] UUIDString]]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", file.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:file.data];
    
    // attachedData
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *err;
    NSData *attachedData = [NSJSONSerialization dataWithJSONObject:file.attachedData options:0 error:&err];
    NSString* jsonString = [[NSString alloc] initWithBytes:[attachedData bytes] length:[attachedData length] encoding:NSUTF8StringEncoding];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"attachedData\"\r\n\r\n%@", jsonString] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // ACL
    if (permissions) {
        
        NSData *aclData = [NSJSONSerialization dataWithJSONObject:permissions options:0 error:&err];
        NSString *aclString = [[NSString alloc] initWithBytes:[aclData bytes] length:[aclData length] encoding:NSUTF8StringEncoding];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"acl\"\r\n\r\n%@", aclString] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
    }
    
    [request setHTTPBody:body];
    
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         if (completionBlock) {
                             
                             NSHTTPURLResponse *res = (NSHTTPURLResponse*)response;
                             NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:kNilOptions
                                                                                 error:nil];
                             
                             if (error == nil && res.statusCode <= 201) {
                                 
                                 id c = [file class];
                                 id newObject = [[c alloc] initWithDictionary:d[@"data"]];
                                 completionBlock(newObject, nil);
                                 
                             } else {
                                 
                                 NSDictionary *userInfo = @{
                                                            NSLocalizedDescriptionKey: d[@"message"],
                                                            NSLocalizedFailureReasonErrorKey: d[@"message"],
                                                            NSLocalizedRecoverySuggestionErrorKey: @"Make sure that ACL roles and usernames exist on the backend."
                                                            };
                                 NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                                      code:[BaasBox errorCode]
                                                                  userInfo:userInfo];
                                 
                                 completionBlock(nil, error);
                                 
                             }
                         }
                         
                     }] resume];
    
}

- (void) deleteFile:(BAAFile *)file completion:(BAABooleanResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
    [self deletePath:path
          parameters:nil
             success:^(id responseObject) {
                 
                 if (completionBlock) {
                     
                     NSString *res = responseObject[@"result"];
                     if ([res isEqualToString:@"ok"])
                         completionBlock(YES, nil);
                     
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock)
                     completionBlock(NO, error);
                 
             }];
    
}

- (void) loadFileDetails:(NSString *)fileID completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"file/details/%@", fileID];
    [self getPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  BAAFile *file = [[BAAFile alloc] initWithDictionary:responseObject[@"data"]];
                  completionBlock (file, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) loadFilesAndDetailsWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    
    [self getPath:@"file/details"
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              if (completionBlock) {
                  
                  NSArray *files = responseObject[@"data"];
                  NSMutableArray *resultArray = [NSMutableArray new];
                  
                  for (NSDictionary *fileDictionary in files) {
                      
                      BAAFile *file = [[BAAFile alloc] initWithDictionary:fileDictionary];
                      [resultArray addObject:file];
                      
                  }
                  
                  completionBlock(resultArray, nil);
                  
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
}

#pragma mark - Acl

- (void) grantAccess:(id)element toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [self buildPathForRoleACL:element forAccessType:access roleName:roleName];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  completionBlock(element, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) grantAccess:(id)element toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [self buildPathForUserACL:element forAccessType:access username:username];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  completionBlock(element, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) revokeAccess:(id)element toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [self buildPathForRoleACL:element forAccessType:access roleName:roleName];
    
    [self deletePath:path
          parameters:nil
             success:^(id responseObject) {
                 
                 if (completionBlock) {
                     completionBlock(element, nil);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(nil, error);
                 }
                 
             }];
    
}

- (void) revokeAccess:(id)element toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [self buildPathForUserACL:element forAccessType:access username:username];
    
    [self deletePath:path
          parameters:nil
             success:^(id responseObject) {
                 
                 if (completionBlock) {
                     completionBlock(element, nil);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(nil, error);
                 }
                 
             }];
    
}


// Both methods are ugly, but at the moment let's live with these
- (NSString *) buildPathForRoleACL:(id)element forAccessType:(NSString *)accessType roleName:(NSString *)role {

    NSString *path;
    
    if ([element isKindOfClass:[BAAFile class]]) {
    
        BAAFile *file = (BAAFile *)element;
        path = [NSString stringWithFormat:@"file/%@/%@/role/%@", file.fileId, accessType, role];
        
    } else {
    
        BAAObject *object = (BAAObject *)element;
        path = [NSString stringWithFormat:@"%@/%@/%@/role/%@", object.collectionName, object.objectId, accessType, role];
        
    }
    
    return path;
    
}

- (NSString *) buildPathForUserACL:(id)element forAccessType:(NSString *)accessType username:(NSString *)name {
    
    NSString *path;
    
    if ([element isKindOfClass:[BAAFile class]]) {
        
        BAAFile *file = (BAAFile *)element;
        path = [NSString stringWithFormat:@"file/%@/%@/user/%@", file.fileId, accessType, name];
        
    } else {
        
        BAAObject *object = (BAAObject *)element;
        path = [NSString stringWithFormat:@"%@/%@/%@/user/%@", object.collectionName, object.objectId, accessType, name];
        
    }
    
    return path;
    
}


#pragma mark - User methods

- (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock {
    
    [self getPath:@"me"
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              [self updateUserWithDictionary:responseObject];
              
              if (completionBlock) {
                  completionBlock(self.currentUser, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) updateUserWithCompletion:(BAAObjectResultBlock)completionBlock {
    
    [self putPath:@"user"
       parameters:@{@"visibleByAnonymousUsers" : self.currentUser.visibleByAnonymousUsers,
                    @"visibleByTheUser" : self.currentUser.visibleByTheUser,
                    @"visibleByFriends" : self.currentUser.visibleByFriends,
                    @"visibleByRegisteredUsers" : self.currentUser.visibleByRegisteredUsers}
          success:^(NSDictionary *responseObject) {
              
              [self updateUserWithDictionary:responseObject];
              
              if (completionBlock) {
                  completionBlock(self.currentUser, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) loadUsersDetails:(NSString *)userId completion:(BAAObjectResultBlock)completionBlock {
    
    [self getPath:[NSString stringWithFormat:@"user/%@", userId]
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                  completionBlock(user, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}


- (void) loadUsersWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    [self loadUsersWithParameters:@{kPageNumberKey : @0, kPageSizeKey : @20}
                       completion:completionBlock];
    
}

- (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {
    
    [self getPath:@"users"
       parameters:parameters
          success:^(id responseObject) {
              
              NSArray *objects = responseObject[@"data"];
              NSMutableArray *users = [NSMutableArray array];
              
              for (NSDictionary *d in objects) {
                  
                  BAAUser *u = [[BAAUser alloc] initWithDictionary:d];
                  [users addObject:u];
                  
              }
              
              if (completionBlock) {
                  completionBlock(users, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) loadFollowingForUser:(BAAUser *)user completion:(BAAArrayResultBlock)completionBlock {
    
    [self getPath:[NSString stringWithFormat:@"following/%@", user.username]
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  NSArray *users = responseObject[@"data"];
                  NSMutableArray *resultArray = [NSMutableArray array];
                  
                  for (NSDictionary *d in users) {
                      
                      BAAUser *user = [[BAAUser alloc] initWithDictionary:d];
                      [resultArray addObject:user];
                      
                  }
                  
                  completionBlock(resultArray, nil);
                  
              }
              
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) loadFollowersOfUser:(BAAUser *)user completion:(BAAArrayResultBlock)completionBlock {
    
    [self getPath:[NSString stringWithFormat:@"followers/%@", user.username]
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  NSArray *users = responseObject[@"data"];
                  NSMutableArray *resultArray = [NSMutableArray array];
                  
                  for (NSDictionary *d in users) {
                      
                      BAAUser *user = [[BAAUser alloc] initWithDictionary:d];
                      [resultArray addObject:user];
                      
                  }
                  
                  completionBlock(resultArray, nil);
                  
              }
              
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completionBlock {
    
    [self postPath:[NSString stringWithFormat:@"follow/%@", user.username]
        parameters:nil
           success:^(id responseObject) {
               
               if (completionBlock) {
                   
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   
                   if (user) {
                       
                       completionBlock(user, nil);
                       
                   }
                   
               }
               
               
           } failure:^(NSError *error) {
               
               if (completionBlock) {
                   completionBlock(nil, error);
               }
               
           }];
    
}

- (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completionBlock {
    
    [self deletePath:[NSString stringWithFormat:@"follow/%@", user.username]
          parameters:nil
             success:^(id responseObject) {
                 
                 if (completionBlock) {
                     NSString *res = responseObject[@"result"];
                     if ([res isEqualToString:@"ok"]) {
                         completionBlock(YES, nil);
                     }
                 }
                 
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(NO, error);
                 }
                 
             }];
    
}

- (void) changeOldPassword:(NSString *)oldPassword
             toNewPassword:(NSString *)newPassword
                completion:(BAABooleanResultBlock)completionBlock {
    
    [self putPath:@"me/password"
       parameters:@{@"old": oldPassword, @"new": newPassword}
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  NSString *res = responseObject[@"result"];
                  
                  if ([res isEqualToString:@"ok"]) {
                      
                      completionBlock(YES, nil);
                      
                  } else {
                      
                      NSDictionary *userInfo = @{
                                                 NSLocalizedDescriptionKey: responseObject[@"message"],
                                                 NSLocalizedFailureReasonErrorKey: responseObject[@"message"],
                                                 NSLocalizedRecoverySuggestionErrorKey: responseObject[@"message"]
                                                 };
                      NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                           code:[BaasBox errorCode]
                                                       userInfo:userInfo];
                      completionBlock(NO, error);
                      
                  }
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(NO, error);
              }
              
          }];
    
}

- (void) resetPasswordForUser:(BAAUser *)user withCompletion:(BAABooleanResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"user/%@/password/reset", user.username];
    [self getPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  NSString *res = responseObject[@"result"];
                  
                  if ([res isEqualToString:@"ok"]) {
                      
                      completionBlock(YES, nil);
                      
                  } else {
                      
                      NSDictionary *userInfo = @{
                                                 NSLocalizedDescriptionKey: responseObject[@"message"],
                                                 NSLocalizedFailureReasonErrorKey: responseObject[@"message"],
                                                 NSLocalizedRecoverySuggestionErrorKey: responseObject[@"message"]
                                                 };
                      NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                           code:[BaasBox errorCode]
                                                       userInfo:userInfo];
                      completionBlock(NO, error);
                      
                  }
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(NO, error);
              }
              
          }];
    
}

#pragma mark - Push notifications

- (void) askToEnablePushNotifications {
    
#if !(TARGET_IPHONE_SIMULATOR)
    
    #if TARGET_OS_IPHONE
    
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
    
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
            (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
        #else
    
            UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |UIUserNotificationTypeBadge |  UIUserNotificationTypeSound
                                      categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
    
        #endif
    
    #else
    
        [[NSApplication sharedApplication] registerForRemoteNotificationTypes:
        (NSRemoteNotificationTypeBadge | NSRemoteNotificationTypeSound | NSRemoteNotificationTypeAlert)];
    
    #endif

#endif

}

- (void) enablePushNotifications:(NSData *)tokenData completion:(BAABooleanResultBlock)completionBlock {
    
    if (self.currentUser.pushEnabled) {
        if (completionBlock) {
            completionBlock(YES, nil);
            return;
        }
    }
    
    self.currentUser.pushNotificationToken = [self convertTokenToDeviceID:tokenData];
    
    NSString *path = [NSString stringWithFormat:@"push/enable/%@/%@", @"ios", self.currentUser.pushNotificationToken];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  if (responseObject) {
                      
                      self.currentUser.pushEnabled = YES;
                      completionBlock(YES, nil);
                      
                  } else {
                      
                      NSMutableDictionary* details = [NSMutableDictionary dictionary];
                      details[@"NSLocalizedDescriptionKey"] = [NSString stringWithFormat:@"Server returned %@", responseObject];
                      NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                           code:[BaasBox errorCode]
                                                       userInfo:details];
                      completionBlock(NO, error);
                      
                  }
                  
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(NO, error);
              }
              
          }];
    
}

- (void) disablePushNotificationsWithCompletion:(BAABooleanResultBlock)completionBlock {
    
    if (!self.currentUser.pushEnabled) {
        
        if (completionBlock) {
            
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            details[@"NSLocalizedDescriptionKey"] = @"Push notifications already disabled";
            NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                 code:[BaasBox errorCode]
                                             userInfo:details];
            completionBlock(NO, error);
            
        }
        
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"push/disable/%@", self.currentUser.pushNotificationToken];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionBlock) {
                  
                  if (responseObject) {
                      
                      self.currentUser.pushEnabled = YES;
                      completionBlock(YES, nil);
                      
                  } else {
                      
                      NSMutableDictionary* details = [NSMutableDictionary dictionary];
                      details[@"NSLocalizedDescriptionKey"] = [NSString stringWithFormat:@"Server returned %@", responseObject];
                      NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                           code:[BaasBox errorCode]
                                                       userInfo:details];
                      completionBlock(NO, error);
                      
                  }
                  
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(NO, error);
              }
              
          }];
    
}

- (NSString *)convertTokenToDeviceID:(NSData *)token {
    
    NSMutableString *deviceID = [NSMutableString string];
    
    unsigned char *ptr = (unsigned char *)[token bytes];
    
    for (NSInteger i=0; i < 32; ++i) {
        [deviceID appendString:[NSString stringWithFormat:@"%02x", ptr[i]]];
    }
    
    return deviceID;
}

- (void)pushNotificationToUsername:(NSString *)username
                       withMessage:(NSString *)message
                        completion:(BAABooleanResultBlock)completionBlock {
    
    [self pushNotificationToUsername:username
                         withMessage:message
                       customPayload:nil
                          completion:completionBlock];
}

- (void)pushNotificationToUsername:(NSString *)username
                       withMessage:(NSString *)message
                     customPayload:(NSDictionary *)customPayload
                        completion:(BAABooleanResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"/push/message/%@", username];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:message forKey:kPushNotificationMessageKey];
    
    if (customPayload) {
        [parameters setObject:customPayload forKey:kPushNotificationCustomPayloadKey];
    }
    
    BAAClient *client = [BAAClient sharedClient];
    [client postPath:path
          parameters:parameters
             success:^(id responseObject) {
                 
                 if (completionBlock) {
                     completionBlock(YES, nil);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(NO, error);
                 }
                 
             }];
}

#pragma mark - Admin

- (void) createCollection:(NSString *)collectionName completion:(BAAObjectResultBlock)completionBlock {
    
    [self postPath:[NSString stringWithFormat:@"admin/collection/%@", collectionName]
        parameters:nil
           success:^(id responseObject) {
               
               if (completionBlock) {
                   
                   completionBlock(responseObject, nil);
                   
               }
               
           } failure:^(NSError *error) {
               
               if (completionBlock) {
                   
                   completionBlock(nil, error);
                   
               }
               
           }];
    
}

- (void) loadSettingsWithCompletion:(BAAObjectResultBlock)completionBlock {
    
    [self getPath:@"admin/configuration/dump.json"
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              if (completionBlock) {
                  completionBlock(responseObject, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) loadSettingsSection:(NSString *)sectionName completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"admin/configuration/%@", sectionName];
    [self getPath:path
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              if (completionBlock) {
                  completionBlock(responseObject, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

- (void) setValue:(NSString *)value forKey:(NSString *)key inSection:(NSString *)sectionName completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"admin/configuration/%@/%@/%@", sectionName, key, value];
    [self putPath:path
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              if (completionBlock) {
                  completionBlock(responseObject, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionBlock) {
                  completionBlock(nil, error);
              }
              
          }];
    
}

#pragma mark - URL Serialization

- (BAAMutableURLRequest *)requestWithMethod:(NSString *)method
                                  URLString:(NSString *)path
                                 parameters:(NSDictionary *)parameters {
    
    NSString *u = [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
    NSURL *url = [NSURL URLWithString:u];
    BAAMutableURLRequest *request = [[BAAMutableURLRequest alloc] initWithURL:url];
    
    if ([path isEqualToString:@"login"]) { // Hack. Login should support json
        
        request.contentType = BAAContentTypeForm;
        
    }
    
    [request setHTTPMethod:method];
    [request setValue:self.appCode
   forHTTPHeaderField:@"X-BAASBOX-APPCODE"];
    [request setValue:self.currentUser.authenticationToken
   forHTTPHeaderField:@"X-BB-SESSION"];
    
    request = [[self requestBySerializingRequest:request withParameters:parameters error:nil] mutableCopy];
    
	return request;
}

- (BAAMutableURLRequest *)requestBySerializingRequest:(BAAMutableURLRequest *)mutableRequest
                                       withParameters:(id)parameters
                                                error:(NSError *__autoreleasing *)error {
    
    if (!parameters) {
        return mutableRequest;
    }
    
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    NSString *query = BAAQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
    
    if (mutableRequest.contentType == BAAContentTypeForm) {
        
        [mutableRequest setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
        [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]
              forHTTPHeaderField:@"Content-Type"];
        
    } else {
        
        [mutableRequest setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset]
              forHTTPHeaderField:@"Content-Type"];
        if ([mutableRequest.HTTPMethod isEqualToString:@"POST"] || [mutableRequest.HTTPMethod isEqualToString:@"PUT"]) {
            [mutableRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:error]];
        }
        if ([mutableRequest.HTTPMethod isEqualToString:@"GET"]) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
        }
        
    }
    
    return mutableRequest;
}

#pragma mark - Client methods

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id responseObject))success
        failure:(void (^)(NSError *error))failure {
    
	BAAMutableURLRequest *request = [self requestWithMethod:@"GET" URLString:path parameters:parameters];
    
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:kNilOptions
                                                                                      error:nil];
                         
                         if (httpResponse.statusCode >= 400) {
                             
                             NSError *error = [BaasBox authenticationErrorForResponse:jsonObject];                            
                             failure(error);
                             return;
                             
                         }
                         
                         if (error == nil) {
                             
                             NSString *contentType = [httpResponse.allHeaderFields objectForKey:@"Content-type"];
                             if ([contentType hasPrefix:@"image/"]) {
                                 
                                 success(data);
                                 
                             } else {
                             
                                 success(jsonObject);
                                 
                             }
                             
                         } else {
                         
                             failure(error);
                     
                         }
      
      }] resume];
    
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(id responseObject))success
         failure:(void (^)(NSError *error))failure {
    
	BAAMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                  URLString:path
                                                 parameters:parameters];
    
	[[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
                         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:kNilOptions
                                                                                      error:nil];
                         
                         if (r.statusCode >= 400) {
                             
                             NSError *error = [BaasBox authenticationErrorForResponse:jsonObject];
                             failure(error);
                             return;
                             
                         }
                         
                         if (error == nil) {

                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id responseObject))success
        failure:(void (^)(NSError *error))failure {
    
    BAAMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                  URLString:path
                                                 parameters:parameters];
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
                         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:kNilOptions
                                                                                      error:nil];
                         
                         if (r.statusCode >= 400) {
                             
                             NSError *error = [BaasBox authenticationErrorForResponse:jsonObject];
                             failure(error);
                             return;
                             
                         }
                         
                         if (error == nil) {

                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(id responseObject))success
           failure:(void (^)(NSError *error))failure {
    
    BAAMutableURLRequest *request = [self requestWithMethod:@"DELETE"
                                                  URLString:path
                                                 parameters:parameters];
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
                         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:kNilOptions
                                                                                      error:nil];
                         
                         if (r.statusCode >= 400) {
                             
                             NSError *error = [BaasBox authenticationErrorForResponse:jsonObject];
                             failure(error);
                             return;
                             
                         }
                         
                         if (error == nil) {

                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}


#pragma mark - Helpers

- (void) saveUserToDisk:(BAAUser *)user {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:user];
    [defaults setValue:encodedUser forKey:BAAUserKeyForUserDefaults];
    [defaults synchronize];
    
}

- (BAAUser *) loadUserFromDisk {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *decodedUser = [defaults objectForKey:BAAUserKeyForUserDefaults];

    if (decodedUser) {

      BAAUser *user = (BAAUser *)[NSKeyedUnarchiver unarchiveObjectWithData:decodedUser];
      return user;

    } else {

      return nil;
      
    }
    
    
}

- (void) updateUserWithDictionary:(NSDictionary *)dictionary {
    
    NSDictionary *dataDictionary = dictionary[@"data"];
    self.currentUser.roles = dataDictionary[@"user"][@"roles"];
    self.currentUser.status = dataDictionary[@"user"][@"status"];
    
    self.currentUser.visibleByAnonymousUsers = [NSMutableDictionary dictionaryWithDictionary:dataDictionary[@"visibleByAnonymousUsers"]];
    self.currentUser.visibleByRegisteredUsers = [NSMutableDictionary dictionaryWithDictionary:dataDictionary[@"visibleByRegisteredUsers"]];
    
    if (dictionary[@"visibleByFriends"] == [NSNull null]) {
        
        self.currentUser.visibleByFriends = [NSMutableDictionary dictionary];
        
    } else {
        
        self.currentUser.visibleByFriends = [NSMutableDictionary dictionaryWithDictionary:dataDictionary[@"visibleByFriends"]];
        
    }
    
    if (dictionary[@"visibleByTheUser"] == [NSNull null]) {
        
        self.currentUser.visibleByTheUser = [NSMutableDictionary dictionary];
        
    } else {
        
        self.currentUser.visibleByTheUser = [NSMutableDictionary dictionaryWithDictionary:dataDictionary[@"visibleByTheUser"]];
        
    }

    [self saveUserToDisk:self.currentUser];
    
}

- (BOOL) isAuthenticated {
    
    return self.currentUser.authenticationToken != nil;
    
}

@end
