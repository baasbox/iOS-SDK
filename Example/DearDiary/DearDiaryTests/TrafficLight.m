//
//  TestSemaphor.m
//  BillsApp
//
//  Created by Marin Todorov on 17/01/2012.
//  Copyright (c) 2012 Marin Todorov. All rights reserved.
//

#import "TrafficLight.h"

@implementation TrafficLight

@synthesize flags;

+(TrafficLight *)sharedInstance
{   
    static TrafficLight *sharedInstance = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedInstance = [TrafficLight alloc];
        sharedInstance = [sharedInstance init];
    });
    
    return sharedInstance;
}

-(id)init
{
    self = [super init];
    if (self != nil) {
        self.flags = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

-(void)dealloc
{
    self.flags = nil;
}

-(BOOL)isGreen:(NSString*)key
{
    return [self.flags objectForKey:key]!=nil;
}

-(void)goGreen:(NSString*)key
{
    [self.flags setObject:@"YES" forKey: key];
}

-(void)waitGreenForKey:(NSString*)key
{
    BOOL keepRunning = YES;
    while (keepRunning && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                                   beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
        keepRunning = ![[TrafficLight sharedInstance] isGreen: key];
    }

}

@end
