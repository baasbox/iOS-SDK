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
#import "BAAClient.h"

@interface BAAUser : NSObject <NSCoding>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *authenticationToken;
@property (nonatomic, copy) NSString *pushNotificationToken;
@property (nonatomic, assign) BOOL pushEnabled;
@property (nonatomic, copy) NSDictionary *roles;
@property (nonatomic, copy) NSMutableDictionary *visibleByTheUser;
@property (nonatomic, copy) NSMutableDictionary *visibleByFriends;
@property (nonatomic, copy) NSMutableDictionary *visibleByRegisteredUsers;
@property (nonatomic, copy) NSMutableDictionary *visibleByAnonymousUsers;

- (instancetype) initWithDictionary:(NSDictionary *)dict;
- (NSString *) jsonString;

// load
+ (void) logoutWithCompletion:(BAABooleanResultBlock)completionBlock;
+ (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock;
+ (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
+ (void) loadUserDetails:(NSString *)username completion:(BAAObjectResultBlock)completionBlock;

// update
- (void) updateWithCompletion:(BAAObjectResultBlock)completionBlock;

// Follow/unfollow
- (void) loadFollowingWithCompletion:(BAAArrayResultBlock)completionBlock;
- (void) loadFollowersWithCompletion:(BAAArrayResultBlock)completionBlock;
+ (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completionBlock;
+ (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completionBlock;

// Password
- (void) changeOldPassword:(NSString *)oldPassword toNewPassword:(NSString *)newPassword completionBlock:(BAABooleanResultBlock)completionBlock;
- (void) resetPasswordWithCompletion:(BAABooleanResultBlock)completionBlock;

@end