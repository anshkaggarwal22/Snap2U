//
//  ContactsViewController1.h
//  Snaglet
//
//  Created by anshaggarwal on 5/13/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobilePhoneSelectedDelegate.h"
#import "SetupAlbumManager.h"

@class MyAlbumInfo;
@class MySetupInfo;

@protocol ContactUpdateDelegate <NSObject>

-(void)refresh;

@end

@interface ContactsViewController : UIViewController <UINavigationControllerDelegate,  MobilePhoneSelectedDelegate, SetupAlbumManagerDelegate, MBProgressHUDDelegate>

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo*)albumInfo;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo;

@property (nonatomic, weak) id<ContactUpdateDelegate> contactUpdateDelegate;

@end
