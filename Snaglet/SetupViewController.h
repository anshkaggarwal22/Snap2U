//
//  SetupViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySetupInfo;

@interface SetupViewController : UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo;

- (IBAction)getStarted:(id)sender;
- (IBAction)alreadyRegisteredUser:(id)sender;

@end
