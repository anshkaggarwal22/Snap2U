//
//  PhotoFullScreenViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 10/1/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "PhotoFullScreenViewController.h"
#import "SnagletDataAccess.h"
#import "SnagletManager.h"
#import "UIImageView+Snaglet.h"
#import "AppDelegate.h"
#import "SnagletRepository.h"

@interface PhotoFullScreenViewController ()

@property (nonatomic, strong) MyPhotoInfo *photoInfo;

@property (nonatomic, strong) MyAlbumInfo *albumInfo;

@property (nonatomic, strong) SnagletManager *manager;

@property (nonatomic, strong) MBProgressHUD *HUD;

@property (nonatomic, assign) BOOL setupMode;

@end

@implementation PhotoFullScreenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil photoInfo:(MyPhotoInfo*)photoInfo albumInfo:(MyAlbumInfo *)albumInfo cellIndex:(NSInteger)cellIndex setupMode:(BOOL)setupMode
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.photoInfo = [photoInfo copy];
        self.albumInfo = albumInfo;
        self.cellIndex = cellIndex;
        self.setupMode = setupMode;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.setupMode) {
        self.btnSendSms.hidden = YES;
    }
    self.navigationItem.title = @"Photo";

        
    if (self.photoInfo.asset != nil) {
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.networkAccessAllowed = YES;
        CGSize targetSize = CGSizeMake(self.imgPhotoView.bounds.size.width * [UIScreen mainScreen].scale, self.imgPhotoView.bounds.size.height * [UIScreen mainScreen].scale);
        [manager requestImageForAsset:self.photoInfo.asset
                           targetSize:targetSize
                          contentMode:PHImageContentModeAspectFit
                              options:options
                        resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                            self.imgPhotoView.image = result;
                        }];
    }
    else {
        NSString *photoUrl = [self.photoInfo getPhotoUrl];
        if (![NSString isNilOrEmpty:photoUrl]) {
            NSURL *fileUrl = [NSURL URLWithString:photoUrl];
            
            [self.imgPhotoView snaglet_setImageWithURL:fileUrl
                                           imageSent:NO
                                    placeholderImage:nil];
        }
    }
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(goBack:)forControlEvents:UIControlEventTouchUpInside];
    [customButton sizeToFit];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;

    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(removePhoto:)];
    self.navigationItem.rightBarButtonItem = deleteButton;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PhotoUploadBegin"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self photoUploadBegin:note];
                                                    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PhotoUploadProgress"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self photoUploadProgress:note];
                                                    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PhotoUploadComplete"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                    [self photoUploadProgress:note];
                                                    }];
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

- (void)goBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
};

- (void)removePhoto:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Delete Photo"];

    SnagletRepository *repository = [[SnagletRepository alloc] init];

    [self.navigationController.view addSubview:self.HUD];
    [self.HUD showAnimated:YES];

    [repository deletePhoto:self.albumInfo.serverId photoInfo:self.photoInfo
                      success:^(BOOL success)
     {
         [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoDeleted" object:nil userInfo:nil];
         
         [self.HUD hideAnimated:YES];
         [self dismissViewControllerAnimated:YES completion:nil];
     }
     failure:^(NSError *error)
     {
         [self.HUD hideAnimated:YES];
     }];
    
}

- (IBAction)sendPhoto:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Send Snaglet"];

    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];

    self.manager = [appDelegate getUploadManager];
    self.manager.delegate = self;
    
    if (self.photoInfo.serverId > 0)
    {
        [self.manager sendSnagletSmsOnly:self.photoInfo albumId:self.albumInfo.serverId];
    }
    else
    {
        [self.manager uploadAndSendSnaglets:[NSArray arrayWithObjects:self.photoInfo, nil] albumId:self.albumInfo.serverId];
    }
}

-(void)smsNotificationBegin
{
    self.btnSendSms.enabled = NO;
    self.lblProgress.hidden = NO;
    self.lblProgress.text = @"Sending Snap2U...";
}

-(void)UploadSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float percentageComplete = (float)totalBytesSent / (float) totalBytesExpectedToSend;
    
    self.lblProgress.text = [NSString stringWithFormat:@"%.01f%@", percentageComplete * 100, @"%"];
}

-(void)smsNotificationCompleted:(NSError *)error
{
    self.btnSendSms.enabled = YES;
    self.lblProgress.hidden = NO;
    
    if (!error)
    {
        self.lblProgress.text = @"Snap2U was sent";
                
        NSDictionary *sentPhotoInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%ld", self.photoInfo.albumId ], @"albumId",
                                  [NSString stringWithFormat:@"%ld", (long)self.cellIndex ], @"cellIndex",
                                  nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoSent" object:nil userInfo:sentPhotoInfo];
    }
    else
    {
        self.lblProgress.text = @"Failed to send Photo.";
    }
}
 
#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
}

#pragma mark - File Upload Notifications

- (void)photoUploadBegin:(NSNotification *)notif
{
    if (!self.photoInfo.asset)
        return;
    
    MyPhotoInfo *uploadingPhotoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!uploadingPhotoInfo)
        return;
    
    NSString *assetUrl = self.photoInfo.asset.localIdentifier;

    if ([assetUrl compare:uploadingPhotoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
    if (!self.photoInfo.asset)
        return;
    
    MyPhotoInfo *uploadingPhotoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!uploadingPhotoInfo)
        return;
    
    NSString *percentageComplete = notif.userInfo[@"percentageComplete"];
    
    NSString *assetUrl = self.photoInfo.asset.localIdentifier;

    if ([assetUrl compare:uploadingPhotoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (!self.HUD)
        {
            self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.HUD.mode = MBProgressHUDModeIndeterminate;
            self.HUD.delegate = self;
            
            self.HUD.contentColor = [UIColor whiteColor];
            self.HUD.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
            self.HUD.backgroundView.color = [UIColor clearColor];

            self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
            self.HUD.bezelView.color = [UIColor clearColor];
        }
        
        self.HUD.progress = [percentageComplete doubleValue];
    }
}

- (void)photoUploadComplete:(NSNotification *)notif
{
    if (!self.photoInfo.asset)
        return;
    
    MyPhotoInfo *uploadingPhotoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!uploadingPhotoInfo)
        return;
    
    NSString *assetUrl = self.photoInfo.asset.localIdentifier;

    if ([assetUrl compare:uploadingPhotoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (self.HUD)
        {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}

- (void)photoUploadError:(NSNotification *)notif
{
    if (!self.photoInfo.asset)
        return;
    
    MyPhotoInfo *uploadingPhotoInfo = notif.userInfo[@"uploadedPhotoInfo"];
    if (!uploadingPhotoInfo)
        return;
    
    NSString *assetUrl = self.photoInfo.asset.localIdentifier;

    if ([assetUrl compare:uploadingPhotoInfo.photoUrlOnDevice options:NSCaseInsensitiveSearch] == 0)
    {
        if (self.HUD)
        {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }
}

@end
