//
//  FinishSetupViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "FinishSetupViewController.h"
#import "AppDelegate.h"
#import "MySetupInfo.h"
#import "MyAlbumInfo.h"
#import "MyContactInfo.h"

@interface FinishSetupViewController ()

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation FinishSetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.setupInfo = setupInfo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.HUD.delegate = self;
    
    self.navigationItem.title = @"Finish Setup";
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
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Finish Setup"];

    [self.navigationController.view addSubview:self.HUD];
    [self.HUD showAnimated:YES];

    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];
    
    [self.navigationController.view addSubview:self.HUD];
    [self.HUD showAnimated:YES];
    
    SetupAlbumManager *albumManager = [appDelegate getAlbumManager:self.setupInfo albumManagerDelegate:(id<SetupAlbumManagerDelegate>)self];
    [albumManager setupAlbum];
    
}

-(void)dismissModalViews
{
    if ([UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController)
    {
        [[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        [self performSelector:@selector(dismissModalViews) withObject:nil afterDelay:0.10];
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}

#pragma mark - SnagletAlbumManager Delegate

-(void)albumDataInvalid:(MyAlbumInfo *)albumInfo
{
    [self.HUD hideAnimated:YES];
    
    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];

    [self dismissModalViews];
    [appDelegate launchInRegularMode];
}

-(void)albumCreationBegin:(MyAlbumInfo *)albumInfo
{
    NSLog(@"%@", albumInfo.albumName);
}

-(void)albumCreationEnd:(NSError *)error albumInfo:(MyAlbumInfo *)albumInfo
{
    [self.HUD hideAnimated:YES];
    
    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"1" forKey:@"SetupComplete"];
    [defaults synchronize];

    [self dismissModalViews];
    [appDelegate launchInRegularMode];
}

-(void)contactCreationBegin:(MyContactInfo *)contactInfo
{
    NSLog(@"%@", contactInfo.displayName);
}

-(void)contactCreationEnd:(NSError *)error contactInfo:(MyContactInfo *)contactInfo
{
    NSLog(@"%ld - %@", contactInfo.serverId, contactInfo.displayName);
}


@end
