//
//  SMPost.m
//  DearDiary
//
//  Created by Cesare Rocchi on 8/21/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "SMPost.h"

@implementation SMPost

- (instancetype) initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super initWithDictionary:dictionary];
    
    if (self) {
        
        _postTitle = dictionary[@"postTitle"];
        _postBody = dictionary[@"postBody"];
        
    }
    
    return self;
    
}

- (NSString *)collectionName {
    
    return @"document/memos";
    
}

@end
