//
//  FinishSetupViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySetupInfo;

@interface FinishSetupViewController : UIViewController<MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnFinish;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo;

- (IBAction)finishSetup:(id)sender;

@end
