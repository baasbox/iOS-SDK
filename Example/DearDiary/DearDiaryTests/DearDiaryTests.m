//
//  DearDiaryTests.m
//  DearDiaryTests
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BaasBoxSDK/BAAClient.h>
#import "SMPost.h"

/*
 
 WARNING
 
 - assumes server is running on localhost
 - a user a:a is NOT created on the backend
 - a collection(memos) posts is created
 
 */

@interface DearDiaryTests : XCTestCase

@end

@implementation DearDiaryTests

#pragma mark - 
#pragma mark - Setup

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


#pragma mark - 
#pragma mark - Test Case

- (void)testAUserCreation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [BAAUser createUserWithUsername:@"cesare"
                           password:@"cesare"
                         completion:^(BAAUser *currentUser, NSError *error)
    {
        [expectation fulfill];
        
        XCTAssertNotNil(currentUser);
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testLoginWithAdmin {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUser:@"admin"
                    password:@"admin"
                  completion:^(BOOL success, NSError *error)
    {
        [expectation fulfill];
        XCTAssertTrue(client.isAuthenticated, @"Admin login failed");
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testLoginWrong {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [[BAAClient sharedClient] authenticateUser:@"a"
                     password:@"a"
                   completion:^(BOOL success, NSError *error)
    {
        [expectation fulfill];
        XCTAssertNotNil(error, @"login didn't fail as expected");

    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testCreationOfNewObject {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [self login];
    
    SMPost *p = [[SMPost alloc] init];
    p.postTitle = @"Mock title";
    p.postBody = @"No body";
    
    [p saveObjectWithCompletion:^(id object, NSError *error)
    {
        [expectation fulfill];
        XCTAssertNil(error, @"error is not nil as expected");
        XCTAssertNotNil(object, @"post is nil, it shouldn't.");
    
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testObjectRetrieval {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [self login];
    
    [SMPost getObjectsWithCompletion:^(NSArray *objects, NSError *error)
    {
        [expectation fulfill];
        XCTAssertNil(error, @"error is not nil");
        XCTAssertNotNil(objects, @"returned array is nil");
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testObjectRetrievalWithParams {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [self login];
    
    [SMPost getObjectsWithParams:@{kPageNumberKey : @0,
                                   kPageSizeKey : @4}
                      completion:^(NSArray *objects, NSError *error)
    {
        [expectation fulfill];
        XCTAssertNil(error, @"error is not nil");
        XCTAssertNotNil(objects, @"returned array is nil");
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void)testObjectDeletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    [SMPost getObjectsWithCompletion:^(NSArray *objects, NSError *error)
     {
         XCTAssertNil(error, @"error is not nil");
         XCTAssertNotNil(objects, @"returned array is nil");
         
         [(SMPost *)objects.firstObject deleteObjectWithCompletion:^(BOOL success, NSError *error)
          {
              [expectation fulfill];
              XCTAssertTrue(success, @"object not deleted as expected");
              XCTAssertNil(error, @"error is not nil");
              
          }];
     }];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
    
}

- (void)testSignup {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async testing"];
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUser:@"cesare"
                    password:@"cesare"
                  completion:^(BOOL success, NSError *error)
    {
        [expectation fulfill];
        XCTAssertTrue(client.isAuthenticated, @"Not signed up as expected");
        XCTAssertNil(error, @"Error is not nil");
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}


#pragma mark - 
#pragma mark - Helper method

- (void)login {
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUser:@"cesare"
                    password:@"cesare"
                  completion:^(BOOL success, NSError *error)
     {
         XCTAssertTrue(client.isAuthenticated, @"Didn't authenticate as expected. Check if user really exists on the backend");
         
     }];
}


@end
