//
//  ContactsViewController1.m
//  Snaglet
//
//  Created by anshaggarwal on 5/13/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "ContactsViewController.h"
#import "AppDelegate.h"
#import "ContactDetailViewController.h"
#import "ContactTableViewCell.h"
#import "SnagletDataAccess.h"
#import "MySetupInfo.h"
#import "SignupViewController.h"
#import "SetupAlbumManager.h"

@interface ContactsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, copy) NSString *currentSearchString;

@property (nonatomic, strong) NSMutableArray *dbContacts;

@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) MySetupInfo *setupInfo;
@property (nonatomic, assign) BOOL setupMode;

@property (nonatomic, strong) NSMutableDictionary *dictSetupContacts;
@property (nonatomic, strong) MBProgressHUD *HUD;


@end

@implementation ContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo *)albumInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.albumInfo = albumInfo;
        self.navigationItem.title = @"Select Contact(s)";
        self.setupMode = NO;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil setupInfo:(MySetupInfo *)setupInfo
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.setupInfo = setupInfo;
        self.navigationItem.title = @"Select Contact(s)";
        self.setupMode = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    self.HUD.delegate = self;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelContactsCreation:)];
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(completeContactsSelection)];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = nextButton;
    self.tableView.rowHeight = 44;
    
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    self.dbContacts = [dataAccess getAllContacts:self.albumInfo.serverId];
    
    self.contacts = [[NSMutableArray alloc] init];
    [self requestContactAccessIfNeeded];
    
    /*
        
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            // Move the contact retrieval operation to a background thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSArray<CNContact *> *contacts = [self retrieveContactsFromContactStore:contactStore];
                
                NSMutableArray<MyContactInfo *> *mutableContacts = [[NSMutableArray alloc] init];
                for (CNContact *contact in contacts) {
                    MyContactInfo *myContact = [self createContactInfoFromCNContact:contact];
                    [mutableContacts addObject:myContact];
                }
                
                // Perform UI updates on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.contacts = mutableContacts;
                    [self partitionObjects];
                    [self.tableView reloadData];
                });
            });
        }
    }];
    
    [self partitionObjects];
    */
}

- (void)requestContactAccessIfNeeded {
    
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                // Move the contact retrieval operation to a background thread
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSArray<CNContact *> *contacts = [self retrieveContactsFromContactStore:contactStore];
                    
                    NSMutableArray<MyContactInfo *> *mutableContacts = [[NSMutableArray alloc] init];
                    for (CNContact *contact in contacts) {
                        MyContactInfo *myContact = [self createContactInfoFromCNContact:contact];
                        [mutableContacts addObject:myContact];
                    }
                    
                    // Perform UI updates on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.contacts = mutableContacts;
                        [self partitionObjects];
                        [self.tableView reloadData];
                    });
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
        });
    }];
    [self partitionObjects];
}

- (NSArray<CNContact *> *)retrieveContactsFromContactStore:(CNContactStore *)contactStore
{
    NSMutableArray<CNContact *> *contacts = [[NSMutableArray alloc] init];

    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]];
    
    NSError *fetchError;
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&fetchError usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        [contacts addObject:contact];
    }];
    
    if (fetchError) {
        NSLog(@"Error fetching contacts: %@", fetchError.localizedDescription);
    }
    
    return [contacts copy];
}

