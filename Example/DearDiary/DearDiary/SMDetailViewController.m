//
//  SMDetailViewController.m
//  DearDiary
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "SMDetailViewController.h"

@interface SMDetailViewController () {

    SMPost *_post;
    
}

- (void)configureView;
@end

@implementation SMDetailViewController

#pragma mark - Managing the detail item

- (void)setPost:(SMPost *)post {
    
    if (_post != post) {
        _post = post;
        [self configureView];
    }
}

- (SMPost *) post {
    return _post;
}

- (void)configureView {
    
    self.titleField.text = self.post.postTitle;
    self.bodyTextView.text = self.post.postBody;
    
}

- (void)viewDidLoad
{
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.titleField.leftView = paddingView;
    self.titleField.leftViewMode = UITextFieldViewModeAlways;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(savePost:)];
    
    [self configureView];
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.titleField becomeFirstResponder];
    
}

- (void) savePost:(id)sender {
    
    self.post.postTitle = self.titleField.text;
    self.post.postBody = self.bodyTextView.text;
    
    [self.post saveObjectWithCompletion:^(id object, NSError *error) {
                
                if (error == nil) {
                    
                    NSLog(@"object saved");
                    self.post = object;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"POST_UPDATED"
                                                                        object:nil];
                    [self.navigationController popViewControllerAnimated:YES];
                    
                }
                else {
                    
                    NSLog(@"error in updating %@", error);
                    
                }
                
            }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
