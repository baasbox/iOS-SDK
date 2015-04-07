//
//  SMLoginViewController.m
//  DearDiary
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "SMLoginViewController.h"

@interface SMLoginViewController ()

@end

@implementation SMLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlTapped:)
                    forControlEvents:UIControlEventValueChanged];
    
}

- (void) segmentedControlTapped:(id)sender {
    
    [self updateView];
    
}

- (void) updateView {
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        
        [UIView animateWithDuration:0.5f animations:^{
            
            self.loginView.alpha = 1;
            self.signupView.alpha = 0;
            
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5f animations:^{
            
            self.loginView.alpha = 0;
            self.signupView.alpha = 1;
            
        }];
        
    }
    
}

#pragma mark - Actions

- (IBAction) login {
    
    NSLog(@"login");
    
    BAAClient *client = [BAAClient sharedClient];
    
    [client authenticateUser:self.loginUsernameField.text
                    password:self.loginPasswordField.text
               completion:^(BOOL success, NSError *error) {
                   
                   if (success) {
                       
                       NSLog(@"user authenticated %@", client.currentUser);
                       [self dismissViewControllerAnimated:YES completion:nil];
                       
                   } else {
                       
                       NSLog(@"error in logging in %@", error);
                       
                   }
                   
               }];
    
}

- (IBAction) signup {
    
    NSLog(@"signup");
    
    BAAClient *client = [BAAClient sharedClient];
        
    [client createUserWithUsername:self.signupUsernameField.text
                       password:self.signupPasswordField.text
                 completion:^(BOOL success, NSError *error) {
                     
                     if (success) {
                         
                         NSLog(@"user created %@", client.currentUser);
                         [self dismissViewControllerAnimated:YES completion:nil];
                         
                     }
                     
                     else {
                         
                         NSLog(@"error in creating user: %@", error);
                         
                     }
                     
                 }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
