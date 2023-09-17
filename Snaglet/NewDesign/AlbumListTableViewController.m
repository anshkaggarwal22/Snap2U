//
//  AlbumListTableViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/24/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AlbumListTableViewController.h"
#import "MyPhotoInfo.h"
#import "AlbumInfoCell.h"
#import "CreateNewAlbumCell.h"
#import "SnagletDataAccess.h"
#import "SnagletManager.h"
#import "CreateAlbumViewController.h"
#import "AlbumSetupViewController.h"
#import "AppHelper.h"
#import "SnagletRepository.h"
#include "MySetupInfo.h"
#import "SetupViewController.h"
#import "AppDelegate.h"

@interface AlbumListTableViewController ()

@property (nonatomic, strong) NSMutableArray *albums;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation AlbumListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat headerViewHeight = 44.0;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), headerViewHeight)];

    // Create the image view with an image.
    UIImage *headerImage = [UIImage imageNamed:@"NavBar-Logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:headerImage];

    // Set the content mode of the image view.
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    // Place the image view in the center of the header view.
    //imageView.frame = headerView.bounds;
    imageView.frame = CGRectMake(0, -5, CGRectGetWidth(imageView.frame), CGRectGetHeight(imageView.frame));

    [headerView addSubview:imageView];
    self.navigationItem.titleView = headerView;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Initialize the refresh control.
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:64/255.0 green:101/255.0 blue:214.0/255.0 alpha:1];
    self.refreshControl.tintColor = [UIColor whiteColor];
    
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh" attributes:attrsDictionary];
    self.refreshControl.attributedTitle = attributedTitle;
    
    [self.refreshControl addTarget:self
                            action:@selector(getLatestAlbums)
                  forControlEvents:UIControlEventValueChanged];
 
    self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.hud.delegate = self;

    [self loadAlbumView];

    [self checkPhotoAlbumAccess];
    
    [self refreshAlbumView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoUploadComplete:)
                                                 name:@"PhotoUploadComplete"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoSentNotification:)
                                                 name:@"PhotoSent"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoDeletedNotification:)
                                                 name:@"PhotoDeleted"
                                               object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getLatestAlbums
{
    if (self.refreshControl)
    {
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing Albums..." attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl beginRefreshing];
    }
    
    [self loadAlbums:^(NSMutableArray *albums)
    {
        self.albums = albums;

        MyAlbumInfo *newAlbum = [[MyAlbumInfo alloc] init];
        [self.albums insertObject:newAlbum atIndex:0];

        [self reloadData];
    }
    failure:^(NSError *error)
    {
        if (self.refreshControl)
        {
            [self resetRefreshControl];
        }
    }];
}

-(void)reloadData
{
    // Reload table data
    [self resetRefreshControl];
    
    [self.tableView reloadData];
}

-(void)resetRefreshControl
{
    if (self.refreshControl)
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

-(void)loadAlbums:(void (^)(NSMutableArray *albums))success
                 failure:(void (^)(NSError *error))failure
{
    SnagletRepository *repository = [[SnagletRepository alloc] init];
    
    [repository loadAlbums:^(NSArray *albums) {
        
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        MyPreferences *preferences = [dataAccess getMyPreferences];
        if (preferences == nil)
        {
            preferences = [[MyPreferences alloc] init];
        }
        
        preferences.albumRefreshDate = [[NSDate date] timeIntervalSince1970];
        [dataAccess updateMyPreferences:preferences];
        
        success([dataAccess getMyAlbums]);
        
    }
    failure:^(NSError *error)
    {
        failure(error);
    }];
}

-(void)refreshAlbumView
{
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];
    
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    MyPreferences *preferences = [dataAccess getMyPreferences];
    
    if (preferences != nil && preferences.albumRefreshDate > 0)
    {
        NSTimeInterval duration = [[NSDate dateWithTimeIntervalSince1970:currentTimestamp] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:preferences.albumRefreshDate]];
        
        NSInteger days = ((NSInteger) duration) / (60 * 60 * 24);
        NSInteger hours = (((NSInteger) duration) / (60 * 60)) - (days * 24);
        
        if (hours > 0)
        {
            [self getLatestAlbums];
        }
        else
        {
            if (self.refreshControl)
            {
                [self.refreshControl beginRefreshing];
                [self.refreshControl endRefreshing];
            }
        }
    }
    else
    {
        [self getLatestAlbums];
    }
}

