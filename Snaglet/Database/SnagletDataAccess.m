//
//  SnagletDataAccess.m
//  Snaglet
//
//  Created by anshaggarwal on 7/15/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SnagletDataAccess.h"
#import "AppDelegate.h"
#import "FMDatabase.h"
#import "DbHistory.h"
#import "MyPhotoInfo.h"

@implementation SnagletDataAccess

+ (id)sharedSnagletDbAccess
{
    static SnagletDataAccess *sharedSnagletDbAccess = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSnagletDbAccess = [[self alloc] init];
    });
    return sharedSnagletDbAccess;
}

+(NSString *) getDatabasePath
{
    NSString *databasePath = [(AppDelegate *)[[UIApplication sharedApplication] delegate] databasePath];
    
    return databasePath;
}

-(id)init
{
    if (self = [super init]) {
    }
    return self;
}

/*
-(BOOL)insertAlbum:(DbAlbumInfo *)album
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];

    [db open];


    BOOL success =  [db executeUpdate:@"INSERT INTO Albums (AlbumId, Url) VALUES (?, ?);",
                     album.albumId, album.url, nil];

    [db close];

    return success;
}
*/

-(BOOL)insertContact:(MyContactInfo *)contact
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    
    BOOL success =  [db executeUpdate:@"INSERT INTO MyContacts (contactId, album_id, displayName, firstName, lastName, mobilePhone, mobileiPhone, ServerId, created_date, modified_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                     contact.phoneContactId,
                     [NSNumber numberWithLong:contact.albumId],
                     contact.displayName,
                     contact.firstName,
                     contact.lastName,
                     contact.otherPhoneNumber,
                     contact.mobilePhoneNumber,
                     [NSNumber numberWithLong:contact.serverId],
                     [NSNumber numberWithDouble:contact.createdDate],
                     [NSNumber numberWithDouble:contact.modifiedDate]];
    
    [db close];
    
    return success;
}

-(BOOL)insertHistory:(DbHistory *)history
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    
    BOOL success =  [db executeUpdate:@"INSERT INTO History (AlbumId, AlbumUrl, AssetUrl, AssetFileName, ContactId, CloudFileName, DateSentTimeStamp) VALUES (?, ?, ?, ?, ?, ?, ?);",
                     history.albumId, history.albumUrl, history.assetUrl, history.assetFileName,
                     history.contactId, history.cloudFileName,
                     [NSNumber numberWithDouble:history.dateSentTimeStamp]];
    
    [db close];
    
    return success;
}

-(BOOL)removeAlbum:(NSInteger)albumId
{
    BOOL success = NO;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    [db beginTransaction];
    
    @try {
        
        success =  [db executeUpdate:@"DELETE FROM MyContacts WHERE album_id = ?;", [NSNumber numberWithLong:albumId]];
        
        success =  [db executeUpdate:@"DELETE FROM MyPhotos WHERE album_id = ?;",
                         [NSNumber numberWithLong:albumId]];
        
        success =  [db executeUpdate:@"DELETE FROM MyAlbums WHERE Id = ?;",
                         [NSNumber numberWithLong:albumId]];

    }
    @catch (NSException *exception) {
    }
    @finally {
        
        if (success) {
            [db commit];
        }
        else {
            [db rollback];
        }
    }
    [db close];
    
    return success;
}

-(BOOL)removeContact:(NSInteger)serverId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"DELETE FROM MyContacts WHERE serverId=?", [NSNumber numberWithLong:serverId]];
    
    [db close];
    
    return success;
}

-(BOOL)updateContact:(MyContactInfo*)contactInfo
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"UPDATE MyContacts SET displayName='%@', firstName='%@', lastName='%@', mobilePhone='%@', mobileiPhone='%@', created_date=%f, modified_date=%f WHERE ServerId=%ld",
                       contactInfo.displayName,
                       contactInfo.firstName,
                       contactInfo.lastName,
                       contactInfo.otherPhoneNumber,
                       contactInfo.mobilePhoneNumber,
                       contactInfo.createdDate,
                       contactInfo.modifiedDate,
                       contactInfo.serverId];
    
    BOOL success =  [db executeUpdate:query];
    
    [db close];
    
    return success;
}

