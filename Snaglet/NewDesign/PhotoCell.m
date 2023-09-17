//
//  PhotoCell.m
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "PhotoCell.h"
#import "UIImageView+Snaglet.h"
#import "MyPhotoInfo.h"
#import "UploadProgressInfo.h"

@interface PhotoCell ()

@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation PhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.photoSelected = NO;
        self.showUploadedOverlay = YES;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.photoSelected = NO;
    self.showUploadedOverlay = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)resetForNotification:(BOOL)notify
{
    if (notify)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoUploadBegin:)
                                                     name:@"PhotoUploadBegin"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoUploadProgress:)
                                                     name:@"PhotoUploadProgress"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoUploadComplete:)
                                                     name:@"PhotoUploadComplete"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(photoUploadError:)
                                                     name:@"PhotoUploadError"
                                                   object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setImageURL:(NSURL *)imageURL
{
    if (_imageURL != imageURL)
    {
        _imageURL = imageURL;
        
        if (_imageURL)
        {
            [self.photoImageView snaglet_setImageWithURL:self.imageURL imageSent:self.isPhotoSent placeholderImage:[UIImage imageNamed:@"img-default-album"]];
        }
    }

    if (self.HUD)
    {
        [self.HUD hideAnimated:YES];
        [self.HUD removeFromSuperview];
        self.HUD = nil;
    }
}

- (void)setAsset:(PHAsset *)asset {
    _asset = asset;
    
    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize
                    contentMode:PHImageContentModeAspectFit
                    options:nil
                    resultHandler:^(UIImage *result, NSDictionary *info) {
                    self.photoImageView.image = result;
                    }];

    if (self.HUD) {
        [self.HUD hideAnimated:YES];
        [self.HUD removeFromSuperview];
        self.HUD = nil;
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
}

#pragma mark - File Upload Notifications

- (void)photoUploadBegin:(NSNotification *)notif
{
    if (!self.asset)
        return;
    
    MyPhotoInfo *photoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!photoInfo)
        return;
    
    NSString *assetUrl = self.asset.localIdentifier;
    
    if ([assetUrl compare:photoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        NSLog(@"File Upload Begin %@", assetUrl);

        self.HUD = [MBProgressHUD showHUDAddedTo:self.progressView animated:YES];
        self.HUD.mode = MBProgressHUDModeIndeterminate;
        self.HUD.delegate = self;
        
        self.HUD.contentColor = [UIColor whiteColor];
        self.HUD.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.backgroundView.color = [UIColor clearColor];

        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.color = [UIColor clearColor];
    }
}

- (void)photoUploadProgress:(NSNotification *)notif
{
    if (!self.asset)
        return;
    
    MyPhotoInfo *photoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!photoInfo)
        return;
    
    NSString *percentageComplete = notif.userInfo[@"percentageComplete"];
    
    NSString *assetUrl = self.asset.localIdentifier;
    
    if ([assetUrl compare:photoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (!self.HUD)
        {
            self.HUD = [MBProgressHUD showHUDAddedTo:self.progressView animated:YES];
            self.HUD.mode = MBProgressHUDModeIndeterminate;
            self.HUD.delegate = self;
            
            self.HUD.contentColor = [UIColor whiteColor];
            self.HUD.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
            self.HUD.backgroundView.color = [UIColor clearColor];

            self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
            self.HUD.bezelView.color = [UIColor clearColor];
            
            NSLog(@"File Upload Progress %@", assetUrl);
        }
        
        self.HUD.progress = [percentageComplete doubleValue];
    }
}

- (void)photoUploadComplete:(NSNotification *)notif
{
    if (!self.asset)
        return;
    
    MyPhotoInfo *photoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!photoInfo)
        return;
    
    NSString *assetUrl = self.asset.localIdentifier;

    if ([assetUrl compare:photoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (self.HUD)
        {
            [MBProgressHUD hideHUDForView:self.progressView animated:YES];
        }
        
        UIImageView *overlayImageView = (UIImageView*)[self.photoImageView viewWithTag:100];
        if (overlayImageView)
        {
            [overlayImageView removeFromSuperview];
        }
        
        if (self.showUploadedOverlay)
        {
            overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            overlayImageView.image = [UIImage imageNamed:@"overlay-uploaded"];
            overlayImageView.tag = 100;
            
            [self.photoImageView addSubview:overlayImageView];
        }
    }
}

- (void)photoUploadError:(NSNotification *)notif
{
    if (!self.asset)
        return;
    
    MyPhotoInfo *photoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!photoInfo)
        return;
    
    NSString *assetUrl = self.asset.localIdentifier;
    
    if ([assetUrl compare:photoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (self.HUD)
        {
            [MBProgressHUD hideHUDForView:self.progressView animated:YES];
        }
    }
}

@end
