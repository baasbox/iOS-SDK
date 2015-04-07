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

@property (nonatomic, copy) NSString *authenticationToken;
@property (nonatomic, copy) NSString *pushNotificationToken;
@property (nonatomic, assign) BOOL pushEnabled;
@property (nonatomic, copy) NSDictionary *roles;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, strong) NSMutableDictionary *visibleByTheUser;
@property (nonatomic, strong) NSMutableDictionary *visibleByFriends;
@property (nonatomic, strong) NSMutableDictionary *visibleByRegisteredUsers;
@property (nonatomic, strong) NSMutableDictionary *visibleByAnonymousUsers;

- (instancetype) initWithDictionary:(NSDictionary *)dict;
- (NSString *) jsonString;
- (NSString *) username;

// login/logout
+ (void) loginWithUsername:(NSString *)username password:(NSString *)password completion:(BAABooleanResultBlock)completionHandler;
+ (void) logoutWithCompletion:(BAABooleanResultBlock)completionBlock;

// load
+ (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock;
+ (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
+ (void) loadUserDetails:(NSString *)username completion:(BAAObjectResultBlock)completionBlock;
+ (void) loadRandomUserWithCompletion:(BAAArrayResultBlock)completionBlock;

// Social
+ (void) loginWithFacebookToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock;
- (void) linkToFacebookWithToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock;
- (void) unlinkFromFacebookWithCompletion:(BAABooleanResultBlock)completionBlock;
+ (void) loginWithGoogleToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock;
- (void) linkToGoogleWithToken:(NSString *)token completion:(BAABooleanResultBlock)completionBlock;
- (void) unlinkFromGoogleWithCompletion:(BAABooleanResultBlock)completionBlock;
- (void) fetchLinkedSocialNetworksWithCompletion:(BAAArrayResultBlock)completionBlock;

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
