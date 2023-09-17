//
//  ActivateAppViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "ActivateAppViewController.h"
#import "AppHelper.h"
#import "AppDelegate.h"
#import "MySetupInfo.h"
#import "FinishSetupViewController.h"

@interface ActivateAppViewController ()

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation ActivateAppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo
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

    self.navigationItem.title = @"Verify PIN";

    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(cancelActivation:)forControlEvents:UIControlEventTouchUpInside];
    customButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -20, 0, 0);
    customButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -19, 0, 0);
    [customButton sizeToFit];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;
    
    self.txtPinCode.backgroundColor = [UIColor whiteColor];
    self.txtPinCode.delegate = self;
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.txtPinCode.leftView = paddingView;
    self.txtPinCode.leftViewMode = UITextFieldViewModeAlways;
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

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self validateTextField:textField];
}

-(BOOL)validateTextField:(UITextField*)textField
{
    NSString *textData = textField.text;
    NSString *trimmedString = [textData stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
    if ([trimmedString isEqualToString:@""])
    {
        textField.layer.cornerRadius = 0.0f;
        textField.layer.masksToBounds = YES;
        textField.layer.borderColor = [[UIColor redColor] CGColor];
        textField.layer.borderWidth = 1.0f;
        return NO;
    }
    else
    {
        textField.layer.borderColor = [[UIColor clearColor] CGColor];
        return YES;
    }
}

- (IBAction)activateApp:(id)sender
{
    if ([self validateTextField:self.txtPinCode])
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Activate App"];

        NSString *ownerId = [AppHelper getOwnerId];
        NSString *pinCode = self.txtPinCode.text;
        
        [self.txtPinCode resignFirstResponder];
        
        NSString *activationUrl = [AppHelper getActivationUrl];
        
        [self.navigationController.view addSubview:self.HUD];
        [self.HUD showAnimated:TRUE];

        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager POST:activationUrl
           parameters:@{@"grant_type":@"password", @"username": ownerId, @"password": pinCode}
              headers:nil
              progress:nil
               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

                  [self.HUD hideAnimated:YES];

                  NSString *accessToken = [responseObject objectForKey:@"access_token"];
                  [AppHelper saveToken:accessToken];
                  
                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                  [defaults setValue:@"1" forKey:@"ActivationComplete"];
                  [defaults synchronize];
                  
                  if (self.setupInfo)
                  {
                      FinishSetupViewController *finishSetupViewController = [[FinishSetupViewController alloc] initWithNibName:@"FinishSetupViewController" bundle:nil setupInfo:self.setupInfo];
                      
                      UINavigationController *finishSetupNavigationController = [[UINavigationController alloc] initWithRootViewController:finishSetupViewController];
                      
                      finishSetupNavigationController.navigationBar.translucent = YES;
                      finishSetupNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
                      [self presentViewController:finishSetupNavigationController animated:NO completion:nil];
                  }
                  else
                  {
                      UIApplication *application = [UIApplication sharedApplication];
                      AppDelegate *appDelegate = (AppDelegate*)[application delegate];
                      
                      [appDelegate launchInRegularMode];
                  }
              }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
              {
                  [self.HUD hideAnimated:YES];

                  NSLog(@"Error: %@", error);
              }];
        
    }
}

- (void)cancelActivation:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
};

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}

@end
