//
//  TestSemaphor.h
//  BillsApp
//
//  Created by Marin Todorov on 17/01/2012.
//  Copyright (c) 2012 Marin Todorov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TrafficLight : NSObject

@property (strong, atomic) NSMutableDictionary* flags;

+(TrafficLight *)sharedInstance;

-(BOOL)isGreen:(NSString*)key;
-(void)goGreen:(NSString*)key;
-(void)waitGreenForKey:(NSString*)key;

@end