-(MyPreferences*)getMyPreferences
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM MyPreferences"];
    
    MyPreferences *preferences = nil;
    
    while([results next])
    {
        preferences = [[MyPreferences alloc] init];
        
        preferences.albumRefreshDate = [results doubleForColumn:@"album_refresh_date"];
        
        break;
    }
    
    [db close];
    
    return preferences;
}

-(BOOL)updateMyPreferences:(MyPreferences*)preferences
{
    BOOL success = NO;
    
    NSInteger itemCount = 0;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = @"SELECT COUNT(*) FROM MyPreferences";
    
    FMResultSet *results = [db executeQuery:query];
    
    if([results next])
    {
        itemCount = [results intForColumnIndex: 0];
    }
    
    if (itemCount <= 0)
    {
        success =  [db executeUpdate:@"INSERT INTO MyPreferences (album_refresh_date) VALUES (?);", [NSNumber numberWithDouble:preferences.albumRefreshDate], nil];

    }
    else
    {
        success = [db executeUpdate:@"UPDATE MyPreferences SET album_refresh_date=?",
                         [NSNumber numberWithDouble:preferences.albumRefreshDate]];
    }
    
    [db close];
    
    return success;
    
}

-(NSMutableArray *)getMyAlbums
{
    NSMutableArray *albums = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM MyAlbums order by serverId desc"];
    
    while([results next])
    {
        MyAlbumInfo *album = [[MyAlbumInfo alloc] init];
        
        album.Id = [results intForColumn:@"Id"];
        album.serverId = [results intForColumn:@"serverId"];
        album.albumName = [results stringForColumn:@"album_name"];
        album.createdDate = [results doubleForColumn:@"created_date"];
        album.modifiedDate = [results doubleForColumn:@"modified_date"];
        
        [albums addObject:album];
    }
    
    [db close];
    
    return albums;
}

-(NSMutableArray *)getAllContacts:(NSInteger)albumId;
{
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyContacts Where album_id = %ld", (long)albumId];
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        MyContactInfo *contact = [[MyContactInfo alloc] init];
        
        contact.Id = [results intForColumn:@"Id"];
        contact.serverId = [results intForColumn:@"serverId"];
        contact.phoneContactId = [results stringForColumn:@"contactId"];
        contact.albumId = [results intForColumn:@"album_id"];
        contact.displayName = [results stringForColumn:@"displayName"];
        contact.firstName = [results stringForColumn:@"firstName"];
        contact.lastName = [results stringForColumn:@"lastName"];
        contact.otherPhoneNumber = [results stringForColumn:@"mobilePhone"];
        contact.mobilePhoneNumber = [results stringForColumn:@"mobileiPhone"];
        contact.createdDate = [results doubleForColumn:@"created_date"];
        contact.modifiedDate = [results doubleForColumn:@"modified_date"];

        [contacts addObject:contact];
    }
    
    [db close];
    
    return contacts;
}

-(NSMutableArray *)getMobileOnlyContacts
{
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM MyContacts Where mobilePhone is not null"];
    
    while([results next])
    {
        MyContactInfo *contact = [[MyContactInfo alloc] init];
        
        contact.Id = [results intForColumn:@"Id"];
        contact.phoneContactId = [results stringForColumn:@"contactId"];
        contact.serverId = [results intForColumn:@"serverId"];
        contact.albumId = [results intForColumn:@"album_id"];
        contact.displayName = [results stringForColumn:@"displayName"];
        contact.firstName = [results stringForColumn:@"firstName"];
        contact.lastName = [results stringForColumn:@"lastName"];
        contact.otherPhoneNumber = [results stringForColumn:@"mobilePhone"];
        contact.mobilePhoneNumber = [results stringForColumn:@"mobileiPhone"];
        contact.createdDate = [results doubleForColumn:@"created_date"];
        contact.modifiedDate = [results doubleForColumn:@"modified_date"];

        [contacts addObject:contact];
    }
    
    [db close];
    
    return contacts;
}