- (MyContactInfo *)createContactInfoFromCNContact:(CNContact *)contact
{
    MyContactInfo *myContact = [[MyContactInfo alloc] init];
    
    NSString *givenName = contact.givenName;
    NSString *familyName = contact.familyName;

    if (givenName.length > 0 || familyName.length > 0) {
        
        NSString *fullName = [self constructFullNameWithGivenName:givenName familyName:familyName];
        myContact.displayName = fullName;

    } else {
        myContact.displayName = @"No Name";
    }

    myContact.phoneContactId = contact.identifier;
    myContact.firstName = givenName;
    myContact.lastName = familyName;
        
    for (CNLabeledValue<CNPhoneNumber *> *phoneNumber in contact.phoneNumbers) {
        CNPhoneNumber *number = phoneNumber.value;
        NSString *label = phoneNumber.label;
        NSString *phoneNumberString = number.stringValue;

        if ([label isEqualToString:CNLabelPhoneNumberMobile]) {
            myContact.otherPhoneNumber = phoneNumberString;
        }
        if ([label isEqualToString:CNLabelPhoneNumberiPhone]) {
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

    return myContact;
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

#pragma mark - TableView Delegate and DataSource

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.tableView)
    {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        if ([[self.sections objectAtIndex:section] count] > 0)
        {
            return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView)
    {
        return self.sections.count;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (tableView == self.tableView)
    {
        return [[self.sections objectAtIndex:section] count];
    }
    else
    {
        return self.filteredContacts.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"personCellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    ContactTableViewCell *cell = (ContactTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ContactTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    cell.imgContactSelected.hidden = YES;

    MyContactInfo *contact = nil;
    if (tableView == self.tableView)
    {
        contact = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else
    {
        contact = [self.filteredContacts objectAtIndex:indexPath.row];
    }
    
    bool contactExistsInDb = [self isContactSelectedForSnaglet:self.albumInfo.serverId contactId:contact.phoneContactId];

    UIFont *fontBold = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
    
    NSMutableAttributedString *displayName = [[NSMutableAttributedString alloc] initWithString:contact.displayName];

    NSRange lastNameRange = [contact.displayName rangeOfString:@" " options:NSBackwardsSearch];
    if (lastNameRange.location != NSNotFound)
    {
        NSUInteger lastNameLocation = lastNameRange.location + 1;
        NSUInteger lastNameLength = contact.displayName.length - lastNameLocation;
        
        if (lastNameLength > 0)
        {
            NSRange lastNameRange = NSMakeRange(lastNameLocation, lastNameLength);
            [displayName addAttribute:NSFontAttributeName value:fontBold range:lastNameRange];
            cell.lblDisplayName.attributedText = displayName;
        }
        else
        {
            cell.lblDisplayName.text = contact.displayName;
        }
    }
    else
    {
        [displayName addAttribute:NSFontAttributeName value:fontBold range:NSMakeRange(0, contact.displayName.length)];
        cell.lblDisplayName.attributedText = displayName;
    }
    
/*
    NSMutableAttributedString *displayName = [[NSMutableAttributedString alloc]initWithString:contact.displayName];
    
    NSRange lastNameRange = [contact.displayName rangeOfString:@" " options:NSBackwardsSearch];
    if (lastNameRange.location != NSNotFound)
    {
        NSUInteger lastNameLocation = lastNameRange.location + 1;
        NSUInteger lastNameLength = contact.displayName.length - lastNameLocation;
        [displayName addAttribute:NSFontAttributeName value:fontBold range:NSMakeRange(lastNameLocation, lastNameLength)];
        cell.lblDisplayName.attributedText = displayName;
    }
    else
    {
        [displayName addAttribute:NSFontAttributeName value:fontBold range:NSMakeRange(0, contact.displayName.length)];
        cell.lblDisplayName.attributedText = displayName;
    }
 */
    cell.imgContactSelected.hidden = !contactExistsInDb;
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:contact.phoneContactId];
    cell.tag = [uuid.UUIDString hash];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyContactInfo *contact = nil;
    if (tableView == self.tableView)
    {
        contact = [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else
    {
        contact = [self.filteredContacts objectAtIndex:indexPath.row];
    }
    
    ContactDetailViewController *contactDetailViewController = nil;
    
    if (self.albumInfo)
    {
        contactDetailViewController = [[ContactDetailViewController alloc] initWithNibName:@"ContactDetailViewController" bundle:nil contact:contact albumInfo:self.albumInfo setupInfo:nil];
        contactDetailViewController.mobilePhoneDelegate = self;
    }
    else
    {
        contactDetailViewController = [[ContactDetailViewController alloc] initWithNibName:@"ContactDetailViewController" bundle:nil contact:contact albumInfo:nil setupInfo:self.setupInfo];
        contactDetailViewController.mobilePhoneDelegate = self;
    }
    
    UINavigationController *contactDetailNavigationController = [[UINavigationController alloc]  initWithRootViewController:contactDetailViewController];
    contactDetailNavigationController.navigationBar.translucent = NO;
    if (@available(iOS 13.0, *)) {
        contactDetailNavigationController.modalPresentationStyle = UIModalPresentationAutomatic;
    } else {
        contactDetailNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    }

    [self.navigationController presentViewController:contactDetailNavigationController animated:NO completion:nil];
}

#pragma mark - MobilePhoneSelectedDelegate Delegate

-(void)mobilePhoneAdded:(MyContactInfo*)contact
{
    if (!contact || contact.phoneContactId.length == 0) {
        return;
    }

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:contact.phoneContactId];

    ContactTableViewCell *cell = (ContactTableViewCell*)[self.tableView viewWithTag:[uuid.UUIDString hash]];
    cell.imgContactSelected.hidden = ![contact IsPhoneNumberSelected];
    
    NSString *contactId = contact.phoneContactId;
    
    if (self.setupMode)
    {
        MyContactInfo *existingContact = [self.setupInfo.contactsInfo objectForKey:contactId];
        if (!existingContact)
        {
            [self.setupInfo.contactsInfo setObject:contact forKey:contactId];
        }
        else
        {
            [self.setupInfo.contactsInfo setValue:contact forKey:contactId];
        }
    }
    else
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
        self.dbContacts = [dataAccess getAllContacts:self.albumInfo.serverId];
    }
}

-(void)mobilePhoneUpdated:(MyContactInfo*)contact
{
    if (!contact || contact.phoneContactId.length == 0) {
        return;
    }

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:contact.phoneContactId];

    ContactTableViewCell *cell = (ContactTableViewCell*)[self.tableView viewWithTag:[uuid.UUIDString hash]];
    cell.imgContactSelected.hidden = ![contact IsPhoneNumberSelected];

    NSString *contactId = contact.phoneContactId;
    
    if (self.setupMode)
    {
        MyContactInfo *existingContact = [self.setupInfo.contactsInfo objectForKey:contactId];
        if (!existingContact)
        {
            [self.setupInfo.contactsInfo setObject:contact forKey:contactId];
        }
        else
        {
            [self.setupInfo.contactsInfo setValue:contact forKey:contactId];
        }
    }
    else
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
        self.dbContacts = [dataAccess getAllContacts:self.albumInfo.serverId];
    }
}

-(void)mobilePhoneDeleted:(NSString*)phoneContactId success:(BOOL)success
{
    if (!phoneContactId || phoneContactId.length == 0) {
        return;
    }

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:phoneContactId];

    ContactTableViewCell *cell = (ContactTableViewCell*)[self.tableView viewWithTag:[uuid.UUIDString hash]];
    if (cell.imgContactSelected != nil)
    {
        cell.imgContactSelected.hidden = YES;
    }
    
    if (self.setupMode)
    {
        MyContactInfo *existingContact = [self.setupInfo.contactsInfo objectForKey:phoneContactId];
        if (existingContact)
        {
            [self.setupInfo.contactsInfo removeObjectForKey:phoneContactId];
        }
    }
    else
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
        self.dbContacts = [dataAccess getAllContacts:self.albumInfo.serverId];
    }
}

