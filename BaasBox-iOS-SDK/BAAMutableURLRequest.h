//
//  BAAMutableURLRequest.h
//
//  Created by Cesare Rocchi on 12/4/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BAAContentType) {
    BAAContentTypeJSON,
    BAAContentTypeForm
};

@interface BAAMutableURLRequest : NSMutableURLRequest

@property (assign) BAAContentType contentType;

@end
