//
//  AddRecipientViewController.m
//  Snaglet
//
//  Created by anshaggarwal on 9/14/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AddRecipientViewController.h"
#import "SnagletDataAccess.h"
#import "AddNewContactViewCell.h"
#import "ContactInfoCell.h"
#import "ContactDetailViewController.h"
#import "AppDelegate.h"
#import "SnagletRepository.h"
#import "MySetupInfo.h"
#import "AlbumSetupViewController.h"

@interface AddRecipientViewController ()

@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) NSMutableArray *recipients;
@property (nonatomic, strong) UIViewController *parentRootViewController;
@property (nonatomic, assign) BOOL contactDeleted;
@property (nonatomic, assign) BOOL editModeOn;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItem;

@end

@implementation AddRecipientViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
            albumInfo:(MyAlbumInfo*)albumInfo parentViewController:(UIViewController *)parentViewController
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

    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    self.hud.delegate = self;
    
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    self.recipients = [dataAccess getAllContacts:self.albumInfo.serverId];

    MyContactInfo *contactInfo = [[MyContactInfo alloc] init];
    [self.recipients insertObject:contactInfo atIndex:0];

    self.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(toggleEdit)];
    
    [self checkAddressBookAccess];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.parentRootViewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)toggleEdit
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    self.editModeOn = [self.tableView isEditing];
    
    if (self.tableView.editing)
    {
        [self.parentRootViewController.navigationItem.rightBarButtonItem setTitle:@"Done"];
    }
    else
    {
        [self.parentRootViewController.navigationItem.rightBarButtonItem setTitle:@"Edit"];
        if (self.contactDeleted)
        {
            UIApplication *application = [UIApplication sharedApplication];
            AppDelegate *appDelegate = (AppDelegate*)[application delegate];
            
            [appDelegate refreshAlbumListView];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recipients.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row <= 0)
    {
        [self addNewRecipient:nil];
    }
    else
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"View Recipient"];

        MyContactInfo *contactInfo = self.recipients[indexPath.row];

        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error)
         {
            if (granted)
            {
                NSPredicate *predicate = [CNContact predicateForContactsMatchingName:contactInfo.displayName];
                
                NSError *fetchError;
                NSArray<CNContact *> *contacts = [contactStore unifiedContactsMatchingPredicate:predicate keysToFetch:@[CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] error:&fetchError];

                if (contacts.count > 0)
                {
                    CNContact *contact = contacts.firstObject;
                    NSString *givenName = contact.givenName;
                    NSString *familyName = contact.familyName;
                    
                    if (givenName.length > 0 || familyName.length > 0)
                    {
                        MyContactInfo *myContact = [[MyContactInfo alloc] init];
                        NSString *fullName = [self constructFullNameWithGivenName:givenName familyName:familyName];
                        myContact.displayName = fullName;

                        myContact.phoneContactId = contactInfo.phoneContactId;
                        myContact.firstName = givenName;
                        myContact.lastName = familyName;
                        
                        for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers)
                        {
                            CNPhoneNumber *number = phoneNumber.value;
                            NSString *label = phoneNumber.label;
                            NSString *phoneNumberString = number.stringValue;

                            if ([label isEqualToString:CNLabelPhoneNumberMobile])
                            {
                                myContact.otherPhoneNumber = phoneNumberString;
                            }

                            if ([label isEqualToString:CNLabelPhoneNumberiPhone])
                            {
                                myContact.mobilePhoneNumber = phoneNumberString;
                            }
                        }
                        
                        if ((myContact.otherPhoneNumber == nil || myContact.otherPhoneNumber.length == 0) &&
                            (myContact.mobilePhoneNumber == nil || myContact.mobilePhoneNumber.length == 0)) {
                            for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers) {
                                CNPhoneNumber *number = phoneNumber.value;
                                NSString *label = phoneNumber.label;
                                NSString *phoneNumberString = number.stringValue;

                                if ([label isEqualToString:CNLabelPhoneNumberMain]) {
                                    myContact.mobilePhoneNumber = phoneNumberString;
                                }
                            }
                        }
                        
                        ContactDetailViewController *contactDetailViewController = nil;
                        contactDetailViewController = [[ContactDetailViewController alloc] initWithNibName:@"ContactDetailViewController" bundle:nil contact:myContact albumInfo:self.albumInfo setupInfo:nil];
                        contactDetailViewController.mobilePhoneDelegate = self;
                        
                        UINavigationController *contactDetailNavigationController = [[UINavigationController alloc] initWithRootViewController:contactDetailViewController];
                        contactDetailNavigationController.navigationBar.translucent = NO;
                        if (@available(iOS 13.0, *)) {
                            contactDetailNavigationController.modalPresentationStyle = UIModalPresentationAutomatic;
                        } else {
                            contactDetailNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
                        }

                        
                        [self.parentRootViewController presentViewController:contactDetailNavigationController animated:NO completion:nil];
                    }
                }
            } else {
                NSLog(@"Access to Contacts denied");
            }
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyContactInfo *contactInfo = [self.recipients objectAtIndex:indexPath.row];
    
    if (contactInfo.Id <= 0)
    {
        AddNewContactViewCell *cell = (AddNewContactViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddNewContactViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddNewContactViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            
            [cell.btnAddNewRecipient addTarget:self
                                       action:@selector(addNewRecipient:)
                             forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else
    {
        ContactInfoCell *cell = (ContactInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ContactInfoCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        cell.lblDisplayName.text = contactInfo.displayName;
        
        UIImage *avatar = [MyContactInfo getImage:contactInfo.phoneContactId];
        if (avatar)
        {
            cell.imgContact.image = avatar;
        }

        if (contactInfo.otherPhoneNumber != nil && contactInfo.otherPhoneNumber.length > 0
            && contactInfo.mobilePhoneNumber != nil && contactInfo.mobilePhoneNumber.length > 0)
        {
            cell.lblPhone.hidden = NO;
            cell.lblPhone2.hidden = NO;
            
            cell.lblPhone.text = [NSString stringWithFormat:@"Mobile %@", contactInfo.otherPhoneNumber];
            cell.lblPhone2.text = [NSString stringWithFormat:@"iPhone %@", contactInfo.mobilePhoneNumber];
            
        }
        else
        {
            [cell.lblPhone2 removeFromSuperview];

            if (contactInfo.otherPhoneNumber != nil && contactInfo.otherPhoneNumber.length > 0)
            {
                cell.lblPhone.hidden = NO;
                cell.lblPhone.text = [NSString stringWithFormat:@"Mobile %@", contactInfo.otherPhoneNumber];
            }
            
            if (contactInfo.mobilePhoneNumber != nil && contactInfo.mobilePhoneNumber.length > 0)
            {
                cell.lblPhone.hidden = NO;
                cell.lblPhone.text = [NSString stringWithFormat:@"iPhone %@", contactInfo.mobilePhoneNumber];
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
    MyContactInfo *contactInfo = [self.recipients objectAtIndex:indexPath.row];
    return contactInfo.Id > 0 ? YES: NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Delete Recipient"];

        MyContactInfo *contactInfo = [self.recipients objectAtIndex:indexPath.row];
        if (contactInfo != nil)
        {
            [self.view addSubview:self.hud];
            [self.hud showAnimated:YES];

            SnagletRepository *repository = [[SnagletRepository alloc] init];
            
            [repository deleteContact:self.albumInfo.serverId contactInfo:contactInfo
                              success:^(BOOL success)
             {
                 [self.hud hideAnimated:YES];

                 if (!self.editModeOn)
                 {
                     [self.recipients removeObjectAtIndex:indexPath.row];
                     
                     // Delete the row from the data source
                     [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                     
                     UIApplication *application = [UIApplication sharedApplication];
                     AppDelegate *appDelegate = (AppDelegate*)[application delegate];
                     
                     [appDelegate refreshAlbumListView];
                 }
                 else
                 {
                     self.contactDeleted = YES;
                     
                     [self.recipients removeObjectAtIndex:indexPath.row];
                     
                     // Delete the row from the data source
                     [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                 }
                 
                 if ([self.parentRootViewController isKindOfClass:[AlbumSetupViewController class]])
                 {
                     AlbumSetupViewController *setupViewController = (AlbumSetupViewController *)self.parentRootViewController;
                     
                     [setupViewController updateRecipientsTabTitle];
                 }
                 //[self.HUD hideAnimated:NO];
             }
             failure:^(NSError *error)
             {
                 //[self.HUD hideAnimated:NO];
             }];
        }
    }
}

-(void)addNewRecipient:(UIButton *)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Add New Recipient"];

    ContactsViewController *contactsViewController = nil;
    contactsViewController = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil albumInfo:self.albumInfo];
    
    UINavigationController *contactsNavigationController = [[UINavigationController alloc]  initWithRootViewController:contactsViewController];
    contactsNavigationController.navigationBar.translucent = NO;
    contactsViewController.contactUpdateDelegate = self;
    if (@available(iOS 13.0, *)) {
        contactsNavigationController.modalPresentationStyle = UIModalPresentationAutomatic;
    } else {
        contactsNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    }

    [self.parentRootViewController presentViewController:contactsNavigationController animated:NO completion:nil];
}

-(void)refresh
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    self.recipients = [dataAccess getAllContacts:self.albumInfo.serverId];
    
    MyContactInfo *contactInfo = [[MyContactInfo alloc] init];
    [self.recipients insertObject:contactInfo atIndex:0];

    [self.tableView reloadData];
}

- (void)checkAddressBookAccess
{
    CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    
    switch (authorizationStatus) {
        case CNAuthorizationStatusAuthorized:
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
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
        } else {
            // Handle error here if needed
        }
    }];

}

- (NSString *)constructFullNameWithGivenName:(NSString *)givenName familyName:(NSString *)familyName {
    NSMutableString *fullName = [[NSMutableString alloc] init];
    
    if (givenName.length > 0) {
        [fullName appendString:givenName];
    }
    
    if (familyName.length > 0) {
        if (fullName.length > 0) {
            [fullName appendString:@" "];
        }
        [fullName appendString:familyName];
    }
    
    return [fullName copy];
}

#pragma mark - MobilePhoneSelectedDelegate Delegate

-(void)mobilePhoneAdded:(MyContactInfo*)contact
{
    [self refresh];
}

-(void)mobilePhoneUpdated:(MyContactInfo*)contact
{
    [self refresh];
}

-(void)mobilePhoneDeleted:(NSString*)phoneContactId success:(BOOL)success
{
    [self refresh];
    
    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];
    
    [appDelegate refreshAlbumListView];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.hud removeFromSuperview];
}

@end
