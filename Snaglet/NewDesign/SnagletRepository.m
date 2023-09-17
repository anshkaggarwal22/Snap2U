//
//  SnagletRepository.m
//  Snaglet
//
//  Created by anshaggarwal on 1/25/15.
//  Copyright (c) 2015 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SnagletRepository.h"
#import "AppHelper.h"
#import "MyAlbumInfo.h"
#import "MyPhotoInfo.h"
#import "SnagletDataAccess.h"
#import "UserDeviceToken.h"

@implementation SnagletRepository

-(void)loadAlbums:(void (^)(NSArray *albums))success
          failure:(void (^)(NSError *error))failure
{
    NSString *albumsUrl = [AppHelper getMyAlbumsUrl];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager GET:albumsUrl
          parameters:nil
             headers:nil
            progress:nil
             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             
            NSArray *arrJsonAlbums = [[NSArray alloc] initWithArray:responseObject];

            SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
             
            NSMutableArray *myAlbums = [dataAccess getMyAlbums];
             
            for (MyAlbumInfo *myAlbumInfo in myAlbums)
            {
                long myAlbumServerId = myAlbumInfo.serverId;

                BOOL albumFound = NO;
                
                for (int count = 0; count < [arrJsonAlbums count]; count++)
                {
                    id albumObject = [arrJsonAlbums objectAtIndex:count];

                    long serverId = [[albumObject objectForKey:@"Id"] integerValue];

                    if (myAlbumServerId == serverId)
                    {
                        albumFound = YES;
                        break;
                    }
                }
                
                if (!albumFound)
                {
                    [dataAccess removeAlbum:myAlbumInfo.Id];
                }
            }

            NSMutableArray *albums = [[NSMutableArray alloc] init];

            for (int count = 0; count < [arrJsonAlbums count]; count++)
            {
                id albumObject = [arrJsonAlbums objectAtIndex:count];

                long serverId = [[albumObject objectForKey:@"Id"] integerValue];

                NSString *albumName = [albumObject objectForKey:@"Name"];

                double createdDate = [[albumObject objectForKey:@"CreatedDate"] doubleValue];
                double modifiedDate = [[albumObject objectForKey:@"ModifiedDate"] doubleValue];

                MyAlbumInfo *dbAlbumInfo = [dataAccess getAlbum:serverId];
                if (!dbAlbumInfo)
                {
                    MyAlbumInfo *albumInfo = [[MyAlbumInfo alloc] init];
                    albumInfo.albumName = albumName;
                    albumInfo.serverId = serverId;
                    albumInfo.modifiedDate = modifiedDate;
                    albumInfo.createdDate = createdDate;
                    
                    [dataAccess insertMyAlbum:albumInfo];
                    
                    [albums addObject:albumInfo];
                }
                else
                {
                    if (dbAlbumInfo.createdDate != createdDate
                        || dbAlbumInfo.modifiedDate != modifiedDate)
                    {
                        dbAlbumInfo.albumName = albumName;
                        dbAlbumInfo.modifiedDate = modifiedDate;
                        dbAlbumInfo.createdDate = createdDate;
                        
                        [dataAccess updateMyAlbum:dbAlbumInfo];
                    }

                    [albums addObject:dbAlbumInfo];
                }
                
                NSArray *contacts = [albumObject objectForKey:@"Contacts"];
                
                for(id contactObject in contacts)
                {
                    long serverId = [[contactObject objectForKey:@"Id"] longValue];
                    long albumId = [[contactObject objectForKey:@"AlbumId"] longValue];
                    NSString *phoneContactId = [contactObject objectForKey:@"PhoneContactId"];
                    NSString *displayName = [contactObject objectForKey:@"DisplayName"];
                    NSString *firstName = [contactObject objectForKey:@"FirstName"];
                    NSString *lastName = [contactObject objectForKey:@"LastName"];
                    
                    id mobilePhoneNumberObject = [contactObject objectForKey:@"MobilePhoneNumber"];
                    NSString *mobilePhoneNumber = mobilePhoneNumberObject==[NSNull null] ? @"" : mobilePhoneNumberObject;
                    
                    id otherPhoneNumberObject = [contactObject objectForKey:@"OtherPhoneNumber"];
                    NSString *otherPhoneNumber = otherPhoneNumberObject==[NSNull null] ? @"" : otherPhoneNumberObject;
                    
                    double createdDate = [[contactObject objectForKey:@"CreatedDate"] doubleValue];
                    double modifiedDate = [[contactObject objectForKey:@"ModifiedDate"] doubleValue];
                    
                    MyContactInfo *contactInfo = [dataAccess getContact:serverId];
                    if (!contactInfo)
                    {
                        MyContactInfo *contactInfo = [[MyContactInfo alloc] init];
                        contactInfo.phoneContactId = phoneContactId;
                        contactInfo.albumId = albumId;
                        contactInfo.serverId = serverId;
                        contactInfo.displayName = displayName;
                        contactInfo.firstName = firstName;
                        contactInfo.lastName = lastName;
                        contactInfo.otherPhoneNumber = otherPhoneNumber;
                        contactInfo.mobilePhoneNumber = mobilePhoneNumber;
                        contactInfo.modifiedDate = modifiedDate;
                        contactInfo.createdDate = createdDate;
                        
                        [dataAccess insertContact:contactInfo];
                    }
                    else
                    {
                        if (contactInfo.createdDate != createdDate
                            || contactInfo.modifiedDate != modifiedDate)
                        {
                            contactInfo.displayName = displayName;
                            contactInfo.firstName = firstName;
                            contactInfo.lastName = lastName;
                            contactInfo.otherPhoneNumber = otherPhoneNumber;
                            contactInfo.mobilePhoneNumber = mobilePhoneNumber;
                            contactInfo.modifiedDate = modifiedDate;
                            contactInfo.createdDate = createdDate;
                            
                            [dataAccess updateContact:contactInfo];
                        }
                    }
                }
                
                NSArray *photos = [albumObject objectForKey:@"Photos"];
                
                for(id photoObject in photos)
                {
                    NSLog(@"%@", photoObject);
                    
                    long serverId = [[photoObject objectForKey:@"Id"] integerValue];
                    bool photoSent = [[photoObject objectForKey:@"IsPhotoSent"] boolValue];
                    double dateSent = [[photoObject objectForKey:@"DateSent"] doubleValue];
                    
                    MyPhotoInfo *myPhotoInfo = [dataAccess getPhotoByServerId:serverId];
                    if(!myPhotoInfo)
                    {
                        long albumId = [[photoObject objectForKey:@"AlbumId"] integerValue];
                        NSString *fileName = [photoObject objectForKey:@"FileName"];
                        NSString *fileUrl = [photoObject objectForKey:@"Url"];
                        NSString *photoUrlOnDevice = [photoObject objectForKey:@"PhotoUrlOnDevice"];
                        NSString *contentType = [photoObject objectForKey:@"ContentType"];
                        double createdDate = [[photoObject objectForKey:@"CreatedDate"] doubleValue];
                        double fileSize = [[photoObject objectForKey:@"FileSize"] doubleValue];
                        bool isThumbnailProcessed = [[photoObject objectForKey:@"IsThumbnailProcessed"] boolValue];
                        NSString *thumbnailFileUrl = [photoObject objectForKey:@"ThumbnailUrl"];

                        myPhotoInfo = [[MyPhotoInfo alloc] init];
                        myPhotoInfo.serverId = serverId;
                        myPhotoInfo.fileName = fileName;
                        myPhotoInfo.fileUrl = fileUrl;
                        myPhotoInfo.photoUrlOnDevice = photoUrlOnDevice;
                        myPhotoInfo.dateAdded = createdDate;
                        myPhotoInfo.isPhotoSent = photoSent;
                        myPhotoInfo.albumId = albumId;
                        myPhotoInfo.dateSent = dateSent;
                        myPhotoInfo.contentType = contentType;
                        myPhotoInfo.fileSize = fileSize;
                        myPhotoInfo.isThumbnailProcessed = isThumbnailProcessed;
                        myPhotoInfo.thumbnailUrl = thumbnailFileUrl;
                        
                        [dataAccess insertMyPhotoInfo:myPhotoInfo];
                    }
                    else
                    {
                        if (myPhotoInfo.isPhotoSent != photoSent && myPhotoInfo.dateSent != dateSent)
                        {
                            myPhotoInfo.isPhotoSent = photoSent;
                            myPhotoInfo.dateSent = dateSent;
                            
                            [dataAccess updatePhotoSentInfo:serverId isPhotoSent:photoSent dateSent:dateSent];
                        }
                    }
                }
            }

            success(albums);
             
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"Error: %@", error);
             
             failure(error);
            }];
}

