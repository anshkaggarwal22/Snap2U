//
//  SignupViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "VerifyViewController.h"
#import "ActivateAppViewController.h"
#import "AppHelper.h"

@interface VerifyViewController ()

@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation VerifyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Verify Phone";

    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(cancelVerification:)forControlEvents:UIControlEventTouchUpInside];
    [customButton sizeToFit];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;
    
    self.txtMobilePhone.backgroundColor = [UIColor whiteColor];
    self.txtMobilePhone.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.txtMobilePhone.leftViewMode = UITextFieldViewModeAlways;
   
    self.txtMobilePhone.delegate = self;
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

- (void)cancelVerification:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Cancel"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField.tag == 3)
    {
        [self validatePhoneField:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 3)
    {
        NSUInteger length = [self getLength:textField.text];
        
        if(length == 10)
        {
            if(range.length == 0)
                return NO;
        }
        
        if(length == 3)
        {
            NSString *num = [self formatNumber:textField.text];
            textField.text = [NSString stringWithFormat:@"(%@) ",num];
            if(range.length > 0)
                textField.text = [NSString stringWithFormat:@"%@",[num substringToIndex:3]];
        }
        else if(length == 6)
        {
            NSString *num = [self formatNumber:textField.text];
            textField.text = [NSString stringWithFormat:@"(%@) %@-",[num  substringToIndex:3],[num substringFromIndex:3]];
            if(range.length > 0)
                textField.text = [NSString stringWithFormat:@"(%@) %@",[num substringToIndex:3],[num substringFromIndex:3]];
        }
    }
    return YES;
}

-(NSString*)formatNumber:(NSString*)mobileNumber
{
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    NSUInteger length = [mobileNumber length];
    if(length > 10)
    {
        mobileNumber = [mobileNumber substringFromIndex: length-10];
    }
    return mobileNumber;
}

-(NSUInteger)getLength:(NSString*)mobileNumber
{
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
   return [mobileNumber length];
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

-(BOOL)validatePhoneField:(UITextField*)textField
{
    NSString *phoneRegex = @"^(\\([0-9]{3})\\) [0-9]{3}-[0-9]{4}$";
    NSPredicate *phone = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    
    BOOL isValid =[phone evaluateWithObject:textField.text];

    if (!isValid)
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

- (IBAction)verify:(id)sender
{
    if(!self.HUD)
    {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        self.HUD.delegate = self;
    }

    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Verify Phone"];

    [self signupExistingUser];
}

-(void)signupExistingUser
{
    BOOL validMobilePhone = [self validateTextField:self.txtMobilePhone] && [self validatePhoneField:self.txtMobilePhone];

    if(!validMobilePhone)
    {
        [self showInvalidPhoneNumberAlert];
        
        [self.txtMobilePhone becomeFirstResponder];
        return;
    }

    NSString *mobilePhone = self.txtMobilePhone.text;
    NSString *baseUrl = [AppHelper getExistingUserSignupUrl];
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSDictionary *params = @{@"PhoneNumber": mobilePhone};

    [self.navigationController.view addSubview:self.HUD];
    [self.HUD showAnimated:YES];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager POST:url.absoluteString
       parameters:params
          headers:nil
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

              [self.HUD hideAnimated:YES];

              NSString *ownerId = [responseObject objectForKey:@"OwnerId"];
              [AppHelper saveOwnerId:ownerId];
              
              NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
              [defaults setValue:@"1" forKey:@"SignupComplete"];
              [defaults setValue:@"1" forKey:@"SetupComplete"];
              [defaults synchronize];
              
              ActivateAppViewController *activateAppController = [[ActivateAppViewController alloc] initWithNibName:@"ActivateAppViewController" bundle:nil setupInfo:nil];
              
              UINavigationController *activateAppNavigationController = [[UINavigationController alloc] initWithRootViewController:activateAppController];
              activateAppNavigationController.navigationBar.translucent = YES;
              activateAppNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

              [self presentViewController:activateAppNavigationController animated:NO completion:nil];

          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"Error: %@", error);
              [self.HUD hideAnimated:YES];
              
              [self showInvalidAccountAlert];
          }];
}

- (void)showInvalidAccountAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Account Verification Error"
        message:@"User with this phone number does not exist. Please check if your phone number is correct."
        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showInvalidPhoneNumberAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid Phone Number"
        message:@"Please enter a valid US or Canada-based number. Check the format and try again."
        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}

@end