- (void)cancelContactsCreation:(id)sender
{
    [[SnagletAnalytics sharedSnagletAnalytics] logButtonPress:NSStringFromClass(self.class) buttonTitle:@"Cancel"];

    [self dismissViewControllerAnimated:YES completion:nil];
};

-(void)completeContactsSelection
{
    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];
    
    if (!self.setupMode)
    {
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        BOOL setupComplete = [[defaults objectForKey:@"SetupComplete"] boolValue];
        
        if (!setupComplete)
        {
            [defaults setValue:@"1" forKey:@"SetupComplete"];
            [defaults synchronize];
            
            [appDelegate launchInRegularMode];
        }
        else
        {
            [self dismissModalViews];
            [appDelegate refreshAlbumListView];
            
            if (self.contactUpdateDelegate) {
                [self.contactUpdateDelegate refresh];
            }
        }
    }
    else
    {
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        BOOL signupComplete = [[defaults objectForKey:@"SignupComplete"] boolValue];
        BOOL activationComplete = [[defaults objectForKey:@"ActivationComplete"] boolValue];
        
        if (!signupComplete || !activationComplete)
        {
            SignupViewController *signupViewController = [[SignupViewController alloc] initWithNibName:@"SignupViewController" bundle:nil setupInfo:self.setupInfo];
            
            UINavigationController *signupNavigationController = [[UINavigationController alloc] initWithRootViewController:signupViewController];
            
            signupNavigationController.navigationBar.translucent = YES;
            signupNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;

            [self presentViewController:signupNavigationController animated:NO completion:nil];
        }
        else
        {
            UIApplication *application = [UIApplication sharedApplication];
            AppDelegate *appDelegate = (AppDelegate*)[application delegate];
            
            [self.navigationController.view addSubview:self.HUD];
            [self.HUD showAnimated:YES];

            SetupAlbumManager *albumManager = [appDelegate getAlbumManager:self.setupInfo albumManagerDelegate:(id<SetupAlbumManagerDelegate>)self];
            [albumManager setupAlbum];
        }
    }
}

