//
//  SelectedPhotosViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SelectedPhotosViewController.h"
#import "SnagletDataAccess.h"
#import "SnagletManager.h"
#import "PhotoCell.h"
#import "PhotoViewController.h"
#import "AppDelegate.h"
#import "PhotoFullScreenViewController.h"
#import "UploadManager.h"
#import <Photos/Photos.h>

@interface SelectedPhotosViewController ()

@property(nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) UIViewController *parentRootViewController;

@end

@implementation SelectedPhotosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo*)albumInfo parentViewController:(UIViewController *)parentViewController
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.albumInfo = albumInfo;
        self.parentRootViewController = parentViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoCell"];

    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

    self.photos = [dataAccess getPhotosByAlbumId:self.albumInfo.serverId];
    
    MyPhotoInfo *photoInfo = [[MyPhotoInfo alloc] init];
    [self.photos insertObject:photoInfo atIndex:0];
    
    UploadManager *uploadManager = [AppDelegate uploadFileManager];
    NSArray *assetsBeingUploaded = [uploadManager getAssetsBeingUploadedByAlbumId:self.albumInfo.serverId];

    [self showFilesBeingUploaded:assetsBeingUploaded];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoSentNotification:)
                                                 name:@"PhotoSent"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoDeletedNotification:)
                                                 name:@"PhotoDeleted"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadBeginNotification:)
                                                 name:@"UploadBegin"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadCompleteNotification:)
                                                 name:@"UploadComplete"
                                               object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.parentRootViewController.navigationItem.rightBarButtonItem = nil;
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

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (PHAsset *)assetExists:(NSString *)assetUrl {
    __block PHAsset *existingAsset = nil;
    
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetUrl] options:nil];
    if (result.count > 0) {
        existingAsset = [result firstObject];
    }
    return existingAsset;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MyPhotoInfo *photoInfo = self.photos[indexPath.item];
    
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    cell.showUploadedOverlay = NO;
    cell.tag = photoInfo.serverId;
    [cell resetForNotification:NO];
    cell.albumId = self.albumInfo.serverId;

    UIImageView *overlayImageView = (UIImageView*)[cell.photoImageView viewWithTag:100];
    if (overlayImageView != nil)
    {
        [overlayImageView removeFromSuperview];
    }
    
    if (photoInfo != nil)
    {
        if (photoInfo.Id <= 0 && indexPath.row == 0 && indexPath.item == 0)
        {
            cell.photoImageView.image = [UIImage imageNamed:@"AddBox-PlusOnly"];
        }
        else
        {
            [cell resetForNotification:!photoInfo.isPhotoSent];

            cell.imageURL = nil;
            
            PHAsset *asset = [self assetExists:photoInfo.photoUrlOnDevice];
            
            if (asset)
            {
                cell.asset = asset;

                if (photoInfo.isPhotoSent)
                {
                    UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
                    overlayImageView.image = [UIImage imageNamed:@"overlay-sent"];
                    overlayImageView.tag = 100;
                    
                    [cell.photoImageView addSubview:overlayImageView];
                }
            }
            else
            {
                cell.isPhotoSent = photoInfo.isPhotoSent;
                cell.imageURL = [NSURL URLWithString:[photoInfo getPhotoUrl]];
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MyPhotoInfo *photoInfo = self.photos[indexPath.item];
    
    if (photoInfo.Id <= 0 && indexPath.row == 0) {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Add Photo"];

        PhotoViewController *photoViewController = [[PhotoViewController alloc] initWithNibName:@"PhotoViewController" bundle:nil albumInfo:self.albumInfo];
        photoViewController.delegate = self;
        
        UINavigationController *photosNavigationController = [[UINavigationController alloc] initWithRootViewController:photoViewController];
        photosNavigationController.navigationBar.translucent = NO;
        if (@available(iOS 13.0, *)) {
            photosNavigationController.modalPresentationStyle = UIModalPresentationAutomatic;
        } else {
            photosNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        }

        [self.parentRootViewController presentViewController:photosNavigationController animated:NO completion:nil];
    } else {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"View Existing Photo"];

        if (photoInfo.serverId <= 0) {
            return;
        }
        
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[photoInfo.photoUrlOnDevice] options:nil];
        PHAsset *asset = result.firstObject;
        
        if (asset) {
            photoInfo.asset = asset;
            
            PhotoFullScreenViewController *photoFullScreenViewController = [[PhotoFullScreenViewController alloc] initWithNibName:@"PhotoFullScreenViewController" bundle:nil photoInfo:photoInfo albumInfo:self.albumInfo cellIndex:indexPath.row setupMode:NO];
            photoFullScreenViewController.delegate = self;
            
            UINavigationController *photoFullScreenNavigationController = [[UINavigationController alloc] initWithRootViewController:photoFullScreenViewController];
            photoFullScreenNavigationController.navigationBar.translucent = NO;
            photoFullScreenNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

            [self.parentRootViewController presentViewController:photoFullScreenNavigationController animated:NO completion:nil];
        } else {
            PhotoFullScreenViewController *photoFullScreenViewController = [[PhotoFullScreenViewController alloc] initWithNibName:@"PhotoFullScreenViewController" bundle:nil photoInfo:photoInfo albumInfo:self.albumInfo cellIndex:indexPath.row setupMode:NO];
            photoFullScreenViewController.delegate = self;
            
            UINavigationController *photoFullScreenNavigationController = [[UINavigationController alloc] initWithRootViewController:photoFullScreenViewController];
            photoFullScreenNavigationController.navigationBar.translucent = NO;
            photoFullScreenNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

            [self.parentRootViewController presentViewController:photoFullScreenNavigationController animated:NO completion:nil];
        }
    }
}

