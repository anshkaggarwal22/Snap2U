//
//  VerifyViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VerifyViewController : UIViewController<UITextFieldDelegate, MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnVerify;

@property (weak, nonatomic) IBOutlet UITextField *txtMobilePhone;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (IBAction)verify:(id)sender;

@end
