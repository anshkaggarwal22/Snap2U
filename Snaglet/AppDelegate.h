//
//  AppDelegate.h
//  Snaglet
//
//  Created by anshaggarwal on 4/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SetupAlbumManager.h"

@class SnagletManager;
@class UploadManager;
@class MySetupInfo;
@class SetupAlbumManager;
@class Reachability;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@property (strong, nonatomic) NSString *databaseName;
@property (strong, nonatomic) NSString *databasePath;

@property (copy) void (^sessionCompletionHandler)(void);

@property (strong, nonatomic) MySetupInfo *setupInfo;

@property (strong, nonatomic) Reachability *snagletInternetReachable;

-(void)launchInGettingStartedMode;

-(void)launchInRegularMode;

-(void)refreshAlbumListView;

- (void)createAndCheckDatabase;

-(SnagletManager*)getUploadManager;

+ (UploadManager *)uploadFileManager;

-(SetupAlbumManager*)getAlbumManager:(MySetupInfo*)setupInfo albumManagerDelegate:(id<SetupAlbumManagerDelegate>)albumManagerDelegate;

@end