-(void)createAlbum:(NSString *)albumName success:(void (^)(MyAlbumInfo *))success
           failure:(void (^)(NSError *))failure
{
    NSString *albumsUrl = [AppHelper getMyAlbumsUrl];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];
    
    [manager POST:albumsUrl parameters:@{@"Name": albumName} headers:nil progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        long serverId = [[responseObject objectForKey:@"Id"] integerValue];
        
        NSString *albumName = [responseObject objectForKey:@"Name"];
        
        double createdDate = [[responseObject objectForKey:@"CreatedDate"] doubleValue];
        double modifiedDate = [[responseObject objectForKey:@"ModifiedDate"] doubleValue];
        
        MyAlbumInfo *albumInfo = [[MyAlbumInfo alloc] init];
        albumInfo.albumName = albumName;
        albumInfo.serverId = serverId;
        albumInfo.modifiedDate = modifiedDate;
        albumInfo.createdDate = createdDate;

        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        BOOL albumInserted = [dataAccess insertMyAlbum:albumInfo];
        if (albumInserted)
        {
            MyAlbumInfo *dbAlbumInfo = [dataAccess getAlbum:albumInfo.serverId];
            
            success(dbAlbumInfo);
        }
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        NSLog(@"Failure");
        failure(error);
    }];
}

