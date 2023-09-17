//
//  AddRecipientViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 9/14/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyAlbumInfo.h"
#import "ContactsViewController.h"

@class MySetupInfo;

@interface AddRecipientViewController : UITableViewController<ContactUpdateDelegate, MobilePhoneSelectedDelegate, MBProgressHUDDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
            albumInfo:(MyAlbumInfo*)albumInfo parentViewController:(UIViewController*)parentViewController;

@end
