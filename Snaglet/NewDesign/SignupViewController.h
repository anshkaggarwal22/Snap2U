//
//  SignupViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySetupInfo;

@interface SignupViewController : UIViewController<UITextFieldDelegate, MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnSignup;

@property (weak, nonatomic) IBOutlet UITextField *txtFirstName;
@property (weak, nonatomic) IBOutlet UITextField *txtLastName;
@property (weak, nonatomic) IBOutlet UITextField *txtMobilePhone;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo;

- (IBAction)signUp:(id)sender;
- (IBAction)privacyPolicy:(id)sender;
- (IBAction)termsAndConditions:(id)sender;

@end