-(void)deleteAlbum:(long)albumId success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSString *albumUrl = [AppHelper deleteAlbumUrl:albumId];

    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager DELETE:albumUrl parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        BOOL albumDeleted = [dataAccess removeAlbum:albumId];
        success(albumDeleted);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        NSLog(@"Failure");
        failure(error);
    }];
}

-(void)addContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(MyContactInfo *))success
           failure:(void (^)(NSError *))failure
{
    NSString *contactsUrl = [AppHelper addNewContactUrl:albumId];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    NSDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
    [contactDictionary setValue:contactInfo.phoneContactId forKey:@"PhoneContactId"];
    [contactDictionary setValue:contactInfo.displayName forKey:@"DisplayName"];
    [contactDictionary setValue:contactInfo.firstName forKey:@"FirstName"];
    [contactDictionary setValue:contactInfo.lastName forKey:@"LastName"];
    [contactDictionary setValue:contactInfo.mobilePhoneNumber != nil ? contactInfo.mobilePhoneNumber : @"" forKey:@"MobilePhoneNumber"];
    [contactDictionary setValue:contactInfo.otherPhoneNumber != nil ? contactInfo.otherPhoneNumber : @"" forKey:@"OtherPhoneNumber"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager POST:contactsUrl parameters:contactDictionary headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
         long serverId = [[responseObject objectForKey:@"Id"] longValue];
         long albumId = [[responseObject objectForKey:@"AlbumId"] longValue];
         NSString *phoneContactId = [responseObject objectForKey:@"PhoneContactId"];
         NSString *displayName = [responseObject objectForKey:@"DisplayName"];
         NSString *firstName = [responseObject objectForKey:@"FirstName"];
         NSString *lastName = [responseObject objectForKey:@"LastName"];
         
         id mobilePhoneNumberObject = [responseObject objectForKey:@"MobilePhoneNumber"];
         NSString *mobilePhoneNumber = mobilePhoneNumberObject==[NSNull null] ? @"" : mobilePhoneNumberObject;

         id otherPhoneNumberObject = [responseObject objectForKey:@"OtherPhoneNumber"];
         NSString *otherPhoneNumber = otherPhoneNumberObject==[NSNull null] ? @"" : otherPhoneNumberObject;

         double createdDate = [[responseObject objectForKey:@"CreatedDate"] doubleValue];
         double modifiedDate = [[responseObject objectForKey:@"ModifiedDate"] doubleValue];

         MyContactInfo *contactInfo = [[MyContactInfo alloc] init];
         contactInfo.phoneContactId = phoneContactId;
         contactInfo.albumId = albumId;
         contactInfo.serverId = serverId;
         contactInfo.displayName = displayName;
         contactInfo.firstName = firstName;
         contactInfo.lastName = lastName;
         contactInfo.otherPhoneNumber = otherPhoneNumber;
         contactInfo.mobilePhoneNumber = mobilePhoneNumber;
         contactInfo.modifiedDate = modifiedDate;
         contactInfo.createdDate = createdDate;

         SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
         
         [dataAccess insertContact:contactInfo];
         
         MyContactInfo *dbContactInfo = [dataAccess getContact:contactInfo.serverId];
         
         success(dbContactInfo);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"Failure");
         failure(error);
     }];
}

