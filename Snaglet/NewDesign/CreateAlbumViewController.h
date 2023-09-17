//
//  CreateAlbumViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 9/9/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MySetupInfo;

@interface CreateAlbumViewController : UIViewController<UITextFieldDelegate, MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UITextField *txtAlbumName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo;

@end
