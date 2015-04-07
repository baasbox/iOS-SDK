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


//http://stablekernel.com/blog/speeding-up-nscoding-with-macros/
#define OBJC_STRINGIFY(x) @#x
#define encodeObject(x) [aCoder encodeObject:x forKey:OBJC_STRINGIFY(x)]
#define decodeObject(x) x = [aDecoder decodeObjectForKey:OBJC_STRINGIFY(x)]
#define encodeBool(x) [aCoder encodeBool:x forKey:OBJC_STRINGIFY(x)]
#define decodeBool(x) x = [aDecoder decodeBoolForKey:OBJC_STRINGIFY(x)]
#define encodeInteger(x) [aCoder encodeInteger:x forKey:OBJC_STRINGIFY(x)]
#define decodeInteger(x) x = [aDecoder decodeIntegerForKey:OBJC_STRINGIFY(x)]

#import "BAAUser.h"
#import <objc/runtime.h>

@interface BAAUser () {

}

@property (nonatomic, copy) NSMutableDictionary *user;

@end

@implementation BAAUser


- (instancetype) initWithDictionary:(NSDictionary *)dict {

    self = [super init];
    
    if (self) {
        
        _user = dict[@"user"];
        _roles = dict[@"user"][@"roles"];
        _status = dict[@"user"][@"status"];
        _visibleByAnonymousUsers = [NSMutableDictionary dictionaryWithDictionary:dict[@"visibleByAnonymousUsers"]];
        _visibleByRegisteredUsers = [NSMutableDictionary dictionaryWithDictionary:dict[@"visibleByRegisteredUsers"]];
        
        if (dict[@"visibleByFriends"] == [NSNull null]) {
            
            _visibleByFriends = [NSMutableDictionary dictionary];
            
        } else {
            
            _visibleByFriends = [NSMutableDictionary dictionaryWithDictionary:dict[@"visibleByFriends"]];
            
        }
        
        if (dict[@"visibleByTheUser"] == [NSNull null]) {
            
            _visibleByTheUser = [NSMutableDictionary dictionary];
            
        } else {
            
            _visibleByTheUser = [NSMutableDictionary dictionaryWithDictionary:dict[@"visibleByTheUser"]];
            
        }
        
    }
    
    return self;
    
}

#pragma mark - Login

+ (void) loginWithUsername:(NSString *)username password:(NSString *)password completion:(BAABooleanResultBlock)completionHandler {
  
  BAAClient *client = [BAAClient sharedClient];
  [client authenticateUser:username password:password completion:^(BOOL success, NSError *error) {
    
    if (completionHandler) {
      completionHandler(success, error);
    }
    
  }];
  
}

+ (void) logoutWithCompletion:(BAABooleanResultBlock)completionBlock {
  
  BAAClient *client = [BAAClient sharedClient];
  [client logoutWithCompletion:^(BOOL success, NSError *error) {
    
    if (completionBlock) {
      completionBlock(success, error);
    }
    
  }];
  
}

#pragma mark - Load

+ (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadCurrentUserWithCompletion:^(BAAUser *user, NSError *error) {
        
        if (completionBlock){
            completionBlock(user, error);
        }
        
    }];
    
}

+ (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadUsersWithParameters:parameters
                         completion:^(NSArray *users, NSError *error) {
                             
                             if (completionBlock) {
                                 
                                 if (error == nil) {
                                     
                                     completionBlock(users, nil);
                                     
                                 } else {
                                     
                                     completionBlock(nil, error);
                                     
                                 }
                             }
                             
                         }];
    
}

+ (void) loadRandomUserWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    if (completionBlock) {
        
        [self loadUsersWithParameters:@{} completion:^(NSArray *users, NSError *error) {
            
            if (error == nil) {
                
                if (users.count <= 1) {
                    
                    // This is the edge case where this user is the only user.
                    completionBlock(@[],  nil);
                    
                } else {
                    
                    BAAUser *currentUser = [[BAAClient sharedClient] currentUser];
                    BAAUser *randomUser;
                    
                    do {
                        
                        NSInteger randomIndex = arc4random_uniform((u_int32_t)users.count);
                        randomUser = users[randomIndex];
                        
                    } while ([randomUser.username isEqualToString:currentUser.username]);  // Ensures that the random user is not the current user.
                    
                    completionBlock([NSArray arrayWithObject:randomUser], nil);
                    
                }
                
            } else {
                completionBlock(nil, error);
            }
        }];
    }
}

+ (void) loadUserDetails:(NSString *)username completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    
    [client loadUsersDetails:username
                  completion:^(BAAUser *user, NSError *error) {
        
                      if (completionBlock)
                          completionBlock(user, error);
                      
    }];
    
}

- (void) loadFollowingWithCompletion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFollowingForUser:self
                      completion:^(NSArray *users, NSError *error) {
                          
                          if (completionBlock)
                              completionBlock(users, error);
                          
                      }];
    
}

- (void) loadFollowersWithCompletion:(BAAArrayResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client loadFollowersOfUser:self
                      completion:^(NSArray *users, NSError *error) {
                          
                          if (completionBlock) {
                              completionBlock(users, error);
                          }
                          
                      }];
    
}

#pragma mark - Social

+ (void) loginWithFacebookToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client postPath:@"/social/facebook"
          parameters:@{@"oauth_token":token, @"oauth_secret":token}
             success:^(id responseObject) {
                 
                 BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                 user.authenticationToken = responseObject[@"data"][@"X-BB-SESSION"];
                 client.currentUser = user;
                 [client saveUserToDisk:user];
                 if (completionBlock) {
                     completionBlock(YES, nil);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(NO, error);
                 }
                 
             }];
    
}

