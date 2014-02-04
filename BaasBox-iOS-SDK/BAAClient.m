//
//  BAAClient.m
//
//  Created by Cesare Rocchi on 8/14/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#define VERSION @"0.7.3"

#import "BAAClient.h"
#import "BaasBox.h"
#import "BAAMutableURLRequest.h"

NSString * const kAclAnonymousRole = @"anonymous";
NSString * const kAclRegisteredRole = @"registered";
NSString * const kAclAdministratorRole = @"administrator";
NSString * const kAclReadPermission = @"read";
NSString * const kAclDeletePermission = @"delete";
NSString * const kAclUpdatePermission = @"update";

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

static NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
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

- (void) saveUserToDisk:(BAAUser *)user;
- (BAAUser *) loadUserFromDisk;
- (void)_initSession;

@end

NSString* const BAAUserKeyForUserDefaults = @"com.baaxbox.user";
NSInteger const BAAPageLength = 50;

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
              completion:(BAABooleanResultBlock)completionHander {
    
    [self postPath:@"login"
        parameters:@{@"username" : username, @"password": password, @"appcode" : self.appCode}
           success:^(NSDictionary *responseObject) {
               
               NSString *token = responseObject[@"data"][@"X-BB-SESSION"];
               
               if (token) {
                   
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   user.authenticationToken = token;
                   self.currentUser = user;
                   [self saveUserToDisk:user];
                   
                   completionHander(YES, nil);
                   
               } else {
                   
                   NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                   [errorDetail setValue:responseObject[@"message"]
                                  forKey:NSLocalizedDescriptionKey];
                   NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                        code:100
                                                    userInfo:errorDetail];
                   completionHander(NO, error);
                   
               }
               
           } failure:^(NSError *error) {
               
               completionHander(NO, error);
               
           }];
    
}

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                    completion:(BAABooleanResultBlock)completionHander {
    
    [self postPath:@"user"
        parameters:@{@"username" : username, @"password": password, @"appcode" : self.appCode}
           success:^(NSDictionary *responseObject) {
               
               NSString *token = responseObject[@"data"][@"X-BB-SESSION"];
               
               if (token) {
                   
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   user.authenticationToken = token;
                   self.currentUser = user;
                   [self saveUserToDisk:user];
                   
                   completionHander(YES, nil);
                   
               } else {
                   
                   NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                   [errorDetail setValue:responseObject[@"message"]
                                  forKey:NSLocalizedDescriptionKey];
                   NSError *error = [NSError errorWithDomain:[BaasBox errorDomain]
                                                        code:100
                                                    userInfo:errorDetail];
                   completionHander(NO, error);
                   
               }
               
           } failure:^(NSError *error) {
               
               completionHander(NO, error);
               
           }];
    
}

- (void) logoutWithCompletion:(BAABooleanResultBlock)completionHander {

    NSString *path = @"logout";
    
    if (self.currentUser.pushNotificationToken) {
        path = [NSString stringWithFormat:@"logout/%@", self.currentUser.pushNotificationToken];
    }
    
    [self postPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (completionHander) {
                  self.currentUser = nil;
                  [self saveUserToDisk:self.currentUser];
                  completionHander(YES, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completionHander)
                  completionHander(NO, error);
              
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
                                                       code:100
                                                   userInfo:errorDetail];
                  completionBlock(NO, error);
                  
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
              withParams:@{kPageNumber : @0,
                           kPageSize : [NSNumber numberWithInteger:BAAPageLength]}
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
    NSLog(@"request %@", request);
//    [request setValue:@"image/jpeg"
//          forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask *task = [s dataTaskWithRequest:request
                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                          
                                          NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
                                          if (error == nil && r.statusCode == 200) {
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                                  completionBlock(data, nil);
                                                  
                                              });
                                              
                                              
                                              
                                          } else {
                                              
                                              NSLog(@"Got response %@ with error %@.\n", response, error);
                                              completionBlock(nil, error);
                                              
                                          }
                                          
                                      }];
    
    [task resume];
    return task;
    
}

- (void) uploadFile:(BAAFile *)file completion:(BAAObjectResultBlock)completionBlock {
    
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
    
//    // ACL // TODO: finish this
//    NSDictionary *acl =  @{@"read" : @{@"users" : @[], @"roles" : @[kAclRegisteredRole]},
//                           @"update" : @{@"users" : @[], @"roles" : @[]},
//                           @"delete" : @{@"users" : @[], @"roles" : @[]}
//                           };
//    NSData *aclData = [NSJSONSerialization dataWithJSONObject:acl options:0 error:&err];
//    NSString *aclString = [[NSString alloc] initWithBytes:[aclData bytes] length:[aclData length] encoding:NSUTF8StringEncoding];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"acl\"\r\n\r\n%@", aclString] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         if (completionBlock) {
                             
                             NSHTTPURLResponse *res = (NSHTTPURLResponse*)response;
                             
                             if (error == nil && res.statusCode <= 201) {
                                 
                                 NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data
                                                                                   options:kNilOptions
                                                                                     error:nil];
                                 id c = [file class];
                                 id newObject = [[c alloc] initWithDictionary:d[@"data"]];
                                 completionBlock(newObject, nil);
                                 
                             } else {
                                 
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
              
              completionBlock(nil, error);
              
          }];
    
}

