//
//  AppDelegate.m
//  Snaglet
//
//  Created by anshaggarwal on 4/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AppDelegate.h"
#import "SignupViewController.h"
#import "SetupViewController.h"
#import "ActivateAppViewController.h"
#import "ContactsViewController.h"
#import "AlbumListTableViewController.h"
#import "CreateAlbumStepViewController.h"
#import "SnagletRepository.h"

#import "MyPhotoInfo.h"
#import "SnagletDataAccess.h"
#import "AppHelper.h"
#import "SnagletManager.h"
#import "UploadManager.h"
#import "MySetupInfo.h"
#import "SetupAlbumManager.h"
#import <Fabric/Fabric.h>
#import "Reachability.h"
#import "NotificationDelegate.h"

@interface AppDelegate ()

@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) NotificationDelegate *notificationDelegate;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (@available(iOS 13.0, *))
    {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundImage = [UIImage imageNamed:@"NavBar-Bg-Full"];
        
        NSDictionary *largeTitleTextAttributes = @{
            NSForegroundColorAttributeName : [UIColor whiteColor],
            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:34.0]
        };
        appearance.largeTitleTextAttributes = largeTitleTextAttributes;

        // Set the title text attributes
        NSDictionary *titleTextAttributes = @{
            NSForegroundColorAttributeName : [UIColor whiteColor],
            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
        };
        appearance.titleTextAttributes = titleTextAttributes;
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [UINavigationBar appearance].standardAppearance = appearance;
        [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    }
    else
    {
        UIImage *backgroundImage = [UIImage imageNamed:@"NavBar-Bg-Full"];
        [[UINavigationBar appearance] setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
        
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        
        [[UINavigationBar appearance] setTitleTextAttributes:@{
            NSForegroundColorAttributeName : [UIColor whiteColor],
            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0]
        }];

        // Set the large title text attributes
        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{
            NSForegroundColorAttributeName : [UIColor whiteColor],
            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:34.0]
        }];
    }
    
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"NavArrow-Back"]];

    // Set NavigationBar Button Color & Font
    NSDictionary *disabledAttributes = @{
        NSForegroundColorAttributeName: [UIColor lightGrayColor],
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]
    };

    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]]
        setTitleTextAttributes:disabledAttributes
        forState:UIControlStateDisabled];
    
    NSDictionary *normalAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0]
    };

    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]]
        setTitleTextAttributes:normalAttributes
        forState:UIControlStateNormal];
    
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:64/255.0 green:101/255.0 blue:214.0/255.0 alpha:1]];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica Neue" size:16.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    application.statusBarStyle = UIStatusBarStyleLightContent;

    self.databaseName = @"Snaglet.db";
    self.setupInfo = [[MySetupInfo alloc] init];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    self.databasePath = [documentDir stringByAppendingPathComponent:self.databaseName];
    
    [self createAndCheckDatabase];
    
    self.snagletInternetReachable = [Reachability reachabilityWithHostName:@"www.apple.com"];
    
    __weak typeof(self) weakSelf = self;

    self.snagletInternetReachable.reachableBlock = ^(Reachability *reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf)
            {
                SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
                
                NSMutableArray *assetsToBeUploaded = [dataAccess getPhotosToBeUploaded];
                
                if ([assetsToBeUploaded count] > 0)
                {
                    UIApplication *application = [UIApplication sharedApplication];
                    AppDelegate *appDelegate = (AppDelegate*)[application delegate];

                    for (MyPhotoInfo *photoInfo in assetsToBeUploaded)
                    {
                        SnagletManager *manager = [appDelegate getUploadManager];
                        [manager uploadSnaglets:[NSArray arrayWithObjects:photoInfo, nil] albumId:photoInfo.albumId];
                    }
                }
            }
        });
    };
    
    self.snagletInternetReachable.unreachableBlock = ^(Reachability *reachability)
    {
    };
    
    [self.snagletInternetReachable startNotifier];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    BOOL signupComplete = [[defaults objectForKey:@"SignupComplete"] boolValue];
    BOOL activationComplete = [[defaults objectForKey:@"ActivationComplete"] boolValue];
    
    if (!signupComplete || !activationComplete)
    {
        [self launchInGettingStartedMode];
    }
    else
    {
        [self launchInRegularMode];
    }

    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Did Register for Remote Notifications with Device Token (%@)", deviceToken);
    
    NSString *existingToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceToken"];
    
    NSString *newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"My token is: %@", newToken);
    
    if ([newToken compare:existingToken options:NSCaseInsensitiveSearch] != 0)
    {
        // Call API to register the newToken
        SnagletRepository *repository = [[SnagletRepository alloc] init];
        
        [repository updateDeviceToken:newToken oldToken:existingToken success:^(NSString *deviceToken)
        {
            if(![NSString isNilOrEmpty:deviceToken])
            {
                [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"deviceToken"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        failure:^(NSError *error)
        {
            
        }];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Did Fail to Register for Remote Notifications");
    NSLog(@"%@, %@", error, error.localizedDescription);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Below code will make sure that app continues to run for certian amount of time
    
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    NSMutableArray *assetsToBeUploaded = [dataAccess getPhotosToBeUploaded];
    
    if ([assetsToBeUploaded count] > 0)
    {
        self.bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [application endBackgroundTask:self.bgTask];
                self.bgTask = UIBackgroundTaskInvalid;
            });
        }];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)launchInGettingStartedMode
{
    if (!self.window)
    {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    
    SetupViewController *setupViewController = [[SetupViewController alloc] initWithNibName:@"SetupViewController" bundle:nil setupInfo:self.setupInfo];
    
    UINavigationController *setupNavigationController = [[UINavigationController alloc] initWithRootViewController:setupViewController];
    setupNavigationController.navigationBarHidden = YES;
    
    self.window.rootViewController = setupNavigationController;
    [self.window makeKeyAndVisible];
}

-(void)launchInRegularMode
{
    if (!self.window)
    {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    
    self.notificationDelegate = [[NotificationDelegate alloc] init];

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [UNUserNotificationCenter currentNotificationCenter].delegate = self.notificationDelegate;

    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];

    UIViewController *albumListViewController = [[AlbumListTableViewController alloc] initWithNibName:@"AlbumListTableViewController" bundle:[NSBundle mainBundle]];

    UINavigationController *albumNavigationViewController = [[UINavigationController alloc] initWithRootViewController:albumListViewController];
    albumNavigationViewController.navigationBar.translucent = NO;

    self.window.rootViewController = albumNavigationViewController;
    
    [self.window makeKeyAndVisible];
}

-(void)refreshAlbumListView
{
    UINavigationController *albumNavigationViewController = (UINavigationController*)self.window.rootViewController;
    
    AlbumListTableViewController *albumListViewController = (AlbumListTableViewController*)[albumNavigationViewController.viewControllers firstObject];
    
    [albumListViewController loadAlbumView];
}

- (void)createAndCheckDatabase
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager fileExistsAtPath:self.databasePath];

    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    if(success)
    {
        NSString* appVersion = [userDefaults stringForKey:@"SnagletVersion"];
        
        if ([NSString isNilOrEmpty:appVersion])
        {
            SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
            [dataAccess createUploadProgressTable];
            
            [userDefaults setObject:@"1.1" forKey:@"SnagletVersion"];
            [userDefaults synchronize];
        }
        return;
    }
    
    NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseName];
    
    [fileManager copyItemAtPath:databasePathFromApp toPath:self.databasePath error:nil];

    [userDefaults setObject:@"1.1" forKey:@"SnagletVersion"];
    [userDefaults synchronize];}

-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    self.sessionCompletionHandler = completionHandler;
    
    NSDictionary *userInfo = @{@"sessionIdentifier": identifier,
                               @"completionHandler": completionHandler};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BackgroundSessionUpdated"
                                                        object:nil
                                                      userInfo:userInfo];
}

-(SnagletManager*)getUploadManager
{
    return [[SnagletManager alloc] initWithUploadManager:[AppDelegate uploadFileManager]];
}

-(SetupAlbumManager*)getAlbumManager:(MySetupInfo*)setupInfo albumManagerDelegate:(id<SetupAlbumManagerDelegate>)albumManagerDelegate
{
    SetupAlbumManager *albumManager = [[SetupAlbumManager alloc] initWithSetupInfo:setupInfo];
    albumManager.delegate = albumManagerDelegate;
    return albumManager;
}

+ (UploadManager *)uploadFileManager
{
    static dispatch_once_t pred = 0;
    static UploadManager *manager = nil;
    dispatch_once(&pred, ^{
        manager = [[UploadManager alloc] init];
    });
    return manager;
}


@end
