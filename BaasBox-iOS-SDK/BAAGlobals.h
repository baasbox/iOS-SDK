//
//  BAAGlobals.h
//
//  Created by Cesare Rocchi on 8/21/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#define kPageNumber @"page"
#define kPageSize @"recordsPerPage"

#import <Foundation/Foundation.h>

typedef void (^BAAArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^BAAObjectResultBlock)(id object, NSError *error);
typedef void (^BAABooleanResultBlock)(BOOL success, NSError *error);

@interface BAAGlobals : NSObject

@end