-(NSMutableArray *)getHistoryByContactId:(NSInteger)contactId
{
    NSMutableArray *snagletHistory = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM History Where contactId = %zd", contactId];
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        DbHistory *history = [[DbHistory alloc] init];
        
        history.rowId = [results intForColumn:@"Id"];
        history.albumId = [results stringForColumn:@"AlbumId"];
        history.albumUrl = [results stringForColumn:@"AlbumUrl"];
        history.assetUrl = [results stringForColumn:@"AssetUrl"];
        history.assetFileName = [results stringForColumn:@"AssetFileName"];
        history.contactId = [results intForColumn:@"ContactId"];
        history.cloudFileName = [results stringForColumn:@"CloudFileName"];
        history.dateSentTimeStamp = [results doubleForColumn:@"DateSentTimeStamp"];
        
        [snagletHistory addObject:history];
        
    }
    
    [db close];
    
    return snagletHistory;
}

-(BOOL)isAssetDelivered:(NSString*)albumId assetUrl:(NSString *)assetUrl
{
    NSInteger itemCount = 0;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM History Where AlbumId = '%@' And AssetUrl = '%@'", albumId, assetUrl];
    FMResultSet *results = [db executeQuery:query];
    
    if([results next])
    {
        itemCount = [results intForColumnIndex: 0];
    }
    
    [db close];
    return itemCount > 0 ? YES: NO;
}
////////////////////////////////////////////////////////////////////////////

-(BOOL)insertMyAlbum:(MyAlbumInfo *)album
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"INSERT INTO MyAlbums (album_name, created_date, modified_date, serverId) VALUES (?, ?, ?, ?);",
        album.albumName,
        [NSNumber numberWithDouble:album.createdDate],
        [NSNumber numberWithDouble:album.modifiedDate],
        [NSNumber numberWithInteger:album.serverId], nil];
    
    [db close];
    
    return success;
}

-(BOOL)updateMyAlbum:(MyAlbumInfo *)album
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"UPDATE MyAlbums SET album_name='%@', created_date=%f, modified_date=%f WHERE ServerId=%ld",
        album.albumName,
        album.createdDate,
        album.modifiedDate,
        (long)album.serverId];
    
    BOOL success =  [db executeUpdate:query];
    
    [db close];
    
    return success;
    
}

-(MyAlbumInfo*)getAlbum:(NSInteger)albumId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyAlbums Where serverId = %ld", (long)albumId];
    FMResultSet *results = [db executeQuery:query];
    
    MyAlbumInfo *myAlbum = nil;
    
    while([results next])
    {
        myAlbum = [[MyAlbumInfo alloc] init];
        
        myAlbum.Id = [results intForColumn:@"Id"];
        myAlbum.serverId = [results intForColumn:@"serverId"];
        myAlbum.albumName = [results stringForColumn:@"album_name"];
        myAlbum.createdDate = [results doubleForColumn:@"created_date"];
        myAlbum.modifiedDate = [results doubleForColumn:@"modified_date"];
        
        break;
    }
    
    [db close];
    
    return myAlbum;
}

-(NSInteger)getPhotosInQueueCount:(NSInteger)albumId
{
    NSInteger itemCount = 0;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM MyPhotos WHERE album_id = %ld and date_sent <= 0;", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if([results next])
    {
        itemCount = [results intForColumnIndex: 0];
    }
    [db close];
    
    return itemCount;
}

