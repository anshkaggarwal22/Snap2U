//
//  ContactDetailViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 7/19/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactsViewController.h"
#import "MobilePhoneSelectedDelegate.h"

@class MyContactInfo;
@class MyAlbumInfo;
@class MySetupInfo;

@interface ContactDetailViewController : UIViewController<MBProgressHUDDelegate>

@property (strong, nonatomic) MyContactInfo *contact;

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *btnMobilePhone;
@property (weak, nonatomic) IBOutlet UIButton *btnMobileiPhone;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectMobile;
@property (weak, nonatomic) IBOutlet UIImageView *imgMobilePhoneSelection;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectiPhone;
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;

@property (weak, nonatomic) id<MobilePhoneSelectedDelegate> mobilePhoneDelegate;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil contact:(MyContactInfo*)contact albumInfo:(MyAlbumInfo*)albumInfo setupInfo:(MySetupInfo*)setupInfo;

@end
