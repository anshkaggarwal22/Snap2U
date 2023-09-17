//
//  UploadCompleteViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadCompleteViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *btnFinish;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil photoViewController:(UIViewController*)photoViewController;

- (IBAction)finishSetup:(id)sender;

@end