#pragma mark - Acl

- (void) grantAccess:(BAAFile *)file toRole:(NSString *)roleName completion:(BAAObjectResultBlock)completionBlock {
    
    NSString *path = [NSString stringWithFormat:@"file/%@/read/role/%@", file.fileId, roleName];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              completionBlock(file, nil);
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
          }];
    
}

- (void) grantAccess:(BAAFile *)file toUser:(NSString *)username completion:(BAAObjectResultBlock)completionBlock {

    NSString *path = [NSString stringWithFormat:@"file/%@/read/user/%@", file.fileId, username];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              completionBlock(file, nil);
              
          } failure:^(NSError *error) {
              
              completionBlock(nil, error);
              
          }];
    
}


#pragma mark - User methods

- (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completion {

    [self getPath:@"me"
       parameters:nil
          success:^(NSDictionary *responseObject) {
              
              [self updateUserWithDictionary:responseObject];
              
              if (completion)
                  completion(self.currentUser, nil);
              
          } failure:^(NSError *error) {
              
              if (completion)
                  completion(nil, error);
              
          }];
    
}

- (void) updateUserWithCompletion:(BAAObjectResultBlock)completion {

    [self putPath:@"user"
       parameters:@{@"visibleByAnonymousUsers" : self.currentUser.visibleByAnonymousUsers,
                    @"visibleByTheUser" : self.currentUser.visibleByTheUser,
                    @"visibleByFriends" : self.currentUser.visibleByFriends,
                    @"visibleByRegisteredUsers" : self.currentUser.visibleByRegisteredUsers}
          success:^(NSDictionary *responseObject) {
              
              [self updateUserWithDictionary:responseObject];
              
              if (completion)
                  completion(self.currentUser, nil);
              
          } failure:^(NSError *error) {
              
              if (completion)
                  completion(nil, error);
              
          }];
    
}

- (void) loadUsersDetails:(NSString *)userId completion:(BAAObjectResultBlock)completion {

    [self getPath:[NSString stringWithFormat:@"user/%@", userId]
       parameters:nil
          success:^(id responseObject) {
              
              if (completion) {
                  BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                  completion(user, nil);
              }
              
          } failure:^(NSError *error) {
              
              if (completion)
                  completion(nil, error);
              
          }];
    
}


- (void) loadUsersWithCompletion:(BAAArrayResultBlock)completion {

    [self loadUsersWithParameters:@{kPageNumber : @0, kPageSize : @20}
                       completion:completion];
    
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
              
              if (completionBlock)
                  completionBlock(users, nil);
              
          } failure:^(NSError *error) {
              
              if (completionBlock)
                  completionBlock(nil, error);
              
          }];
    
}

- (void) loadFollowingForUser:(BAAUser *)user completion:(BAAArrayResultBlock)completion {
    
    [self getPath:[NSString stringWithFormat:@"following/%@", user.username]
       parameters:nil
          success:^(id responseObject) {

              if (completion) {

                  NSArray *users = responseObject[@"data"];
                  NSMutableArray *resultArray = [NSMutableArray array];
                  
                  for (NSDictionary *d in users) {
                      
                      BAAUser *user = [[BAAUser alloc] initWithDictionary:d];
                      [resultArray addObject:user];
                      
                  }
              
                  completion(resultArray, nil);
                  
              }
              
              
          } failure:^(NSError *error) {
              
              if (completion)
                  completion(nil, error);
              
          }];
    
}

- (void) loadFollowersOfUser:(BAAUser *)user completion:(BAAArrayResultBlock)completion {

    [self getPath:[NSString stringWithFormat:@"followers/%@", user.username]
       parameters:nil
          success:^(id responseObject) {
              
              if (completion) {
                  
                  NSArray *users = responseObject[@"data"];
                  NSMutableArray *resultArray = [NSMutableArray array];
                  
                  for (NSDictionary *d in users) {
                      
                      BAAUser *user = [[BAAUser alloc] initWithDictionary:d];
                      [resultArray addObject:user];
                      
                  }
                  
                  completion(resultArray, nil);
                  
              }
              
              
          } failure:^(NSError *error) {
              
              if (completion)
                  completion(nil, error);
              
          }];
    
}

