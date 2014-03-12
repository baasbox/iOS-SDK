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
#import "BaasBox.h"

@interface BAAClient : NSObject

@property (nonatomic, strong) BAAUser *currentUser;
@property (nonatomic, strong, readonly) NSURL *baseURL;

+ (instancetype)sharedClient;

// Authentication
- (void)authenticateUser:(NSString *)username
                password:(NSString *)password
              completion:(BAABooleanResultBlock)completionBlock;

- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                    completion:(BAABooleanResultBlock)completionBlock;

- (BOOL) isAuthenticated;

- (void) logoutWithCompletion:(BAABooleanResultBlock)completionBlock;

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
- (void) enablePushNotifications:(NSData *)token completion:(BAABooleanResultBlock)completionBlock;
- (void) disablePushNotificationsWithCompletion:(BAABooleanResultBlock)completionBlock;

// Files
- (void) loadFiles:(BAAFile *)file completion:(BAAArrayResultBlock)completionBlock;
- (void) loadFiles:(BAAFile *)file withParams:(NSDictionary *) parameters completion:(BAAArrayResultBlock)completionBlock;
- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file completion:(void(^)(NSData *data, NSError *error))completionBlock;
- (NSURLSessionDataTask *) loadFileData:(BAAFile *)file parameters:(NSDictionary *)parameters completion:(void(^)(NSData *data, NSError *error))completionBlock;
- (void) uploadFile:(BAAFile *)file withPermissions:(NSDictionary *)permissions completion:(BAAObjectResultBlock)completionBlock;
- (void) deleteFile:(BAAFile *)file completion:(BAABooleanResultBlock)completionBlock;
- (void) loadFileDetails:(NSString *)fileID completion:(BAAObjectResultBlock)completionBlock;
- (void) loadFilesAndDetailsWithCompletion:(BAAArrayResultBlock)completionBlock;

// User
- (void) loadCurrentUserWithCompletion:(BAAObjectResultBlock)completionBlock;
- (void) updateUserWithCompletion:(BAAObjectResultBlock)completionBlock;
- (void) loadUsersWithCompletion:(BAAArrayResultBlock)completionBlock;
- (void) loadUsersWithParameters:(NSDictionary *)parameters completion:(BAAArrayResultBlock)completionBlock;
- (void) loadUsersDetails:(NSString *) userId completion:(BAAObjectResultBlock)completionBlock;
- (void) loadFollowingForUser:(BAAUser *)user completion:(BAAArrayResultBlock)completionBlock;
- (void) loadFollowersOfUser:(BAAUser *)user completion:(BAAArrayResultBlock)completionBlock;
- (void) followUser:(BAAUser *)user completion:(BAAObjectResultBlock)completionBlock;
- (void) unfollowUser:(BAAUser *)user completion:(BAABooleanResultBlock)completionBlock;

// Acl
- (void) grantAccess:(BAAFile *)file toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) grantAccess:(BAAFile *)file toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccess:(BAAFile *)file toRole:(NSString *)roleName accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;
- (void) revokeAccess:(BAAFile *)file toUser:(NSString *)username accessType:(NSString *)access completion:(BAAObjectResultBlock)completionBlock;

// Password
- (void) changeOldPassword:(NSString *)oldPassword toNewPassword:(NSString *)newPassword completion:(BAABooleanResultBlock)completionBlock;
- (void) resetPasswordForUser:(BAAUser *)user withCompletion:(BAABooleanResultBlock)completionBlock;

// Admin
- (void) createCollection:(NSString *)collectionName completion:(BAAObjectResultBlock)completionBlock;
- (void) loadSettingsWithCompletion:(BAAObjectResultBlock)completionBlock;
- (void) loadSettingsSection:(NSString *)sectionName completion:(BAAObjectResultBlock)completionBlock;
- (void) setValue:(NSString *)value forKey:(NSString *)key inSection:(NSString *)sectionName completion:(BAAObjectResultBlock)completionBlock;

// Core methods
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id responseObject))success
        failure:(void (^)(NSError *error))failure;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(id responseObject))success
         failure:(void (^)(NSError *error))failure;

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id responseObject))success
        failure:(void (^)(NSError *error))failure;
    
- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(id responseObject))success
           failure:(void (^)(NSError *error))failure;


// Pagination constants
extern NSString * const kPageNumberKey;
extern NSString * const kPageSizeKey;
extern NSInteger const kPageLength;

// Role constants
extern NSString * const kAclAnonymousRole;
extern NSString * const kAclRegisteredRole;
extern NSString * const kAclAdministratorRole;

// ACL constants
extern NSString * const kAclReadPermission;
extern NSString * const kAclDeletePermission;
extern NSString * const kAclUpdatePermission;




@end