-(void)dismissModalViews
{
    if ([UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController)
    {
        [[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        [self performSelector:@selector(dismissModalViews) withObject:nil afterDelay:0.10];
    }
}

#pragma mark - Private Functions

-(void)partitionObjects
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSUInteger sectionCount = [[collation sectionTitles] count];
    
    NSMutableArray *unsortedSections = [[NSMutableArray alloc] initWithCapacity:sectionCount];
    for (NSUInteger i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    
    NSMutableArray *copyOfContacts = [self.contacts copy];
    for (MyContactInfo *contact in copyOfContacts)
    {
        NSInteger index = [collation sectionForObject:contact collationStringSelector:@selector(displayName)];
        [[unsortedSections objectAtIndex:index] addObject:contact];
    }
    
    NSMutableArray *sortedSections = [[NSMutableArray alloc] initWithCapacity:unsortedSections.count];
    for (NSMutableArray *section in unsortedSections)
    {
        [sortedSections addObject:[collation sortedArrayFromArray:section collationStringSelector:@selector(displayName)]];
    }
    self.sections = sortedSections;
}

- (BOOL)isContactSelectedForSnaglet:(long)albumId contactId:(NSString*)contactId
{
    NSArray<MyContactInfo *> *copyOfContacts = [self.dbContacts copy];
    
    for (MyContactInfo *dbContactInfo in copyOfContacts)
    {
        if ([dbContactInfo.phoneContactId caseInsensitiveCompare:contactId] == NSOrderedSame && dbContactInfo.albumId == albumId)
        {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self.HUD removeFromSuperview];
    self.HUD = nil;
}

#pragma mark - SnagletAlbumManager Delegate

-(void)albumDataInvalid:(MyAlbumInfo *)albumInfo
{
    [self.HUD hideAnimated:YES];
    
    [self dismissModalViews];
}

-(void)albumCreationBegin:(MyAlbumInfo *)albumInfo
{
    NSLog(@"%@", albumInfo.albumName);
}

-(void)albumCreationEnd:(NSError *)error albumInfo:(MyAlbumInfo *)albumInfo
{
    [self.HUD hideAnimated:YES];

    UIApplication *application = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate*)[application delegate];

    [self dismissModalViews];
    [appDelegate refreshAlbumListView];
}

-(void)contactCreationBegin:(MyContactInfo *)contactInfo
{
    NSLog(@"%@", contactInfo.displayName);
}

-(void)contactCreationEnd:(NSError *)error contactInfo:(MyContactInfo *)contactInfo
{
    NSLog(@"%ld - %@", contactInfo.serverId, contactInfo.displayName);
}

@end

