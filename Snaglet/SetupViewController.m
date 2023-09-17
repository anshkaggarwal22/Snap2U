//
//  SetupViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SetupViewController.h"
#import "SignupViewController.h"
#import "VerifyViewController.h"
#import "CreateAlbumStepViewController.h"
#import "MySetupInfo.h"

@interface SetupViewController ()

@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation SetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo
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
    
    // Do any additional setup after loading the view from its nib.
    [self.view setBackgroundColor:[UIColor clearColor]];
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

- (IBAction)getStarted:(id)sender
{    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL signupComplete = [[defaults objectForKey:@"SignupComplete"] boolValue];
    BOOL activationComplete = [[defaults objectForKey:@"ActivationComplete"] boolValue];
    
    if (!signupComplete || !activationComplete)
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Getting Started"];

        UIViewController *createAlbumStepViewController = [[CreateAlbumStepViewController alloc] initWithNibName:@"CreateAlbumStepViewController" bundle:[NSBundle mainBundle] setupInfo:self.setupInfo];
        
        UINavigationController *createAlbumNavigationViewController = [[UINavigationController alloc] initWithRootViewController:createAlbumStepViewController];
        createAlbumNavigationViewController.navigationBar.translucent = NO;
        createAlbumNavigationViewController.modalPresentationStyle = UIModalPresentationFullScreen;

        [self presentViewController:createAlbumNavigationViewController animated:NO completion:nil];
    }
}

- (IBAction)alreadyRegisteredUser:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Already Registered User"];

    VerifyViewController *verifyViewController = [[VerifyViewController alloc] initWithNibName:@"VerifyViewController" bundle:nil];

    UINavigationController *verifyNavigationController = [[UINavigationController alloc] initWithRootViewController:verifyViewController];
    
    verifyNavigationController.navigationBar.translucent = NO;
    verifyNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self.navigationController presentViewController:verifyNavigationController animated:NO completion:nil];
}

@end
