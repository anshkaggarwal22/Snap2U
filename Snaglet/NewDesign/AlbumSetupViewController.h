//
//  AlbumSetupViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 9/9/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyAlbumInfo.h"

@interface AlbumSetupViewController : UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo*)albumInfo;

@property (strong, nonatomic) UITabBarController *tabBarController;

-(void)updatePhotosTabTitle;
-(void)updateRecipientsTabTitle;

@end