- (void)uploadBeginNotification:(NSNotification *)notif
{
    NSArray *assetsToBeUploaded = notif.userInfo[@"assetsUploaded"];
    [self showFilesBeingUploaded:assetsToBeUploaded];
}

- (void)uploadCompleteNotification:(NSNotification *)notif
{
    BOOL sendSnaglet = [notif.userInfo[@"sendSnaglet"] boolValue];

    if (!sendSnaglet)
    {
        UploadManager *uploadManager = [AppDelegate uploadFileManager];
        NSArray *assetsBeingUploaded = [uploadManager getAssetsBeingUploadedByAlbumId:self.albumInfo.serverId];
        
        if ([assetsBeingUploaded count] <= 0)
        {
            [self refresh];
        }
    }
}

- (void)photoSentNotification:(NSNotification *)notif
{    
    [self refresh];
}

- (void)photoDeletedNotification:(NSNotification *)notif
{
    [self refresh];
}

-(void)showFilesBeingUploaded:(NSArray*)assetsBeingUploaded
{
    if ([assetsBeingUploaded count] > 0)
    {
        [self.collectionView performBatchUpdates:^{

            NSRange range = NSMakeRange(1, [assetsBeingUploaded count]);
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];

            [self.photos insertObjects:assetsBeingUploaded atIndexes:indexSet];

            NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
            
            for (NSUInteger i = 1; i < assetsBeingUploaded.count + 1; i++)
                [arrayWithIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
            
            [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
        } completion:nil];
    }
    
}

#pragma mark - PhotoSelectionUpdateDelegate implementation

-(void)refresh
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    self.photos = [dataAccess getPhotosByAlbumId:self.albumInfo.serverId];
    
    MyPhotoInfo *photoInfo = [[MyPhotoInfo alloc] init];
    [self.photos insertObject:photoInfo atIndex:0];
    
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    [self.collectionView reloadData];
    [UIView setAnimationsEnabled:animationsEnabled];
    
    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];
    
    [appDelegate refreshAlbumListView];
}

#pragma mark - PhotoSentDelegate implementation

-(void)photoSent:(long)albumId cellIndex:(NSInteger)cellIndex
{    
    NSIndexPath *path = [NSIndexPath indexPathForRow:cellIndex inSection:0];
    PhotoCell *photoCell = (PhotoCell*)[self.collectionView cellForItemAtIndexPath:path];

    if(photoCell != nil)
    {
        UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, photoCell.frame.size.width, photoCell.frame.size.height)];
        overlayImageView.image = [UIImage imageNamed:@"overlay-sent"];
        overlayImageView.tag = 100;
        
        [photoCell.photoImageView addSubview:overlayImageView];
    }
}

@end
