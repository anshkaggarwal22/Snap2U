//
//  AddRecipientsStepViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyAlbumInfo;
@class MySetupInfo;

@interface AddRecipientsStepViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblDescription;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo *)albumInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo;

- (IBAction)addRecipientsStepContinue:(id)sender;

@end
