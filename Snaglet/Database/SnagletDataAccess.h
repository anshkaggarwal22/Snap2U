//
//  SnagletDataAccess.h
//  Snaglet
//
//  Created by anshaggarwal on 7/15/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyAlbumInfo.h"
#import "MyContactInfo.h"
#import "DbHistory.h"
#import "MyPhotoInfo.h"
#import "MyPreferences.h"

@interface SnagletDataAccess : NSObject

+(NSString *)getDatabasePath;
+(id)sharedSnagletDbAccess;

-(BOOL)insertHistory:(DbHistory *)history;

-(NSMutableArray *)getAllContacts:(NSInteger)albumId;
-(NSMutableArray *)getMobileOnlyContacts;
-(NSMutableArray *)getHistoryByContactId:(NSInteger)contactId;

-(BOOL)isAssetDelivered:(NSString*)albumId assetUrl:(NSString *)assetUrl;

////////////////////////////////////

-(BOOL)insertMyAlbum:(MyAlbumInfo *)album;
-(BOOL)updateMyAlbum:(MyAlbumInfo *)album;
-(BOOL)removeAlbum:(NSInteger)albumId;
-(MyAlbumInfo*)getAlbum:(NSInteger)albumId;
-(NSMutableArray *)getMyAlbums;

-(NSInteger)getPhotosInQueueCount:(NSInteger)albumId;
-(NSInteger)getPhotosCount:(NSInteger)albumId;
-(NSInteger)getRecipientsCount:(NSInteger)albumId;
-(MyPhotoInfo*)getFirstPhotoByAlbumId:(NSInteger)albumId;

-(BOOL)insertContact:(MyContactInfo *)contact;
-(MyContactInfo*)getContact:(NSInteger)contactServerId;
-(BOOL)updateContact:(MyContactInfo*)contactInfo;
-(BOOL)removeContact:(NSInteger)serverId;

-(NSMutableArray*)getPhotosByAlbumId:(NSInteger)albumId;
-(MyPhotoInfo*)getPhotoByServerId:(NSInteger)photoId;

-(BOOL)insertMyPhotoInfo:(MyPhotoInfo *)photo;
-(BOOL)updatePhotoSentInfo:(NSInteger)serverId isPhotoSent:(BOOL)isPhotoSent dateSent:(double)dateSent;
-(BOOL)removePhoto:(NSInteger)serverId;
-(BOOL)removePhotoByAlbumIdAndUrl:(NSInteger)albumId url:(NSString *)url;
-(MyPhotoInfo*)readPhotoByAlbumIdAndUrl:(NSInteger)albumId url:(NSString *)url;

-(MyContactInfo*)getContactByAlbumIdAndPhoneContactId:(NSInteger)albumId contactId:(NSString*)contactId;

-(MyPreferences*)getMyPreferences;
-(BOOL)updateMyPreferences:(MyPreferences*)preferences;

-(BOOL)insertUploadPhotoProgressInfo:(MyPhotoInfo *)photo;
-(BOOL)removeUploadPhotoProgressInfo:(NSInteger)albumId url:(NSString *)url;
-(NSMutableArray*)getPhotosBeingUploadedByAlbumId:(NSInteger)albumId;
-(MyPhotoInfo*)getPhotosBeingUploadedByAlbumIdAndPhotoUrl:(NSInteger)albumId url:(NSString*)url;
-(NSMutableArray*)getPhotosToBeUploaded;

-(BOOL)createUploadProgressTable;

@end