-(NSInteger)getPhotosCount:(NSInteger)albumId
{
    NSInteger itemCount = 0;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM MyPhotos WHERE album_id = %ld;", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if([results next])
    {
        itemCount = [results intForColumnIndex: 0];
    }
    [db close];
    
    return itemCount;
}

-(NSInteger)getRecipientsCount:(NSInteger)albumId
{
    NSInteger itemCount = 0;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM MyContacts WHERE album_id = %ld;", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if([results next])
    {
        itemCount = [results intForColumnIndex: 0];
    }
    [db close];
    
    return itemCount;
}

-(MyContactInfo*)getContact:(NSInteger)contactServerId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyContacts Where serverId = %ld", (long)contactServerId];
    FMResultSet *results = [db executeQuery:query];
    
    MyContactInfo *myContactInfo = nil;
    
    while([results next])
    {
        myContactInfo = [[MyContactInfo alloc] init];
        
        myContactInfo.Id = [results intForColumn:@"Id"];
        myContactInfo.phoneContactId = [results stringForColumn:@"contactId"];
        myContactInfo.serverId = [results intForColumn:@"ServerId"];
        myContactInfo.albumId = [results intForColumn:@"album_id"];
        myContactInfo.displayName = [results stringForColumn:@"displayName"];
        myContactInfo.firstName = [results stringForColumn:@"firstName"];
        myContactInfo.lastName = [results stringForColumn:@"lastName"];
        myContactInfo.mobilePhoneNumber = [results stringForColumn:@"mobileiPhone"];
        myContactInfo.otherPhoneNumber = [results stringForColumn:@"mobilePhone"];
        myContactInfo.createdDate = [results doubleForColumn:@"created_date"];
        myContactInfo.modifiedDate = [results doubleForColumn:@"modified_date"];
        
        break;
    }
    
    [db close];
    
    return myContactInfo;
}

-(MyContactInfo*)getContactByAlbumIdAndPhoneContactId:(NSInteger)albumId contactId:(NSString*)contactId
{
    MyContactInfo *contact = nil;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyContacts Where album_id = %ld and contactid = '%@'", (long)albumId, contactId];
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        contact = [[MyContactInfo alloc] init];
        
        contact.Id = [results intForColumn:@"Id"];
        contact.phoneContactId = [results stringForColumn:@"contactId"];
        contact.serverId = [results intForColumn:@"ServerId"];
        contact.albumId = [results intForColumn:@"album_id"];
        contact.displayName = [results stringForColumn:@"displayName"];
        contact.firstName = [results stringForColumn:@"firstName"];
        contact.lastName = [results stringForColumn:@"lastName"];
        contact.otherPhoneNumber = [results stringForColumn:@"mobilePhone"];
        contact.mobilePhoneNumber = [results stringForColumn:@"mobileiPhone"];
        contact.createdDate = [results doubleForColumn:@"created_date"];
        contact.modifiedDate = [results doubleForColumn:@"modified_date"];
    }
    
    [db close];
    
    return contact;
}

-(MyPhotoInfo*)getFirstPhotoByAlbumId:(NSInteger)albumId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyPhotos Where album_id = %ld", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    MyPhotoInfo *myPhoto = nil;
    
    while([results next])
    {
        myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.serverId = [results intForColumn:@"server_id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.fileName = [results stringForColumn:@"file_name"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.fileUrl = [results stringForColumn:@"file_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        myPhoto.isPhotoSent = [results boolForColumn:@"is_photo_sent"];
        myPhoto.dateSent = [results doubleForColumn:@"date_sent"];
        myPhoto.fileSize = [results doubleForColumn:@"file_size"];
        myPhoto.contentType = [results stringForColumn:@"content_type"];
        myPhoto.thumbnailUrl = [results stringForColumn:@"thumbnail_url"];
        myPhoto.isThumbnailProcessed = [results boolForColumn:@"is_thumbnail_processed"];
        
        break;
    }
    
    [db close];
    
    return myPhoto;
}

