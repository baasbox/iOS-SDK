//
//  BAAMutableURLRequest.m
//
//  Created by Cesare Rocchi on 12/4/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "BAAMutableURLRequest.h"

@implementation BAAMutableURLRequest

-(id) init {
    self = [super init];
    
    if (self) {
        _contentType = BAAContentTypeJSON;
    }
    
    return self;
}

@end