-(void)updateContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(MyContactInfo *))success
          failure:(void (^)(NSError *))failure
{
    NSString *contactsUrl = [AppHelper updateExistingContactUrl:albumId contactId:contactInfo.serverId];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
        
    NSDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
    [contactDictionary setValue:[NSString stringWithFormat:@"%ld", contactInfo.serverId] forKey:@"Id"];
    [contactDictionary setValue:contactInfo.phoneContactId forKey:@"PhoneContactId"];
    [contactDictionary setValue:contactInfo.displayName forKey:@"DisplayName"];
    [contactDictionary setValue:contactInfo.firstName forKey:@"FirstName"];
    [contactDictionary setValue:contactInfo.lastName forKey:@"LastName"];
    [contactDictionary setValue:contactInfo.mobilePhoneNumber != nil ? contactInfo.mobilePhoneNumber : @"" forKey:@"MobilePhoneNumber"];
    [contactDictionary setValue:contactInfo.otherPhoneNumber != nil ? contactInfo.otherPhoneNumber : @"" forKey:@"OtherPhoneNumber"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager PUT:contactsUrl parameters:contactDictionary headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
         long serverId = [[responseObject objectForKey:@"Id"] longValue];
         long albumId = [[responseObject objectForKey:@"AlbumId"] longValue];
         NSString *phoneContactId = [responseObject objectForKey:@"PhoneContactId"];
         NSString *displayName = [responseObject objectForKey:@"DisplayName"];
         NSString *firstName = [responseObject objectForKey:@"FirstName"];
         NSString *lastName = [responseObject objectForKey:@"LastName"];
         
         id mobilePhoneNumberObject = [responseObject objectForKey:@"MobilePhoneNumber"];
         NSString *mobilePhoneNumber = mobilePhoneNumberObject==[NSNull null] ? @"" : mobilePhoneNumberObject;
         
         id otherPhoneNumberObject = [responseObject objectForKey:@"OtherPhoneNumber"];
         NSString *otherPhoneNumber = otherPhoneNumberObject==[NSNull null] ? @"" : otherPhoneNumberObject;
         
         double createdDate = [[responseObject objectForKey:@"CreatedDate"] doubleValue];
         double modifiedDate = [[responseObject objectForKey:@"ModifiedDate"] doubleValue];
         
         MyContactInfo *contactInfo = [[MyContactInfo alloc] init];
         contactInfo.phoneContactId = phoneContactId;
         contactInfo.albumId = albumId;
         contactInfo.serverId = serverId;
         contactInfo.displayName = displayName;
         contactInfo.firstName = firstName;
         contactInfo.lastName = lastName;
         contactInfo.otherPhoneNumber = otherPhoneNumber;
         contactInfo.mobilePhoneNumber = mobilePhoneNumber;
         contactInfo.modifiedDate = modifiedDate;
         contactInfo.createdDate = createdDate;
         
         SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

         [dataAccess updateContact:contactInfo];
         
         MyContactInfo *dbContactInfo = [dataAccess getContact:contactInfo.serverId];
             
         success(dbContactInfo);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"Failure");
         failure(error);
     }];
}

-(void)deleteContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(BOOL))success
             failure:(void (^)(NSError *))failure
{
    NSString *contactsUrl = [AppHelper deleteExistingContactUrl:albumId contactId:contactInfo.serverId];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
        
    NSDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
    [contactDictionary setValue:[NSString stringWithFormat:@"%ld", contactInfo.serverId] forKey:@"contactId"];
    
    long serverId = contactInfo.serverId;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager DELETE:contactsUrl parameters:contactDictionary headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
         
        BOOL contactDeleted = [dataAccess removeContact:serverId];
        success(contactDeleted);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"Failure");
         failure(error);
     }];
}

-(void)deletePhoto:(long)albumId photoInfo:(MyPhotoInfo*)photoInfo success:(void (^)(BOOL))success
             failure:(void (^)(NSError *))failure
{
    NSString *photosUrl = [AppHelper deleteExistingPhotoUrl:albumId photoId:photoInfo.serverId];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    NSDictionary *photoDictionary = [[NSMutableDictionary alloc] init];
    [photoDictionary setValue:[NSString stringWithFormat:@"%ld", photoInfo.serverId] forKey:@"photoId"];
    
    long serverId = photoInfo.serverId;
    
    [manager DELETE:photosUrl parameters:photoDictionary headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
         SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
         
         BOOL photoDeleted = [dataAccess removePhoto:serverId];
         success(photoDeleted);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         long statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];

         if (statusCode == 404)
         {
             SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

             BOOL photoDeleted = [dataAccess removePhoto:serverId];
             success(photoDeleted);
         }
         NSLog(@"Failure");
         failure(error);
     }];
}

