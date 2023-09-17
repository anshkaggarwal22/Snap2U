//
//  AddRecipientsStepViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 4/30/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AddRecipientsStepViewController.h"
#import "ContactsViewController.h"
#import "MySetupInfo.h"

@interface AddRecipientsStepViewController ()

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) MySetupInfo *setupInfo;

@end

@implementation AddRecipientsStepViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo *)albumInfo;
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.albumInfo = albumInfo;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo;
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
    
    self.navigationItem.title = @"Add Recipients";

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

- (IBAction)addRecipientsStepContinue:(id)sender
{
    self.overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.overlayView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:self.overlayView];
    
    [self checkAddressBookAccess];
}

- (void)checkAddressBookAccess
{
    CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    
    switch (authorizationStatus) {
        case CNAuthorizationStatusAuthorized:
            [self requestAddressBookAccess];
            break;
            
        case CNAuthorizationStatusNotDetermined:
            [self requestAddressBookAccess];
            break;
            
        case CNAuthorizationStatusDenied:
        case CNAuthorizationStatusRestricted:
        {
            [self requestAddressBookAccess];
            /*
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Privacy Warning"
                message:@"Permission was not granted for Contacts."
                preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
             */
        }
            break;
            
        default:
            break;
    }
}

- (void)requestAddressBookAccess
{
    __weak typeof(self) weakSelf = self;

    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf accessGrantedForAddressBook];
            });
        } else {
            // Handle case when the user denied access
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Contact Access Denied"
                message:@"Please enable contact access in Settings to use this feature."
                preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
                if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
                    [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
                }
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
            style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:settingsAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

-(void)accessGrantedForAddressBook
{
    [self.overlayView removeFromSuperview];
    
    ContactsViewController *contactsViewController = nil;
    if (self.albumInfo)
    {
        contactsViewController = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil albumInfo:self.albumInfo];
    }
    else
    {
        contactsViewController = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil setupInfo:self.setupInfo];
    }
    
    UINavigationController *contactsNavigationController = [[UINavigationController alloc]  initWithRootViewController:contactsViewController];
    contactsNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    contactsNavigationController.navigationBar.translucent = NO;

    [self presentViewController:contactsNavigationController animated:NO completion:nil];
}

- (void)cancelSignup:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
