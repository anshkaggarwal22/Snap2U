//
//  ActivateAppViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySetupInfo;

@interface ActivateAppViewController : UIViewController<UITextFieldDelegate, MBProgressHUDDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo;

@property (weak, nonatomic) IBOutlet UIButton *btnActivate;
@property (weak, nonatomic) IBOutlet UITextField *txtPinCode;

- (IBAction)activateApp:(id)sender;

@end
