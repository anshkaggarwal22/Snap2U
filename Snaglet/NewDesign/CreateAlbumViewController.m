//
//  CreateAlbumViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/9/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "CreateAlbumViewController.h"
#import "AddPhotosStepViewController.h"
#import "PhotoViewController.h"
#import "SnagletDataAccess.h"
#import "SnagletRepository.h"
#import "MySetupInfo.h"

@interface CreateAlbumViewController ()

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MySetupInfo *setupInfo;
@property(nonatomic, assign) BOOL setupMode;

@end

@implementation CreateAlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo*)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.setupInfo = setupInfo;
        self.setupMode = setupInfo != nil ? YES : NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.HUD.delegate = self;

    self.navigationItem.title = @"Create Album";

    [self.txtAlbumName addTarget:self action:@selector(checkAlbumNameField:) forControlEvents:UIControlEventEditingChanged];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAlbumCreation:)];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(createAlbum:)];

    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = nextButton;
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    [self.txtAlbumName becomeFirstResponder];
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

- (void)cancelAlbumCreation:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
};

- (void)checkAlbumNameField:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    NSString *albumName = textField.text;
    
    if(albumName.length > 0)
    {
        textField.text = [NSString stringWithFormat:@"%@%@",[[albumName substringToIndex:1] uppercaseString],[albumName substringFromIndex:1] ];
    }
}

- (void)createAlbum:(id)sender
{
    if (!self.setupMode)
    {
        [self.navigationController.view addSubview:self.HUD];
        [self.HUD showAnimated:YES];
        
        SnagletRepository *repository = [[SnagletRepository alloc] init];
        
        NSString *albumName = self.txtAlbumName.text;
        
        [repository createAlbum:albumName
                        success:^(MyAlbumInfo *album)
         {
             [self.HUD hideAnimated:YES];
             
             AddPhotosStepViewController *addPhotosStepViewController = [[AddPhotosStepViewController alloc] initWithNibName:@"AddPhotosStepViewController" bundle:nil albumInfo:album];
             
             UINavigationController *addPhotosStepNavigationController = [[UINavigationController alloc] initWithRootViewController:addPhotosStepViewController];
             
             addPhotosStepNavigationController.navigationBar.translucent = YES;

             [self presentViewController:addPhotosStepNavigationController animated:NO completion:nil];
         }
                        failure:^(NSError *error)
         {
             [self.HUD hideAnimated:YES];
         }];
    }
    else
    {
        MyAlbumInfo *album = [[MyAlbumInfo alloc] init];
        album.albumName = self.txtAlbumName.text;

        self.setupInfo.albumInfo = album;

        AddPhotosStepViewController *addPhotosStepViewController = [[AddPhotosStepViewController alloc] initWithNibName:@"AddPhotosStepViewController" bundle:nil setupInfo:self.setupInfo];
        
        UINavigationController *addPhotosStepNavigationController = [[UINavigationController alloc] initWithRootViewController:addPhotosStepViewController];
        addPhotosStepNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

        addPhotosStepNavigationController.navigationBar.translucent = YES;

        [self presentViewController:addPhotosStepNavigationController animated:NO completion:nil];
    }
};

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString * albumName = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (albumName.length > 0 && ![albumName isEqualToString:@""])
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    return YES;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}

@end
