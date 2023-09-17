//
//  UploadCompleteViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "UploadCompleteViewController.h"
#import "AppDelegate.h"
#import "SnagletAnalytics.h"

@interface UploadCompleteViewController ()

@property (nonatomic, strong) UIViewController *photoViewController;

@end

@implementation UploadCompleteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil photoViewController:(UIViewController*)photoViewController
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.photoViewController = photoViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Upload";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)finishSetup:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
        [self.photoViewController.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
