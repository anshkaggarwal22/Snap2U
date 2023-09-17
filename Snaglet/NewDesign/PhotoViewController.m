//
//  PhotoViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoCell.h"
#import "SnagletManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AddRecipientsStepViewController.h"
#import "SnagletDataAccess.h"
#import "UploadProgressInfo.h"
#import "PhotoFullScreenViewController.h"
#import "AppDelegate.h"
#import "UploadManager.h"
#import "MySetupInfo.h"
#import "UploadCompleteViewController.h"

@interface PhotoViewController ()

@property(nonatomic, strong) NSArray *cameraRollAssets;
@property(nonatomic, strong) MyAlbumInfo *albumInfo;
@property(nonatomic, strong) MySetupInfo *setupInfo;
@property(nonatomic, strong) NSMutableArray *existingAssets;
@property(nonatomic, strong) NSMutableArray *freshAssets;
@property(nonatomic, assign) BOOL setupMode;

@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation PhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo *)albumInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.albumInfo = albumInfo;
        self.freshAssets = [[NSMutableArray alloc] init];
        self.setupMode = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.setupInfo = setupInfo;
        self.freshAssets = [[NSMutableArray alloc] init];
        self.setupMode = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Camera Roll";
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.HUD.delegate = self;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPhotosSelection:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 0.35;
    longPressGesture.delegate = self;
    longPressGesture.delaysTouchesBegan = YES;
    [self.collectionView addGestureRecognizer:longPressGesture];
    
    if (self.setupMode) {
        UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(photosSelectedWhenCreatingAlbum:)];
        
        self.navigationItem.rightBarButtonItem = nextButton;
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoSentNotification:)
                                                     name:@"PhotoSent"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(uploadCompleteNotification:)
                                                     name:@"UploadComplete"
                                                   object:nil];
        
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
        self.existingAssets = [dataAccess getPhotosByAlbumId:self.albumInfo.serverId];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(photosSelectedWhenEditingAlbum:)];
        
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoCell"];
    
    self.cameraRollAssets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    [fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [tmpAssets addObject:asset];
    }];
    
    [tmpAssets sortUsingComparator:^NSComparisonResult(PHAsset * _Nonnull obj1, PHAsset * _Nonnull obj2) {
        return [obj2.creationDate compare:obj1.creationDate];
    }];
    
    self.cameraRollAssets = tmpAssets;
    [self.collectionView reloadData];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    {
        return;
    }
    
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath != nil)
    {
        PhotoCell *cell = (PhotoCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        PHAsset *asset = cell.asset;
        
        NSString *localIdentifier = asset.localIdentifier;
        
        MyPhotoInfo *myPhotoInfo = [self getPhoto:localIdentifier];
        if (!myPhotoInfo)
        {
            myPhotoInfo = [[MyPhotoInfo alloc] init];
            myPhotoInfo.albumId = self.albumInfo.serverId;
            myPhotoInfo.photoUrlOnDevice = localIdentifier;
            myPhotoInfo.dateAdded = [[NSDate date] timeIntervalSince1970];
            myPhotoInfo.asset = asset;
        }
        
        PhotoFullScreenViewController *photoFullScreenViewController = [[PhotoFullScreenViewController alloc] initWithNibName:@"PhotoFullScreenViewController" bundle:nil photoInfo:myPhotoInfo albumInfo:self.albumInfo cellIndex:indexPath.row setupMode:self.setupMode];
        photoFullScreenViewController.delegate = self;
        
        UINavigationController *photoFullScreenNavigationController = [[UINavigationController alloc] initWithRootViewController:photoFullScreenViewController];
        photoFullScreenNavigationController.navigationBar.translucent = NO;
        photoFullScreenNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

        [self presentViewController:photoFullScreenNavigationController animated:NO completion:nil];
    }
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.cameraRollAssets.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    cell.showUploadedOverlay = YES;
    [cell resetForNotification:NO];

    UIImageView *overlayImageView = [cell.contentView viewWithTag:100];
    if (overlayImageView)
    {
        [overlayImageView removeFromSuperview];
    }

    PHAsset *asset = self.cameraRollAssets[indexPath.item];
    cell.asset = asset;
    cell.albumId = self.albumInfo.serverId;
    cell.photoSelected = NO;
    
    NSString *assetIdentifier = asset.localIdentifier;
    MyPhotoInfo *myPhotoInfo = [self getPhoto:assetIdentifier];
    
    if (myPhotoInfo != nil)
    {
        if (myPhotoInfo.isPhotoSent)
        {
            UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
            overlayImageView.image = [UIImage imageNamed:@"overlay-sent"];
            overlayImageView.tag = 100;
            
            [cell.contentView addSubview:overlayImageView];
        }
        else if(myPhotoInfo.serverId > 0)
        {
            UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
            overlayImageView.image = [UIImage imageNamed:@"overlay-uploaded"];
            overlayImageView.tag = 100;
            
            [cell.contentView addSubview:overlayImageView];
        }
    }
    else
    {
        if ([self doesAssetAlreadyExists:asset])
        {
            UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
            overlayImageView.image = [UIImage imageNamed:@"overlay-selected"];
            overlayImageView.tag = 100;
            
            [cell.contentView addSubview:overlayImageView];
            cell.photoSelected = YES;
        }
        else
        {
            UploadManager *uploadManager = [AppDelegate uploadFileManager];
            myPhotoInfo = [uploadManager getAssetBeingUploadedByUrl:self.albumInfo.serverId photoUrlOnDevice:assetIdentifier];
            if (myPhotoInfo)
            {
                [cell resetForNotification:YES];
            }
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = (PhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];

    PHAsset *asset = cell.asset;
    NSString *assetUrl = asset.localIdentifier;

    MyPhotoInfo *myPhotoInfo = [self getPhoto:assetUrl];
    if (!myPhotoInfo) {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        myPhotoInfo = [dataAccess readPhotoByAlbumIdAndUrl:self.albumInfo.serverId url:assetUrl];

        if (!myPhotoInfo) {
            UploadManager *uploadManager = [AppDelegate uploadFileManager];
            myPhotoInfo = [uploadManager getAssetBeingUploadedByUrl:self.albumInfo.serverId photoUrlOnDevice:assetUrl];
            if (myPhotoInfo) {
                return;
            }
        }
    }

    if (myPhotoInfo != nil && (myPhotoInfo.isPhotoSent || myPhotoInfo.serverId > 0)) {
        return;
    }

    if (cell.photoSelected) {
        MyPhotoInfo *myPhotoInfo = [self getNewlySelectedPhoto:assetUrl];
        myPhotoInfo.asset = asset;

        if (myPhotoInfo.serverId <= 0) {
            [self.freshAssets removeObject:myPhotoInfo];
        }

        UIImageView *overlayImageView = (UIImageView *)[cell.photoImageView viewWithTag:100];
        [overlayImageView removeFromSuperview];
        cell.photoSelected = NO;
    } else {
        MyPhotoInfo *myPhotoInfo = [[MyPhotoInfo alloc] init];
        myPhotoInfo.albumId = self.albumInfo.serverId;
        myPhotoInfo.photoUrlOnDevice = assetUrl;
        myPhotoInfo.dateAdded = [[NSDate date] timeIntervalSince1970];
        myPhotoInfo.asset = asset;

        [self.freshAssets addObject:myPhotoInfo];

        UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
        overlayImageView.image = [UIImage imageNamed:@"overlay-selected"];
        overlayImageView.tag = 100;

        [cell.photoImageView addSubview:overlayImageView];
        cell.photoSelected = YES;
    }

    if (!self.setupMode) {
        if ([self.freshAssets count] > 0) {
            self.navigationItem.rightBarButtonItem.title = @"Upload";
        } else {
            self.navigationItem.rightBarButtonItem.title = @"Done";
        }
    }
}

- (void)cancelPhotosSelection:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Cancel"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

- (void)photosSelectedWhenCreatingAlbum:(id)sender
{
    self.setupInfo.photosInfo = [NSArray arrayWithArray:self.freshAssets];
    
    AddRecipientsStepViewController *addRecipientsViewController = [[AddRecipientsStepViewController alloc] initWithNibName:@"AddRecipientsStepViewController" bundle:nil setupInfo:self.setupInfo];
    
    UINavigationController *addRecipientsStepNavigationController = [[UINavigationController alloc] initWithRootViewController:addRecipientsViewController];
    addRecipientsStepNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    addRecipientsStepNavigationController.navigationBar.translucent = YES;

    [self presentViewController:addRecipientsStepNavigationController animated:NO completion:nil];
}

- (void)photosSelectedWhenEditingAlbum:(id)sender {
    NSMutableArray<MyPhotoInfo *> *copyOfFreshAssets = [self.freshAssets mutableCopy];
    long totalCount = [copyOfFreshAssets count];

    if (totalCount > 0) {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Upload Photos"];

        [self.collectionView addSubview:self.HUD];
        [self.HUD showAnimated:YES];

        NSMutableArray<MyPhotoInfo *> *arrPhotos = [[NSMutableArray<MyPhotoInfo *> alloc] init];
        NSMutableArray<MyPhotoInfo *> *arrVideos = [[NSMutableArray<MyPhotoInfo *> alloc] init];

        for (NSUInteger count = 0; count < totalCount; count++) {
            MyPhotoInfo *photoInfo = copyOfFreshAssets[count];
            BOOL isVideo = photoInfo.asset.mediaType == PHAssetMediaTypeVideo;

            if (isVideo) {
                [arrVideos addObject:photoInfo];
            } else {
                [arrPhotos addObject:photoInfo];
            }
        }

        NSDictionary *userInfo = @{@"assetsUploaded": copyOfFreshAssets};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadBegin" object:nil userInfo:userInfo];

        NSUInteger size = 5;

        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

        for (NSUInteger count = 0; count * size < [arrPhotos count]; count++) {
            NSUInteger start = count * size;
            NSRange range = NSMakeRange(start, MIN([arrPhotos count] - start, size));
            NSArray<MyPhotoInfo *> *assetSubArray = [arrPhotos subarrayWithRange:range];

            if ([assetSubArray count] > 0) {

                for (MyPhotoInfo *photoInfo in assetSubArray)
                {
                    SnagletManager *manager = [appDelegate getUploadManager];
                    [manager uploadSnaglets:[NSArray arrayWithObjects:photoInfo, nil] albumId:self.albumInfo.serverId];
                }
            }
        }

        for (NSUInteger count = 0; count < [arrVideos count]; count++) {
            MyPhotoInfo *photoInfo = arrVideos[count];
            SnagletManager *manager = [appDelegate getUploadManager];
            [manager uploadSnaglets:@[photoInfo] albumId:self.albumInfo.serverId];
        }

        [self.freshAssets removeAllObjects];
        [self.HUD hideAnimated:YES];

        UploadCompleteViewController *finishSetupViewController = [[UploadCompleteViewController alloc] initWithNibName:@"UploadCompleteViewController" bundle:nil photoViewController:self];
        UINavigationController *finishSetupNavigationController = [[UINavigationController alloc] initWithRootViewController:finishSetupViewController];
        finishSetupNavigationController.navigationBar.translucent = YES;

        [self.navigationController presentViewController:finishSetupNavigationController animated:NO completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)doesAssetAlreadyExists:(PHAsset *)asset {
    if ([self.freshAssets count] > 0) {
        
        NSMutableArray *copyOfFreshAssets = [self.freshAssets mutableCopy];
        
        for (MyPhotoInfo *photoInfo in copyOfFreshAssets) {
            if([photoInfo.photoUrlOnDevice isEqualToString:asset.localIdentifier]) {
                NSLog(@"Selected Photo %@", asset.localIdentifier);
                return YES;
            }
        }
    }
    return NO;
}

- (MyPhotoInfo *)getPhoto:(NSString *)url {
    NSArray<MyPhotoInfo *> *copyOfExistingAssets = [self.existingAssets copy];
    
    for (MyPhotoInfo *photoInfo in copyOfExistingAssets) {
        if ([photoInfo.photoUrlOnDevice isEqualToString:url]) {
            return photoInfo;
        }
    }
    
    return nil;
}

- (MyPhotoInfo *)getNewlySelectedPhoto:(NSString *)url {
    NSArray<MyPhotoInfo *> *copyOfFreshAssets = [self.freshAssets copy];

    for (MyPhotoInfo *photoInfo in copyOfFreshAssets) {
        if ([photoInfo.photoUrlOnDevice isEqualToString:url]) {
            return photoInfo;
        }
    }
    
    return nil;
}

- (void)uploadCompleteNotification:(NSNotification *)notif
{
    NSLog(@"Upload Completed");
    
    [self.freshAssets removeAllObjects];
    
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    self.existingAssets = [dataAccess getPhotosByAlbumId:self.albumInfo.serverId];

    [self.collectionView reloadData];
}

- (void)photoSentNotification:(NSNotification *)notif {
    NSLog(@"Photo Sent");
    
    NSInteger cellIndex = [notif.userInfo[@"cellIndex"] integerValue];
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:cellIndex inSection:0];
    PhotoCell *photoCell = (PhotoCell *)[self.collectionView cellForItemAtIndexPath:path];
    
    if (photoCell != nil) {
        UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, photoCell.frame.size.width, photoCell.frame.size.height)];
        overlayImageView.image = [UIImage imageNamed:@"overlay-sent"];
        overlayImageView.tag = 100;
        
        [photoCell.photoImageView addSubview:overlayImageView];
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
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