- (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completion {

    [self postPath:[NSString stringWithFormat:@"follow/%@", user.username]
        parameters:nil
           success:^(id responseObject) {

               if (completion) {
                   BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                   if (user)
                       completion(user, nil);
                   
               }
               
               
           } failure:^(NSError *error) {
               
               if (completion)
                   completion(NO, error);
               
           }];
    
}

- (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completion {
    
    [self deletePath:[NSString stringWithFormat:@"follow/%@", user.username]
          parameters:nil
             success:^(id responseObject) {
                 
                 if (completion) {
                     NSString *res = responseObject[@"result"];
                     if ([res isEqualToString:@"ok"])
                         completion(YES, nil);
                 }
                 
                 
             } failure:^(NSError *error) {
                 
                 if (completion)
                     completion(NO, error);
                 
             }];

}

#pragma mark - Client methods


- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id responseObject))success
        failure:(void (^)(NSError *error))failure {
    
	BAAMutableURLRequest *request = [self requestWithMethod:@"GET" URLString:path parameters:parameters];
    
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         if (error == nil) {
                             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:kNilOptions
                                                                                          error:nil];
                             success(jsonObject);
                             
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
                         
                         if (error == nil) {
                             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:kNilOptions
                                                                                          error:nil];
                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}

-(void)putPath:(NSString *)path
    parameters:(NSDictionary *)parameters
       success:(void (^)(id responseObject))success
       failure:(void (^)(NSError *error))failure {
    
    BAAMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                  URLString:path
                                                 parameters:parameters];
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         if (error == nil) {
                             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:kNilOptions
                                                                                          error:nil];
                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}

-(void)deletePath:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure {
    
    BAAMutableURLRequest *request = [self requestWithMethod:@"DELETE"
                                                  URLString:path
                                                 parameters:parameters];
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                         
                         if (error == nil) {
                             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:kNilOptions
                                                                                          error:nil];
                             success(jsonObject);
                             
                         } else {
                             
                             failure(error);
                             
                         }
                         
                     }] resume];
    
}



#pragma mark - Push notifications

- (void) askToEnablePushNotifications {
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
}

- (void) enablePushNotification:(NSData *)tokenData completion:(BAABooleanResultBlock)completion {
    
    if (self.currentUser.pushEnabled) {
        completion(YES, nil);
        return;
    }
    
    self.currentUser.pushNotificationToken = [self convertTokenToDeviceID:tokenData];
    
    NSString *path = [NSString stringWithFormat:@"push/device/%@/%@", @"ios", self.currentUser.pushNotificationToken];
    
    [self putPath:path
       parameters:nil
          success:^(id responseObject) {
              
              if (responseObject) {
                  
                  self.currentUser.pushEnabled = YES;
                  completion(YES, nil);
                  
              } else {
                  
                  NSMutableDictionary* details = [NSMutableDictionary dictionary];
                  details[@"NSLocalizedDescriptionKey"] = [NSString stringWithFormat:@"Server returned %@", responseObject];
                  NSError *error = [NSError errorWithDomain:@"baasbox"
                                                       code:200
                                                   userInfo:details];
                  completion(NO, error);
                  
              }
              
          } failure:^(NSError *error) {
              
              NSLog(@"error %@", error);
              completion(NO, error);
              
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


#pragma mark - URL Serialization

- (BAAMutableURLRequest *)requestWithMethod:(NSString *)method
                                  URLString:(NSString *)path
                                 parameters:(NSDictionary *)parameters {
    
    NSString *u = [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
    NSURL *url = [NSURL URLWithString:u];
    BAAMutableURLRequest *request = [[BAAMutableURLRequest alloc] initWithURL:url];
    
    if ([path isEqualToString:@"login"]) // Hack. Login should support json
        request.contentType = BAAContentTypeForm;
    
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
    NSString *query = AFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
    
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
    BAAUser *user = (BAAUser *)[NSKeyedUnarchiver unarchiveObjectWithData:decodedUser];
    return user;
    
}

- (void) updateUserWithDictionary:(NSDictionary *) dictionary {
    
    self.currentUser.roles = dictionary[@"data"][@"user"][@"roles"];
    self.currentUser.visibleByTheUser = dictionary[@"data"][@"visibleByTheUser"];
    self.currentUser.visibleByFriends = dictionary[@"data"][@"visibleByFriends"];
    self.currentUser.visibleByRegisteredUsers = dictionary[@"data"][@"visibleByRegisteredUsers"];
    self.currentUser.visibleByAnonymousUsers = dictionary[@"data"][@"visibleByAnonymousUsers"];
    
}

- (BOOL) isAuthenticated {
    
    return self.currentUser.authenticationToken != nil;
    
}

@end
