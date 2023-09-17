//
//  AddPhotosStepViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AddPhotosStepViewController.h"
#import "PhotoViewController.h"
#import "MySetupInfo.h"
#import <Photos/Photos.h>

@interface AddPhotosStepViewController ()

@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) MyAlbumInfo *albumInfo;

@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation AddPhotosStepViewController

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.setupInfo = setupInfo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    [customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Back" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(cancelSignup:)forControlEvents:UIControlEventTouchUpInside];
    [customButton sizeToFit];
    
    self.navigationItem.title = @"Add Images";

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    self.navigationItem.leftBarButtonItem = backButton;
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

- (IBAction)addPhotosStepContinue:(id)sender
{
    self.overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.overlayView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:self.overlayView];
    
    [self checkPhotoAlbumAccess];
}

- (void)checkPhotoAlbumAccess {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusAuthorized:
            [self accessGrantedForPhotoAlbums];
            break;
        case PHAuthorizationStatusNotDetermined:
            [self requestPhotoAlbumsAccess];
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Privacy Warning" message:@"Permission was not granted to access Photo Albums." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.overlayView removeFromSuperview];
            }];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

-(void)accessGrantedForPhotoAlbums
{
    [self.overlayView removeFromSuperview];

    PhotoViewController *photoViewController = nil;
    
    if (self.albumInfo)
    {
        photoViewController = [[PhotoViewController alloc] initWithNibName:@"PhotoViewController" bundle:nil albumInfo:self.albumInfo];
    }
    else
    {
        photoViewController = [[PhotoViewController alloc] initWithNibName:@"PhotoViewController" bundle:nil setupInfo:self.setupInfo];
    }
    
    UINavigationController *photosNavigationController = [[UINavigationController alloc] initWithRootViewController:photoViewController];
    photosNavigationController.navigationBar.translucent = NO;
    photosNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:photosNavigationController animated:NO completion:nil];
}

- (void)requestPhotoAlbumsAccess {
    __weak typeof(self) weakSelf = self;
        
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized:
                    [weakSelf accessGrantedForPhotoAlbums];
                    break;
                case PHAuthorizationStatusNotDetermined:
                    // Should never get here because we requested authorization
                    break;
                case PHAuthorizationStatusDenied:
                case PHAuthorizationStatusRestricted:
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Privacy Warning" message:@"Permission was not granted to access Photo Albums." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [weakSelf.overlayView removeFromSuperview];
                    }];
                    [alert addAction:okAction];
                    [weakSelf presentViewController:alert animated:YES completion:nil];
                }
                    break;
                default:
                    break;
            }
        });
    }];
}

- (void)cancelSignup:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
};

@end
