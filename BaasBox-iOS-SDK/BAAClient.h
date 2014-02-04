//
//  BAAClient.h
//
//  Created by Cesare Rocchi on 8/14/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "BAAUser.h"
#import "BAAObject.h"
#import "BAAGlobals.h"
#import "BAAFile.h"

@interface BAAClient : NSObject

@property (nonatomic, strong) BAAUser *currentUser;
@property (nonatomic, strong, readonly) NSURL *baseURL;

+ (instancetype)sharedClient;

// Authentication
- (void)authenticateUser:(NSString *)username
                password:(NSString *)password
              completion:(BAABooleanResultBlock)completionHander;

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                    completion:(BAABooleanResultBlock)completionHander;

- (BOOL) isAuthenticated;

- (void) logoutWithCompletion:(BAABooleanResultBlock)completionHander;

// Loading
- (void) loadObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock;
- (void) loadCollection:(BAAObject *)object completion:(BAAArrayResultBlock)completionBlock;
- (void) loadCollection:(BAAObject *)object withParams:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;

// saving
- (void) createObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock;
- (void) updateObject:(BAAObject *)object completion:(BAAObjectResultBlock)completionBlock;

// Deleting
- (void) deleteObject:(BAAObject *)object completion:(BAABooleanResultBlock)completionBlock;

// Push notifications
- (void) askToEnablePushNotifications;
- (void) enablePushNotification:(NSData *)token completion:(BAABooleanResultBlock)completion;

// Files
- (void) loadFiles:(BAAFile *)file completion:(BAAArrayResultBlock)completionBlock;
- (void) loadFiles:(BAAFile *)file withParams:(NSDictionary *) parameters completion:(BAAArrayResultBlock)completionBlock;
- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file completion:(void(^)(NSData *data, NSError *error))completionBlock;
- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file parameters:(NSDictionary *)parameters completion:(void(^)(NSData *data, NSError *error))completionBlock;
- (void) uploadFile:(BAAFile *)file completion:(BAAObjectResultBlock)completionBlock;
- (void) deleteFile:(BAAFile *)file completion:(BAABooleanResultBlock)completionBlock;
- (void) loadFileDetails:(NSString *)fileID completion:(BAAObjectResultBlock)completionBlock;

// User
- (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completion;
- (void) updateUserWithCompletion:(BAAObjectResultBlock)completion;
- (void) loadUsersWithCompletion:(BAAArrayResultBlock)completion;
- (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
- (void) loadUsersDetails:(NSString *) userId completion:(BAAObjectResultBlock)completion;
- (void) loadFollowingForUser:(BAAUser *)user completion:(BAAArrayResultBlock)completion;
- (void) loadFollowersOfUser:(BAAUser *)user completion:(BAAArrayResultBlock)completion;
- (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completion;
- (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completion;

// Acl
- (void) grantAccess:(BAAFile *)file toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) grantAccess:(BAAFile *)file toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccess:(BAAFile *)file toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccess:(BAAFile *)file toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;

extern NSString * const kAclAnonymousRole;
extern NSString * const kAclRegisteredRole;
extern NSString * const kAclAdministratorRole;

extern NSString * const kAclReadPermission;
extern NSString * const kAclDeletePermission;
extern NSString * const kAclUpdatePermission;


@end