-(NSMutableArray*)getPhotosByAlbumId:(NSInteger)albumId
{
    NSMutableArray *photos = [[NSMutableArray alloc] init];

    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyPhotos Where album_id = %ld order by server_id desc", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        MyPhotoInfo *myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.serverId = [results intForColumn:@"server_id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.fileName = [results stringForColumn:@"file_name"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.fileUrl = [results stringForColumn:@"file_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        myPhoto.isPhotoSent = [results boolForColumn:@"is_photo_sent"];
        myPhoto.dateSent = [results doubleForColumn:@"date_sent"];
        myPhoto.fileSize = [results doubleForColumn:@"file_size"];
        myPhoto.contentType = [results stringForColumn:@"content_type"];
        myPhoto.thumbnailUrl = [results stringForColumn:@"thumbnail_url"];
        myPhoto.isThumbnailProcessed = [results boolForColumn:@"is_thumbnail_processed"];

        [photos addObject:myPhoto];
    }
    
    [db close];
    
    return photos;
}

-(BOOL)insertMyPhotoInfo:(MyPhotoInfo *)photo
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"INSERT INTO MyPhotos (album_id, server_id, file_name, phone_photo_url, file_url, date_added, is_photo_sent, date_sent, file_size, content_type, is_thumbnail_processed, thumbnail_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
        [NSNumber numberWithInteger:photo.albumId],
        [NSNumber numberWithInteger:photo.serverId],
        photo.fileName,
        photo.photoUrlOnDevice,
        photo.fileUrl,
        [NSNumber numberWithDouble:photo.dateAdded],
        [NSNumber numberWithBool:photo.isPhotoSent],
        [NSNumber numberWithDouble:photo.dateSent],
        [NSNumber numberWithDouble:photo.fileSize],
        photo.contentType,
        [NSNumber numberWithBool:photo.isThumbnailProcessed],
        photo.thumbnailUrl,
         nil];
    
    [db close];
    
    return success;
}

-(MyPhotoInfo*)getPhotoByServerId:(NSInteger)photoId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyPhotos Where server_id = %ld", (long)photoId];
    FMResultSet *results = [db executeQuery:query];
    
    MyPhotoInfo *myPhoto = nil;
    
    while([results next])
    {
        myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.serverId = [results intForColumn:@"server_id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.fileName = [results stringForColumn:@"file_name"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.fileUrl = [results stringForColumn:@"file_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        myPhoto.isPhotoSent = [results boolForColumn:@"is_photo_sent"];
        myPhoto.dateSent = [results doubleForColumn:@"date_sent"];
        myPhoto.fileSize = [results doubleForColumn:@"file_size"];
        myPhoto.contentType = [results stringForColumn:@"content_type"];
        myPhoto.thumbnailUrl = [results stringForColumn:@"thumbnail_url"];
        myPhoto.isThumbnailProcessed = [results boolForColumn:@"is_thumbnail_processed"];

        break;
    }
    
    [db close];
    
    return myPhoto;
}

-(BOOL)removePhoto:(NSInteger)serverId
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"DELETE FROM MyPhotos WHERE server_id=?", [NSNumber numberWithLong:serverId]];
    
    [db close];
    
    return success;
}

-(BOOL)removePhotoByAlbumIdAndUrl:(NSInteger)albumId url:(NSString *)url
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"DELETE FROM MyPhotos WHERE album_id=? And phone_photo_url=?;", [NSNumber numberWithLong:albumId], url];

    [db close];
    
    return success;
}

