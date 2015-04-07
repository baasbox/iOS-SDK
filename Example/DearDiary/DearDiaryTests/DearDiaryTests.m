//
//  DearDiaryTests.m
//  DearDiaryTests
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BAAClient.h"
#import "TrafficLight.h"
#import "SMPost.h"

/*
 
 WARNING
 
 - assumes server is running
 - a user cesare:cesare is created on the backend
 - a user a:a is NOT created on the backend
 - a collection posts is created
 
 */

@interface DearDiaryTests : XCTestCase

@property (strong) SMPost *post;

@end

@implementation DearDiaryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAdminLogin {
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUsername:@"admin"
                    withPassword:@"admin"
               completionHandler:^(BOOL success, NSError *error) {
                   
                   [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                   
                   XCTAssertTrue(client.isAuthenticated, @"Admin login failed");
                   
               }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void)testLoginWrong {
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUsername:@"a"
                    withPassword:@"a"
               completionHandler:^(BOOL success, NSError *error) {
                   
                   [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                   
                   XCTAssertNotNil(error, @"login didn't fail as expected");
                   
               }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void)testLogin {
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUsername:@"cesare"
                    withPassword:@"cesare"
               completionHandler:^(BOOL success, NSError *error) {
                   
                   [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                   
                   XCTAssertTrue(client.isAuthenticated, @"Didn't authenticate as expected. Check if user really exists on the backend");
                   
               }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void)testCreationOfNewObject {
    
    [self testLogin];
    
    SMPost *p = [[SMPost alloc] init];
    p.postTitle = @"Mock title";
    p.postBody = @"No body";
    
    [SMPost saveObject:p
            completion:^(SMPost *post, NSError *error) {
                
                [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                XCTAssertNil(error, @"error is not nil as expected");
                XCTAssertNotNil(post, @"post is nil, it shouldn't.");
                
            }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void) testObjectRetrieval {
    
    [self testLogin];
    
    [SMPost getObjectsWithCompletion:^(NSArray *objects, NSError *error) {
        
        [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
        XCTAssertNil(error, @"error is not nil");
        XCTAssertNotNil(objects, @"returned array is nil");
        
    }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void) testObjectRetrievalWithParams {
    
    [self testLogin];
    
    [SMPost getObjectsWithParams:@{kPageNumber : @0, kPageSize : @4}
                      completion:^(NSArray *objects, NSError *error) {
                          
                          [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                          XCTAssertNil(error, @"error is not nil");
                          XCTAssertNotNil(objects, @"returned array is nil");
                          
                      }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void) testSingleObjectRetrieval {
    
    [self testLogin];
    
    [SMPost getObjectsWithCompletion:^(NSArray *objects, NSError *error) {
        
        [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
        XCTAssertNil(error, @"error is not nil");
        XCTAssertNotNil(objects, @"returned array is nil");
        self.post = (SMPost *) [objects firstObject];
        
    }];
    
    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}

- (void) testObjectDeletion {

    [self testSingleObjectRetrieval];
    
    [SMPost deleteObject:self.post
              completion:^(BOOL success, NSError *error) {

                  [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                  XCTAssertTrue(success, @"object not deleted as expected");
                  XCTAssertNil(error, @"error is not nil");
                  
              }];

    [[TrafficLight sharedInstance] waitGreenForKey:NSStringFromSelector(_cmd)];
    
}



- (void) testSignup {
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client createUserWithUsername:@"cesare"
                       andPassword:@"cesare"
                 completionHandler:^(BOOL success, NSError *error) {
                     
                     [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
                     XCTAssertTrue(client.isAuthenticated, @"Not signed up as expected");
                     XCTAssertNil(error, @"Error is not nil");
                 }];
    
    [[TrafficLight sharedInstance] goGreen:NSStringFromSelector(_cmd)];
    
}



@end
