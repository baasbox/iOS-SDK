//
//  SMMasterViewController.m
//  DearDiary
//
//  Created by Cesare Rocchi on 9/26/13.
//  Copyright (c) 2013 Cesare Rocchi. All rights reserved.
//

#import "SMMasterViewController.h"
#import "SMDetailViewController.h"
#import "SMPost.h"
#import "SMLoginViewController.h"

@interface SMMasterViewController () {
    
    NSMutableArray *_posts;
    
}

@end

@implementation SMMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(createNewPost:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:@"POST_UPDATED"
                                               object:nil];
}

- (void) reload {
    
    [self.tableView reloadData];
    
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    BAAClient *client = [BAAClient sharedClient];
    
    if (client.isAuthenticated) {
        
        NSLog(@"Logged in");
        
        [SMPost getObjectsWithCompletion:^(NSArray *objects, NSError *error) {

            _posts = [objects mutableCopy];
            [self.tableView reloadData];

        }];
        
        // Example with query criteria        
//        [SMPost getObjectsWithParams:@{@"where" : @"postTitle='aaa'"}
//                          completion:^(NSArray *objects, NSError *error) {
//                              
//                              NSLog(@"objects = %@", objects);
//                              _posts = [objects mutableCopy];
//                              [self.tableView reloadData];
//                              
//                          }];

        
    } else {
        
        NSLog(@"need to login/signup");
        SMLoginViewController *loginViewController = [[SMLoginViewController alloc] initWithNibName:@"SMLoginViewController"
                                                                                             bundle:nil];
        [self.navigationController presentViewController:loginViewController
                                                animated:YES
                                              completion:nil];
        
    }
    
}

- (void)createNewPost:(id)sender {
    
    if (!_posts) {
        _posts = [[NSMutableArray alloc] init];
    }
    
    SMPost *p = [[SMPost alloc] init];
    p.postTitle = [NSString stringWithFormat:@"No title %i", _posts.count ];
    p.postBody = @"No body";
    
    [p saveObjectWithCompletion:^(SMPost *post, NSError *error) {
                
                if (error == nil) {
                    
                    NSLog(@"created post on server %@", post);
                    
                    [_posts insertObject:post atIndex:0];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0
                                                                inSection:0];
                    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                } else {
                    
                    NSLog(@"error in saving %@", error);
                    
                }
                
            }];
    
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    SMPost *post = _posts[indexPath.row];
    cell.textLabel.text = post.postTitle;
    cell.detailTextLabel.text = post.postBody;
    return cell;
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        SMPost *object = _posts[indexPath.row];
        [[segue destinationViewController] setPost:object];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