-(MyPhotoInfo*)readPhotoByAlbumIdAndUrl:(NSInteger)albumId url:(NSString *)url
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM MyPhotos Where album_id = %ld And phone_photo_url='%@';", (long)albumId, url];
    
    FMResultSet *results = [db executeQuery:query];
    
    MyPhotoInfo *myPhoto = nil;

    while([results next])
    {
        myPhoto = [[MyPhotoInfo alloc] init];
                
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.serverId = [results intForColumn:@"server_id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.fileName = [results stringForColumn:@"file_name"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.fileUrl = [results stringForColumn:@"file_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        myPhoto.isPhotoSent = [results boolForColumn:@"is_photo_sent"];
        myPhoto.dateSent = [results doubleForColumn:@"date_sent"];
        myPhoto.fileSize = [results doubleForColumn:@"file_size"];
        myPhoto.contentType = [results stringForColumn:@"content_type"];
        myPhoto.thumbnailUrl = [results stringForColumn:@"thumbnail_url"];
        myPhoto.isThumbnailProcessed = [results boolForColumn:@"is_thumbnail_processed"];

        break;
    }
    
    [db close];
    
    return myPhoto;
    
}

-(BOOL)updatePhotoSentInfo:(NSInteger)serverId isPhotoSent:(BOOL)isPhotoSent dateSent:(double)dateSent
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"UPDATE MyPhotos SET is_photo_sent=?, date_sent=? WHERE server_id=?", [NSNumber numberWithBool:isPhotoSent],
                     [NSNumber numberWithDouble:dateSent],
                     [NSNumber numberWithLong:serverId]];
    
    [db close];
    
    return success;
}

-(BOOL)insertUploadPhotoProgressInfo:(MyPhotoInfo *)photo
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"INSERT INTO UploadProgress (album_id, phone_photo_url, date_added) VALUES (?, ?, ?);",
                     [NSNumber numberWithInteger:photo.albumId],
                     photo.photoUrlOnDevice,
                     [NSNumber numberWithDouble:photo.dateAdded],
                     nil];
    
    [db close];
    
    return success;
}

-(BOOL)removeUploadPhotoProgressInfo:(NSInteger)albumId url:(NSString *)url
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    BOOL success =  [db executeUpdate:@"DELETE FROM UploadProgress WHERE album_id=? And phone_photo_url=?;", [NSNumber numberWithLong:albumId], url];
    
    [db close];
    
    return success;
}

-(NSMutableArray*)getPhotosBeingUploadedByAlbumId:(NSInteger)albumId
{
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM UploadProgress Where album_id = %ld order by Id desc", (long)albumId];
    
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        MyPhotoInfo *myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        
        [photos addObject:myPhoto];
    }
    
    [db close];
    
    return photos;
}

-(MyPhotoInfo*)getPhotosBeingUploadedByAlbumIdAndPhotoUrl:(NSInteger)albumId url:(NSString*)url
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM UploadProgress Where album_id = %ld And phone_photo_url='%@';", (long)albumId, url];
    
    FMResultSet *results = [db executeQuery:query];
    
    MyPhotoInfo *myPhoto = nil;
    
    while([results next])
    {
        myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        
        break;
    }
    
    [db close];
    
    return myPhoto;
}

-(NSMutableArray*)getPhotosToBeUploaded
{
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM UploadProgress"];
    
    FMResultSet *results = [db executeQuery:query];
    
    while([results next])
    {
        MyPhotoInfo *myPhoto = [[MyPhotoInfo alloc] init];
        
        myPhoto.Id = [results intForColumn:@"Id"];
        myPhoto.albumId = [results intForColumn:@"album_id"];
        myPhoto.photoUrlOnDevice = [results stringForColumn:@"phone_photo_url"];
        myPhoto.dateAdded = [results doubleForColumn:@"date_added"];
        
        [photos addObject:myPhoto];
    }
    
    [db close];
    
    return photos;
}

-(BOOL)createUploadProgressTable
{
    FMDatabase *db = [FMDatabase databaseWithPath:[SnagletDataAccess getDatabasePath]];
    
    [db open];
    
    NSString *query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS UploadProgress(Id integer primary key, album_id integer not null, phone_photo_url varchar(300), date_added numeric not null);"];
    
    BOOL success = [db executeUpdate:query];

    [db close];
    
    return success;
}

@end
