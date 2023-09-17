//
//  SnagletRepository.h
//  Snaglet
//
//  Created by anshaggarwal on 1/25/15.
//  Copyright (c) 2015 Snaglet. All rights reserved.
//

#ifndef Snaglet_SnagletRepository_h
#define Snaglet_SnagletRepository_h

@class MyAlbumInfo;
@class MyPhotoInfo;
@class MyContactInfo;

@interface SnagletRepository : NSObject

-(void)loadAlbums:(void (^)(NSArray *albums))success
          failure:(void (^)(NSError *error))failure;

-(void)createAlbum:(NSString*)albumName success:(void (^)(MyAlbumInfo *album))success
           failure:(void (^)(NSError *error))failure;

-(void)deleteAlbum:(long)albumId success:(void (^)(BOOL))success
           failure:(void (^)(NSError *))failure;

-(void)addContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(MyContactInfo *))success
          failure:(void (^)(NSError *))failure;

-(void)updateContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(MyContactInfo *))success
          failure:(void (^)(NSError *))failure;

-(void)deleteContact:(long)albumId contactInfo:(MyContactInfo*)contactInfo success:(void (^)(BOOL))success
             failure:(void (^)(NSError *))failure;

-(void)sendSnaglet:(long)albumId photoId:(long)photoId success:(void (^)(BOOL))success
           failure:(void (^)(NSError *))failure;

-(void)deletePhoto:(long)albumId photoInfo:(MyPhotoInfo*)photoInfo success:(void (^)(BOOL))success
           failure:(void (^)(NSError *))failure;

-(void)updateDeviceToken:(NSString *)existingToken oldToken:(NSString*)oldToken success:(void (^)(NSString *))success
           failure:(void (^)(NSError *))failure;

-(void)deleteAccount: (void (^)(BOOL))success
           failure:(void (^)(NSError *))failure;

@end


#endif
