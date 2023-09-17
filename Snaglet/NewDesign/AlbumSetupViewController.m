//
//  AlbumSetupViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/9/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AlbumSetupViewController.h"
#import "AddRecipientViewController.h"
#import "SelectedPhotosViewController.h"
#import "SnagletDataAccess.h"

@interface AlbumSetupViewController ()

@property (nonatomic, strong) MyAlbumInfo *albumInfo;

@end

@implementation AlbumSetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo*)albumInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.albumInfo = albumInfo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.albumInfo.albumName;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.navigationController.navigationBar.translucent = NO;
    self.tabBarController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.tabBarController.edgesForExtendedLayout = UIRectEdgeAll;
    
    UIViewController *photoViewController = [[SelectedPhotosViewController alloc] initWithNibName:@"SelectedPhotosViewController" bundle:nil albumInfo:self.albumInfo parentViewController:self];
    
    photoViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Photos" image:nil selectedImage:nil];
    [photoViewController.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -10)];
    
    UIViewController *addRecipientViewController = [[AddRecipientViewController alloc] initWithNibName:@"AddRecipientViewController" bundle:nil albumInfo:self.albumInfo parentViewController:self];
    
    addRecipientViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Recipients" image:nil selectedImage:nil];
    [addRecipientViewController.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -10)];    

    self.tabBarController.viewControllers = @[photoViewController, addRecipientViewController];
    self.tabBarController.selectedIndex = 0;

    [self.view addSubview:self.tabBarController.view];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];

    [self updatePhotosTabTitle];
    [self updateRecipientsTabTitle];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updatePhotosTabTitle
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    NSInteger photoCount = [dataAccess getPhotosCount:self.albumInfo.serverId];
    
    NSString *photosTabTitle = [NSString stringWithFormat:@"Photos (%zd)", photoCount];
    
    UIViewController *photoViewController = [self.tabBarController.viewControllers objectAtIndex:0];
    [photoViewController.tabBarItem setTitle:photosTabTitle];
}

-(void)updateRecipientsTabTitle
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    NSInteger recipientCount = [dataAccess getRecipientsCount:self.albumInfo.serverId];
    
    NSString *recipientsTabTitle = [NSString stringWithFormat:@"Recipients (%zd)", recipientCount];

    UIViewController *recipientViewController = [self.tabBarController.viewControllers objectAtIndex:1];
    [recipientViewController.tabBarItem setTitle:recipientsTabTitle];
}

@end
