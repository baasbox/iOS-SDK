//
//  SMDetailViewController.h
//  DearDiary
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMPost.h"

@interface SMDetailViewController : UIViewController

@property (weak) IBOutlet UITextField *titleField;
@property (weak) IBOutlet UITextView *bodyTextView;

- (void)setPost:(SMPost *)post;

@end
