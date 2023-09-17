//
//  ContactDetailViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 7/19/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "ContactDetailViewController.h"
#import "SnagletDataAccess.h"
#import "MyContactInfo.h"
#import "MySetupInfo.h"
#import "SnagletRepository.h"

@interface ContactDetailViewController ()

@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) MySetupInfo *setupInfo;
@property (nonatomic, strong) MyContactInfo *dbContactInfo;

@property (nonatomic, strong) MBProgressHUD *HUD;

@property (nonatomic, assign) bool mobilePhoneNumberSelected;
@property (nonatomic, assign) bool otherPhoneNumberSelected;
@property (nonatomic, assign) BOOL setupMode;

@property (nonatomic, strong) NSString *mobileOtherNumber;
@property (nonatomic, strong) NSString *mobilePhoneNumber;

@end

@implementation ContactDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil contact:(MyContactInfo*)contact albumInfo:(MyAlbumInfo*)albumInfo setupInfo:(MySetupInfo*)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.contact = contact;
        self.albumInfo = albumInfo;
        self.setupInfo = setupInfo;
        self.setupMode = NO;
        if(!albumInfo) {
            self.setupMode = YES;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Select Phone";

    self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.HUD.delegate = self;

    self.imgAvatar.layer.cornerRadius = 24.0f;
    self.imgAvatar.clipsToBounds = YES;

    if (self.setupMode)
    {
        NSString *contactId = self.contact.phoneContactId;
        self.dbContactInfo = [self.setupInfo.contactsInfo objectForKey:contactId];
    }
    else
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
        self.dbContactInfo = [dataAccess getContactByAlbumIdAndPhoneContactId:self.albumInfo.serverId contactId:self.contact.phoneContactId];
    }

    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    //[customButton setImage:[UIImage imageNamed:@"NavArrow-Back"] forState:UIControlStateNormal];
    [customButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(contactDetailBackButtonPressed:)forControlEvents:UIControlEventTouchUpInside];
    customButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -20, 0, 0);
    customButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, -19, 0, 0);
    [customButton sizeToFit];
    
    UIBarButtonItem *contactDetailBackButton = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(saveContact:)];

    self.navigationItem.leftBarButtonItem = contactDetailBackButton;    
    self.navigationItem.rightBarButtonItem = doneButton;
    
    if (![NSString isNilOrEmpty:self.dbContactInfo.otherPhoneNumber])
    {
        self.mobileOtherNumber = self.dbContactInfo.otherPhoneNumber;
        self.otherPhoneNumberSelected = YES;
    }
    else if(![NSString isNilOrEmpty:self.contact.otherPhoneNumber])
    {
        self.mobileOtherNumber = self.contact.otherPhoneNumber;
    }

    if (![NSString isNilOrEmpty:self.dbContactInfo.mobilePhoneNumber])
    {
        self.mobilePhoneNumber = self.dbContactInfo.mobilePhoneNumber;
        self.mobilePhoneNumberSelected = YES;
    }
    else if(![NSString isNilOrEmpty:self.contact.mobilePhoneNumber])
    {
        self.mobilePhoneNumber = self.contact.mobilePhoneNumber;
    }
    
    [self showMobileSelectionStatus];

    [self showiPhoneSelectionStatus];
    
    self.lblDisplayName.text = self.contact.displayName;
    
    if ([NSString isNilOrEmpty:self.mobileOtherNumber])
    {
        [self.btnMobilePhone setTitle:@"phone number not available" forState:UIControlStateNormal];
        [self.btnMobilePhone setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
    else
    {
        [self.btnMobilePhone setTitle:self.mobileOtherNumber forState:UIControlStateNormal];
    }
    
    if ([NSString isNilOrEmpty:self.mobilePhoneNumber])
    {
        [self.btnMobileiPhone setTitle:@"phone number not available" forState:UIControlStateNormal];
        [self.btnMobileiPhone setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
    else
    {
        [self.btnMobileiPhone setTitle:self.mobilePhoneNumber forState:UIControlStateNormal];
;
    }

    UIImage *avatar = [MyContactInfo getImage:self.contact.phoneContactId];
    if (avatar)
    {
        self.imgAvatar.image = avatar;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[SnagletAnalytics sharedSnagletAnalytics] logScreenView:NSStringFromClass(self.class)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)contactDetailBackButtonPressed:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Back"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

-(void)saveContact:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Save Contact"];
    
    if (self.setupMode)
    {
        if (!self.mobilePhoneNumberSelected && !self.otherPhoneNumberSelected)
        {
            self.dbContactInfo.mobilePhoneNumber = @"";
            self.dbContactInfo.otherPhoneNumber = @"";

            [self.mobilePhoneDelegate mobilePhoneDeleted:self.dbContactInfo.phoneContactId success:YES];

            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        
        if (!self.dbContactInfo) {
            self.dbContactInfo = [[MyContactInfo alloc] init];
        }

        //self.dbContactInfo = [[MyContactInfo alloc] init];
        self.dbContactInfo.phoneContactId = self.contact.phoneContactId;
        self.dbContactInfo.albumId = self.albumInfo.Id;
        self.dbContactInfo.displayName = self.contact.displayName;
        self.dbContactInfo.firstName = self.contact.firstName;
        self.dbContactInfo.lastName = self.contact.lastName;
        
        if (!self.otherPhoneNumberSelected)
        {
            self.dbContactInfo.otherPhoneNumber = @"";
        }
        else
        {
            if ([NSString isNilOrEmpty:self.mobileOtherNumber])
            {
                self.dbContactInfo.otherPhoneNumber = @"";
            }
            else
            {
                self.dbContactInfo.otherPhoneNumber = self.mobileOtherNumber;
            }
        }
        
        if (!self.mobilePhoneNumberSelected)
        {
            self.dbContactInfo.mobilePhoneNumber = @"";
        }
        else
        {
            if ([NSString isNilOrEmpty:self.mobilePhoneNumber])
            {
                self.dbContactInfo.mobilePhoneNumber = @"";
            }
            else
            {
                self.dbContactInfo.mobilePhoneNumber = self.mobilePhoneNumber;
            }
        }
        [self.mobilePhoneDelegate mobilePhoneAdded:self.dbContactInfo];
     
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        if(self.dbContactInfo)
        {
            SnagletRepository *repository = [[SnagletRepository alloc] init];
            
            if (!self.mobilePhoneNumberSelected && !self.otherPhoneNumberSelected)
            {
                [self.navigationController.view addSubview:self.HUD];
                [self.HUD showAnimated:YES];
                
                [repository deleteContact:self.albumInfo.serverId contactInfo:self.dbContactInfo
                                  success:^(BOOL success)
                 {
                     [self.mobilePhoneDelegate mobilePhoneDeleted:self.contact.phoneContactId success:YES];

                     [self.HUD hideAnimated:YES];
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
                                  failure:^(NSError *error)
                 {
                     [self.HUD hideAnimated:YES];
                 }];
            }
            else
            {
                if (!self.otherPhoneNumberSelected)
                {
                    self.dbContactInfo.otherPhoneNumber = @"";
                }
                else
                {
                    if ([NSString isNilOrEmpty:self.mobileOtherNumber])
                    {
                        self.dbContactInfo.otherPhoneNumber = @"";
                    }
                    else
                    {
                        self.dbContactInfo.otherPhoneNumber = self.mobileOtherNumber;
                    }
                }
                
                if (!self.mobilePhoneNumberSelected)
                {
                    self.dbContactInfo.mobilePhoneNumber = @"";
                }
                else
                {
                    if ([NSString isNilOrEmpty:self.mobilePhoneNumber])
                    {
                        self.contact.mobilePhoneNumber = @"";
                    }
                    else
                    {
                        self.dbContactInfo.mobilePhoneNumber = self.mobilePhoneNumber;
                    }
                }
                
                [self.navigationController.view addSubview:self.HUD];
                [self.HUD showAnimated:YES];
                
                [repository updateContact:self.albumInfo.serverId contactInfo:self.dbContactInfo
                                  success:^(MyContactInfo *contactInfo)
                 {
                     [self.mobilePhoneDelegate mobilePhoneUpdated:contactInfo];
                     
                     [self.HUD hideAnimated:YES];
                     
                     [self dismissViewControllerAnimated:YES completion:nil];
                     
                 }
                                  failure:^(NSError *error)
                 {
                     [self.HUD hideAnimated:YES];
                 }];
            }
        }
        else
        {
            if (!self.mobilePhoneNumberSelected && !self.otherPhoneNumberSelected)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
            
            if (!self.dbContactInfo) {
                self.dbContactInfo = [[MyContactInfo alloc] init];
            }
            
            self.dbContactInfo.phoneContactId = self.contact.phoneContactId;
            self.dbContactInfo.albumId = self.albumInfo.Id;
            self.dbContactInfo.displayName = self.contact.displayName;
            self.dbContactInfo.firstName = self.contact.firstName;
            self.dbContactInfo.lastName = self.contact.lastName;
            
            if (!self.otherPhoneNumberSelected)
            {
                self.dbContactInfo.otherPhoneNumber = @"";
            }
            else
            {
                if ([NSString isNilOrEmpty:self.mobileOtherNumber])
                {
                    self.dbContactInfo.otherPhoneNumber = @"";
                }
                else
                {
                    self.dbContactInfo.otherPhoneNumber = self.mobileOtherNumber;
                }
            }
            
            if (!self.mobilePhoneNumberSelected)
            {
                self.dbContactInfo.mobilePhoneNumber = @"";
            }
            else
            {
                if ([NSString isNilOrEmpty:self.mobilePhoneNumber])
                {
                    self.contact.mobilePhoneNumber = @"";
                }
                else
                {
                    self.dbContactInfo.mobilePhoneNumber = self.mobilePhoneNumber;
                }
            }
            
            [self.navigationController.view addSubview:self.HUD];
            [self.HUD showAnimated:YES];
            
            SnagletRepository *repository = [[SnagletRepository alloc] init];
            
            [repository addContact:self.albumInfo.serverId contactInfo:self.dbContactInfo
                           success:^(MyContactInfo *contactInfo)
             {
                 [self.mobilePhoneDelegate mobilePhoneAdded:contactInfo];
                 
                 [self.HUD hideAnimated:YES];
                 
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
                           failure:^(NSError *error)
             {
                 [self.HUD hideAnimated:YES];
                 
             }];
        }
    }
}

- (IBAction)mobilePhoneSelected:(id)sender
{
    if (![NSString isNilOrEmpty:self.mobileOtherNumber])
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Phone Selected"];
        
        self.otherPhoneNumberSelected = !self.otherPhoneNumberSelected;
        
        [self showMobileSelectionStatus];
    }
}

- (IBAction)mobileiPhoneSelected:(id)sender
{
    if (![NSString isNilOrEmpty:self.mobilePhoneNumber])
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"iPhone Selected"];

        self.mobilePhoneNumberSelected = !self.mobilePhoneNumberSelected;

        [self showiPhoneSelectionStatus];
    }
}

-(void)showMobileSelectionStatus
{
    if([NSString isNilOrEmpty:self.mobileOtherNumber])
    {
        [self.btnSelectMobile setImage:nil forState:UIControlStateNormal];
        self.btnSelectMobile.hidden = YES;
    }
    else
    {
        UIImage *mobileSelectedStatusImage = self.otherPhoneNumberSelected ? [UIImage imageNamed:@"icon-selected-check"] : [UIImage imageNamed:@"icon-add-plus"];
        
        self.btnSelectMobile.hidden = NO;
        [self.btnSelectMobile setImage:mobileSelectedStatusImage forState:UIControlStateNormal];
    }
}

-(void)showiPhoneSelectionStatus
{
    if ([NSString isNilOrEmpty:self.mobilePhoneNumber])
    {
        [self.btnSelectiPhone setImage:nil forState:UIControlStateNormal];
        self.btnSelectiPhone.hidden = YES;
    }
    else
    {
        UIImage *iPhoneSelectedStatusImage = self.mobilePhoneNumberSelected ? [UIImage imageNamed:@"icon-selected-check"] : [UIImage imageNamed:@"icon-add-plus"];

        self.btnSelectiPhone.hidden = NO;
        [self.btnSelectiPhone setImage:iPhoneSelectedStatusImage forState:UIControlStateNormal];
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
}

@end
