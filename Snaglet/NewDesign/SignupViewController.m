//
//  SignupViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SignupViewController.h"
#import "ActivateAppViewController.h"
#import "AppHelper.h"
#import "MySetupInfo.h"
#import "AgreementViewController.h"

@interface SignupViewController ()

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation SignupViewController

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
    
    self.navigationItem.title = @"Sign Up";

    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(cancelSignup:)forControlEvents:UIControlEventTouchUpInside];
    customButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -20, 0, 0);
    customButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -19, 0, 0);
    [customButton sizeToFit];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.txtFirstName.frame.size.height - 0.5, self.txtFirstName.frame.size.width, 0.5f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.txtFirstName.layer addSublayer:bottomBorder];
    
    self.txtFirstName.backgroundColor = [UIColor whiteColor];
    self.txtFirstName.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.txtFirstName.leftViewMode = UITextFieldViewModeAlways;
    self.txtFirstName.delegate = self;

    [self.txtFirstName addTarget:self action:@selector(checkFirstNameField:) forControlEvents:UIControlEventEditingChanged];

    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.txtLastName.frame.size.height - 0.5, self.txtLastName.frame.size.width, 0.5f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.txtLastName.layer addSublayer:bottomBorder];
    
    self.txtLastName.backgroundColor = [UIColor whiteColor];
    self.txtLastName.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.txtLastName.leftViewMode = UITextFieldViewModeAlways;
    self.txtLastName.delegate = self;
    
    [self.txtLastName addTarget:self action:@selector(checkLastNameField:) forControlEvents:UIControlEventEditingChanged];

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

- (void)checkFirstNameField:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    NSString *firstName = textField.text;
    
    if(firstName.length > 0)
    {
        textField.text = [NSString stringWithFormat:@"%@%@",[[firstName substringToIndex:1] uppercaseString],[firstName substringFromIndex:1] ];
    }
}

- (void)checkLastNameField:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    NSString *lastName = textField.text;
    
    if(lastName.length > 0)
    {
        textField.text = [NSString stringWithFormat:@"%@%@",[[lastName substringToIndex:1] uppercaseString],[lastName substringFromIndex:1] ];
    }
}

- (void)cancelSignup:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Cancel"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField.tag == 1 || textField.tag == 2)
    {
        [self validateTextField:textField];
    }
    else if(textField.tag == 3)
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

- (IBAction)signUp:(id)sender
{
    if(!self.HUD)
    {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        self.HUD.delegate = self;
    }

    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Signup New User"];

    [self signupNewUser];
}

- (IBAction)privacyPolicy:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Privacy Policy"];

    NSString* agreementFile = [[NSBundle mainBundle] pathForResource:@"Snaglet_Privacy_Policy" ofType:@"pdf"];

    AgreementViewController *agreementViewController = [[AgreementViewController alloc] initWithNibName:@"AgreementViewController" bundle:nil title:@"Privacy Policy" agreementFile:agreementFile];
    
    UINavigationController *agreementNavigationController = [[UINavigationController alloc] initWithRootViewController:agreementViewController];
    agreementNavigationController.navigationBar.translucent = NO;

    [self.navigationController presentViewController:agreementNavigationController animated:NO completion:nil];
}

- (IBAction)termsAndConditions:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Terms & Conditions"];

    NSString* agreementFile = [[NSBundle mainBundle] pathForResource:@"Snaglet_Terms_Conditions" ofType:@"pdf"];
    
    AgreementViewController *agreementViewController = [[AgreementViewController alloc] initWithNibName:@"AgreementViewController" bundle:nil title:@"Terms & Conditions" agreementFile:agreementFile];
    
    UINavigationController *agreementNavigationController = [[UINavigationController alloc] initWithRootViewController:agreementViewController];
    agreementNavigationController.navigationBar.translucent = NO;

    [self.navigationController presentViewController:agreementNavigationController animated:NO completion:nil];
}

-(void)signupNewUser
{
    BOOL validFirstName = [self validateTextField:self.txtFirstName];
    BOOL validLastName = [self validateTextField:self.txtLastName];
    BOOL validMobilePhone = [self validateTextField:self.txtMobilePhone] && [self validatePhoneField:self.txtMobilePhone];
    
    if(!validFirstName)
    {
        [self showFirstNameRequiredAlert];
        
        [self.txtFirstName becomeFirstResponder];
        return;
    }
    
    if(!validLastName)
    {
        [self showLastNameRequiredAlert];

        [self.txtLastName becomeFirstResponder];
        return;
    }
    
    if(!validMobilePhone)
    {
        [self showInvalidPhoneNumberAlert];

        [self.txtMobilePhone becomeFirstResponder];
        return;
    }
    
    NSString *firstName = self.txtFirstName.text;
    NSString *lastName = self.txtLastName.text;
    NSString *mobilePhone = self.txtMobilePhone.text;
    
    NSString *baseUrl = [AppHelper getNewUserSignupUrl];
    
    [self.navigationController.view addSubview:self.HUD];
    [self.HUD showAnimated:YES];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:baseUrl
       parameters:@{@"FirstName": firstName, @"LastName": lastName, @"PhoneNumber": mobilePhone}
         headers:nil
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              [self.HUD hideAnimated:YES];
              
              NSString *ownerId = [responseObject objectForKey:@"OwnerId"];
              [AppHelper saveOwnerId:ownerId];
              
              NSString *userAlreadyExists = [responseObject objectForKey:@"IsNewUser"];
              
              NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
              [defaults setValue:@"1" forKey:@"SignupComplete"];
              
              if ([userAlreadyExists boolValue])
              {
                  [defaults setValue:@"1" forKey:@"SetupComplete"];
              }
              [defaults synchronize];
              
              ActivateAppViewController *activateAppController = [[ActivateAppViewController alloc] initWithNibName:@"ActivateAppViewController" bundle:nil setupInfo:self.setupInfo];
              
              UINavigationController *activateAppNavigationController = [[UINavigationController alloc] initWithRootViewController:activateAppController];
              activateAppNavigationController.navigationBar.translucent = YES;
              activateAppNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

              [self presentViewController:activateAppNavigationController animated:NO completion:nil];
              
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
          {
              [self.HUD hideAnimated:YES];
              NSLog(@"Error: %@", error);
          }];
}

- (void)showInvalidPhoneNumberAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid Phone Number"
        message:@"Please enter a valid US or Canada-based number. Check the format and try again."
        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFirstNameRequiredAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"First Name Required"
        message:@"Please enter your First Name. This field is required."
        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showLastNameRequiredAlert {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Last Name Required"
        message:@"Please enter your Last Name. This field is required."
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