-(void)sendSnaglet:(long)albumId photoId:(long)photoId success:(void (^)(BOOL))success
           failure:(void (^)(NSError *))failure;
{
    NSString *sendSnagletUrl = [AppHelper sendSnagletUrl:albumId photoId:photoId];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager POST:sendSnagletUrl parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
         NSLog(@"%@", responseObject);
         
         SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

         long serverId = [[responseObject objectForKey:@"Id"] integerValue];
         bool photoSent = [[responseObject objectForKey:@"IsPhotoSent"] boolValue];
         double dateSent = [[responseObject objectForKey:@"DateSent"] doubleValue];
         
         MyPhotoInfo *myPhotoInfo = [dataAccess getPhotoByServerId:serverId];
         if(!myPhotoInfo)
         {
             long albumId = [[responseObject objectForKey:@"AlbumId"] integerValue];
             NSString *fileName = [responseObject objectForKey:@"FileName"];
             NSString *fileUrl = [responseObject objectForKey:@"Url"];
             NSString *photoUrlOnDevice = [responseObject objectForKey:@"PhotoUrlOnDevice"];
             NSString *contentType = [responseObject objectForKey:@"ContentType"];
             double createdDate = [[responseObject objectForKey:@"CreatedDate"] doubleValue];
             double fileSize = [[responseObject objectForKey:@"FileSize"] doubleValue];
             bool isThumbnailProcessed = [[responseObject objectForKey:@"IsThumbnailProcessed"] boolValue];
             NSString *thumbnailFileUrl = [responseObject objectForKey:@"ThumbnailUrl"];

             myPhotoInfo = [[MyPhotoInfo alloc] init];
             myPhotoInfo.serverId = serverId;
             myPhotoInfo.fileName = fileName;
             myPhotoInfo.fileUrl = fileUrl;
             myPhotoInfo.photoUrlOnDevice = photoUrlOnDevice;
             myPhotoInfo.dateAdded = createdDate;
             myPhotoInfo.isPhotoSent = photoSent;
             myPhotoInfo.albumId = albumId;
             myPhotoInfo.dateSent = dateSent;
             myPhotoInfo.contentType = contentType;
             myPhotoInfo.fileSize = fileSize;
             myPhotoInfo.isThumbnailProcessed = isThumbnailProcessed;
             myPhotoInfo.thumbnailUrl = thumbnailFileUrl;

             [dataAccess insertMyPhotoInfo:myPhotoInfo];
         }
         else
         {
             if (myPhotoInfo.isPhotoSent != photoSent && myPhotoInfo.dateSent != dateSent)
             {
                 myPhotoInfo.isPhotoSent = photoSent;
                 myPhotoInfo.dateSent = dateSent;
                 
                 [dataAccess updatePhotoSentInfo:serverId isPhotoSent:photoSent dateSent:dateSent];
             }
         }
         success(YES);
     }
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         NSLog(@"Failure");
         failure(error);
     }];
}

-(void)updateDeviceToken:(NSString *)existingToken oldToken:(NSString*)oldToken success:(void (^)(NSString *))success
           failure:(void (^)(NSError *))failure
{
    NSString *deviceTokenUrl = [AppHelper updateDeviceTokenUrl];
    
    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    NSDictionary *deviceTokenDictionary = [[NSMutableDictionary alloc] init];
    [deviceTokenDictionary setValue:existingToken forKey:@"DeviceToken"];
    [deviceTokenDictionary setValue:oldToken forKey:@"OldDeviceToken"];
    [deviceTokenDictionary setValue:@"apns" forKey:@"Platform"];

    [manager PUT:deviceTokenUrl parameters:deviceTokenDictionary headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        NSString *registeredDeviceToken = [responseObject objectForKey:@"DeviceToken"];
        
        success(registeredDeviceToken);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        NSLog(@"Failure");
        failure(error);
    }];
}

-(void)deleteAccount:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSString *deleteAccountUrl = [AppHelper deleteAccountUrl];

    NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager.requestSerializer setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

    [manager DELETE:deleteAccountUrl parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        success(1);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        NSLog(@"Failure");
        failure(error);
    }];
}


@end