- (void) linkToFacebookWithToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client putPath:@"/social/facebook"
         parameters:@{@"oauth_token":token, @"oauth_secret":token}
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

- (void) unlinkFromFacebookWithCompletion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client deletePath:@"/social/facebook"
            parameters:nil
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

+ (void) loginWithGoogleToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client postPath:@"/social/google"
          parameters:@{@"oauth_token":token, @"oauth_secret":token}
             success:^(id responseObject) {
                 
                 BAAUser *user = [[BAAUser alloc] initWithDictionary:responseObject[@"data"]];
                 user.authenticationToken = responseObject[@"data"][@"X-BB-SESSION"];
                 client.currentUser = user;
                 [client saveUserToDisk:user];
                 if (completionBlock) {
                     completionBlock(YES, nil);
                 }
                 
             } failure:^(NSError *error) {
                 
                 if (completionBlock) {
                     completionBlock(NO, error);
                 }
                 
             }];
    
}

- (void) linkToGoogleWithToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client putPath:@"/social/google"
         parameters:@{@"oauth_token":token, @"oauth_secret":token}
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

- (void) unlinkFromGoogleWithCompletion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client deletePath:@"/social/google"
            parameters:nil
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

- (void) fetchLinkedSocialNetworksWithCompletion:(BAAArrayResultBlock)completionBlock {
    
    BAAClient *client = [BAAClient sharedClient];
    [client getPath:@"/social"
         parameters:nil
            success:^(id responseObject) {
                if (completionBlock) {
                    NSArray *res = responseObject[@"data"];
                    completionBlock(res, nil);
                }
            } failure:^(NSError *error) {
                if(completionBlock) {
                    completionBlock(nil, error);
                }
            }];
    
}

#pragma mark - Update

- (void) updateWithCompletion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client updateUserWithCompletion:completionBlock];

}

#pragma mark - Follow/Unfollow

+ (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client followUser:user
            completion:^(BAAUser *user, NSError *error) {
                
                if (completionBlock)
                    completionBlock(user, error);
                
            }];
    
}

+ (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client unfollowUser:user
              completion:^(BOOL success, NSError *error) {
                  
                  if (completionBlock)
                      completionBlock(success, error);
                  
              }];
    
}

- (void) changeOldPassword:(NSString *)oldPassword toNewPassword:(NSString *)newPassword completionBlock:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client changeOldPassword:oldPassword
                toNewPassword:newPassword
                   completion:completionBlock];
    
}

- (void) resetPasswordWithCompletion:(BAABooleanResultBlock)completionBlock {

    BAAClient *client = [BAAClient sharedClient];
    [client resetPasswordForUser:self
                  withCompletion:completionBlock];
    
}


#pragma mark - Helpers

- (NSDictionary*) objectAsDictionary {
    
    NSArray *exclude = @[@"authenticationToken", @"pushNotificationToken", @"pushEnabled", @"roles"];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    unsigned int propertiesCount;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertiesCount);
    
    for (int i = 0 ; i < propertiesCount; i++) {
        objc_property_t property = propertyList[i];
        const char *propertyChar = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:propertyChar
                                                    encoding:NSASCIIStringEncoding];
        
        if (![exclude containsObject:propertyName]) {
            
            id value = [self valueForKey:propertyName];
            
            if (value) {

                [result setObject:value forKey:propertyName];

            }
            
        }
        
    }
    
    free(propertyList);
    return [NSDictionary dictionaryWithDictionary:result];
    
}

- (NSString *) jsonString {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self objectAsDictionary]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *res = [[NSString alloc] initWithData:jsonData
                                          encoding:NSUTF8StringEncoding];
    return res;
    
}

- (NSMutableDictionary *) visibleByAnonymousUsers {
    
    if (_visibleByAnonymousUsers == nil) {
        _visibleByAnonymousUsers = [NSMutableDictionary dictionary];
    }
    
    return _visibleByAnonymousUsers;
    
}

- (NSMutableDictionary *) visibleByTheUser {
    
    if (_visibleByTheUser == nil) {
        _visibleByTheUser = [NSMutableDictionary dictionary];
    }
    
    return _visibleByTheUser;
    
}

- (NSMutableDictionary *) visibleByFriends {
    
    if (_visibleByFriends == nil) {
        _visibleByFriends = [NSMutableDictionary dictionary];
    }
    
    return _visibleByFriends;
    
}

- (NSMutableDictionary *) visibleByRegisteredUsers {
    
    if (_visibleByRegisteredUsers == nil) {
        _visibleByRegisteredUsers = [NSMutableDictionary dictionary];
    }
    
    return _visibleByRegisteredUsers;
    
}

- (NSString *) username {
  
  if ([self.visibleByRegisteredUsers[@"_social"] count] > 0) {
    return self.visibleByTheUser[@"name"];
  } else {
    return self.user[@"name"];
  }
  
}

- (NSString *)description {
    
    return [[self objectAsDictionary] description];
    
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if(self) {
        
        decodeObject(_user);
        decodeObject(_authenticationToken);
        decodeObject(_pushNotificationToken);
        decodeBool(_pushEnabled);
        decodeObject(_visibleByAnonymousUsers);
        decodeObject(_visibleByRegisteredUsers);
        decodeObject(_visibleByFriends);
        decodeObject(_visibleByTheUser);
        
    }
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    encodeObject(_user);
    encodeObject(_authenticationToken);
    encodeObject(_pushNotificationToken);
    encodeBool(_pushEnabled);
    encodeObject(_visibleByAnonymousUsers);
    encodeObject(_visibleByRegisteredUsers);
    encodeObject(_visibleByFriends);
    encodeObject(_visibleByTheUser);
    
}

@end