-(void)loadAlbumView
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

    self.albums = [dataAccess getMyAlbums];
    
    MyAlbumInfo *newAlbum = [[MyAlbumInfo alloc] init];
    [self.albums insertObject:newAlbum atIndex:0];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MyAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];
    if (albumInfo.Id <= 0) {
        
        CreateNewAlbumCell *cell = (CreateNewAlbumCell *)[tableView dequeueReusableCellWithIdentifier:@"CreateNewAlbumCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CreateNewAlbumCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            
            [cell.btnCreateNewAlbum addTarget:self
                                       action:@selector(createNewAlbum:)
                             forControlEvents:UIControlEventTouchUpInside];
            
            [cell.btnDeleteAccount addTarget:self
                                       action:@selector(deleteAccount:)
                             forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    } else {
        AlbumInfoCell *cell = (AlbumInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"AlbumCell"];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AlbumInfoCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        MyAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];
        
        cell.lblName.text = albumInfo.albumName;
        
        NSString *photosLabelInfo = [NSString stringWithFormat:@"%zd Photos/videos in queue\n", albumInfo.photosInQueueCount];
        NSString *recipientsLabelInfo = [NSString stringWithFormat:@"%zd Recipients\n", albumInfo.recipientsCount];
        NSString *sendTextLabelInfo = @"Sending @ 7:00 PM CST";
        
        NSString *finalText = [NSString stringWithFormat:@"%@%@%@", photosLabelInfo, recipientsLabelInfo, sendTextLabelInfo];

        NSArray *components = [finalText componentsSeparatedByString:@"\n"];
        NSRange photosLabelRange = [finalText rangeOfString:[components objectAtIndex:0]];
        NSRange recipientsLabelRange = [finalText rangeOfString:[components objectAtIndex:1]];

        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:finalText];
        
        [attrString beginEditing];
        
        if (albumInfo.photosInQueueCount <= 0) {
            [attrString addAttribute: NSForegroundColorAttributeName
                               value:[UIColor redColor]
                               range:photosLabelRange];
        }
        
        if (albumInfo.recipientsCount <= 0) {
            [attrString addAttribute: NSForegroundColorAttributeName
                               value:[UIColor redColor]
                               range:recipientsLabelRange];
        }
        
        [attrString endEditing];
        
        cell.lblPhotoDetails.attributedText = attrString;
        
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        MyPhotoInfo *photoInfo = [dataAccess getFirstPhotoByAlbumId:albumInfo.serverId];
        
        if(photoInfo != nil)
        {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[photoInfo.photoUrlOnDevice] options:nil];
            
            if (fetchResult.count > 0) {
                PHAsset *asset = fetchResult.firstObject;
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.resizeMode = PHImageRequestOptionsResizeModeExact;
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                options.networkAccessAllowed = YES;
                
                [[PHImageManager defaultManager] requestImageForAsset:asset
                                                           targetSize:cell.imgAlbum.frame.size
                                                          contentMode:PHImageContentModeAspectFill
                                                              options:options
                                                        resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                            cell.imgAlbum.image = result;
                                                        }];
            } else {
                cell.imageURL = [NSURL URLWithString:[photoInfo getPhotoUrl]];
            }
        }
        return cell;
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];
    return albumInfo.Id > 0 ? YES: NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        long index = indexPath.row;
        MyAlbumInfo *albumInfo = [self.albums objectAtIndex:index];
        
        if (albumInfo)
        {
            SnagletRepository *repository = [[SnagletRepository alloc] init];
            
            [repository deleteAlbum:albumInfo.serverId
            success:^(BOOL success)
            {
                if (success)
                {
                    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
                    BOOL albumRemoved = [dataAccess removeAlbum:albumInfo.Id];
                    if (albumRemoved)
                    {
                        [self.albums removeObjectAtIndex:index];
                        
                        // Delete the row from the data source
                        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    }
                }
            }
            failure:^(NSError *error)
            {
            }];
        }
    }
}

