//
//  CreateAlbumStepViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/9/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "CreateAlbumStepViewController.h"
#import "CreateAlbumViewController.h"
#import "MySetupInfo.h"

@interface CreateAlbumStepViewController ()

@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation CreateAlbumStepViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.setupInfo = setupInfo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(cancelSignup:) forControlEvents:UIControlEventTouchUpInside];
    customButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -20, 0, 0);
    customButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -19, 0, 0);
    [customButton sizeToFit];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;
 
    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.frame = CGRectMake(0, 0, 120, 48);

    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NavBar-Logo"]];
    imgView.translatesAutoresizingMaskIntoConstraints = NO;
    imgView.contentMode = UIViewContentModeScaleAspectFit;

    [headerView addSubview:imgView];

    [self.navigationItem setTitleView:headerView];
    
    /*
    NSLayoutConstraint *centerXConstraint = [imgView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor];
    NSLayoutConstraint *centerYConstraint = [imgView.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor];
    NSLayoutConstraint *widthConstraint = [imgView.widthAnchor constraintEqualToConstant:120];
    NSLayoutConstraint *heightConstraint = [imgView.heightAnchor constraintEqualToConstant:48];
    [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint, widthConstraint, heightConstraint]];
     */
    
    NSLayoutConstraint *leadingConstraint = [headerView.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [headerView.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor];
    NSLayoutConstraint *topConstraint = [headerView.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor];
    NSLayoutConstraint *bottomConstraint = [headerView.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor];
    [NSLayoutConstraint activateConstraints:@[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint]];

    NSLayoutConstraint *centerXConstraint = [imgView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor];
    NSLayoutConstraint *centerYConstraint = [imgView.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor];
    NSLayoutConstraint *widthConstraint = [imgView.widthAnchor constraintEqualToConstant:headerView.bounds.size.width];
    NSLayoutConstraint *heightConstraint = [imgView.heightAnchor constraintEqualToConstant:headerView.bounds.size.height];
    [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint, widthConstraint, heightConstraint]];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createAlbum:(id)sender
{
    CreateAlbumViewController *createAlbumViewController = [[CreateAlbumViewController alloc] initWithNibName:@"CreateAlbumViewController" bundle:nil setupInfo:self.setupInfo];
    
    UINavigationController *albumsNavigationController = [[UINavigationController alloc]  initWithRootViewController:createAlbumViewController];
    albumsNavigationController.navigationBar.translucent = NO;
    albumsNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:albumsNavigationController animated:NO completion:nil];
}

- (void)cancelSignup:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
