//
//  SMLoginViewController.h
//  DearDiary
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMLoginViewController : UIViewController

@property (weak) IBOutlet UIView *loginView;
@property (weak) IBOutlet UIView *signupView;
@property (weak) IBOutlet UISegmentedControl *segmentedControl;

@property (weak) IBOutlet UITextField *loginUsernameField;
@property (weak) IBOutlet UITextField *loginPasswordField;

@property (weak) IBOutlet UITextField *signupUsernameField;
@property (weak) IBOutlet UITextField *signupPasswordField;

- (IBAction) login;
- (IBAction) signup;

@end