- (void)checkPhotoAlbumAccess {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            break;
        case PHAuthorizationStatusNotDetermined:
            [self requestPhotoAlbumsAccess];
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Privacy Warning" message:@"Permission was not granted to access Photo Albums." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

- (void)requestPhotoAlbumsAccess
{
    __weak typeof(self) weakSelf = self;

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized:
                    // Access granted
                    [weakSelf loadPhotoAlbums];
                    break;
                    
                case PHAuthorizationStatusDenied:
                case PHAuthorizationStatusRestricted:
                    // Access denied or restricted
                    // Show an alert or some other UI to inform the user
                    break;
                    
                case PHAuthorizationStatusNotDetermined:
                    // Access not determined
                    // User hasn't been asked for permission yet, so don't do anything
                    break;
                case PHAuthorizationStatusLimited:
                    
                    break;
            }
        });
    }];
}

- (void)loadPhotoAlbums
{
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        // Do something with each album collection
    }];
}

- (void)photoUploadComplete:(NSNotification *)notif
{
    [self reloadData];
}

- (void)photoSentNotification:(NSNotification *)notif
{
    [self reloadData];
}

- (void)photoDeletedNotification:(NSNotification *)notif
{
    [self reloadData];
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Create Album"];

        MyAlbumInfo *albumInfo = [self.albums objectAtIndex:indexPath.row];

        AlbumSetupViewController *albumViewController = [[AlbumSetupViewController alloc] initWithNibName:@"AlbumSetupViewController" bundle:nil albumInfo:albumInfo];
    
        [self.navigationController pushViewController:albumViewController animated:YES];
    }
    else
    {
        [self createNewAlbum:nil];
    }
}

-(void)createNewAlbum:(UIButton *)sender
{
    MySetupInfo *setupInfo = [[MySetupInfo alloc] init];
    
    CreateAlbumViewController *createAlbumViewController = [[CreateAlbumViewController alloc] initWithNibName:@"CreateAlbumViewController" bundle:nil setupInfo:setupInfo];
    
    UINavigationController *albumsNavigationController = [[UINavigationController alloc]  initWithRootViewController:createAlbumViewController];
    albumsNavigationController.navigationBar.translucent = NO;
    albumsNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:albumsNavigationController animated:NO completion:nil];
}

-(void)deleteAccount:(UIButton *)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Account"
        message:@"Are you sure you want to delete your account? If you select 'Yes,' Snap2U will permanently delete all your data and registration information."
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        if(self.hud) {
            [self.hud showAnimated:YES];
        }

        // User tapped "Yes" button, proceed with the delete action
        [self deleteMyAccount];
    }];

    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteMyAccount
{
    SnagletRepository *repository = [[SnagletRepository alloc] init];
    
    [repository deleteAccount:^(BOOL success)
    {
        if(self.hud) {
            [self.hud hideAnimated:YES];
        }

        if (success)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentDir = [documentPaths objectAtIndex:0];
            NSString *databasePath = [documentDir stringByAppendingPathComponent:@"Snaglet.db"];

            BOOL success = [fileManager fileExistsAtPath:databasePath];
            if(success) {
                NSError *error = nil;
                [fileManager removeItemAtPath:databasePath error:&error];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setValue:@"0" forKey:@"SignupComplete"];
                [defaults setValue:@"0" forKey:@"SetupComplete"];
                [defaults setValue:@"0" forKey:@"ActivationComplete"];
                [defaults synchronize];

                UIApplication *application = [UIApplication sharedApplication];
                AppDelegate *appDelegate = (AppDelegate*)[application delegate];
                
                [appDelegate createAndCheckDatabase];
                [appDelegate launchInGettingStartedMode];
            }
        }
    }
    failure:^(NSError *error)
    {
        if(self.hud) {
            [self.hud hideAnimated:YES];
        }
    }];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.hud removeFromSuperview];
}

@end
