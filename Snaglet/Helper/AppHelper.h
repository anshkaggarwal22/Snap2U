//
//  AppHelper.h
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppHelper : NSObject

+(id)getPlistData:(NSString *)key;

+(NSString*)getBaseUrl;

+(NSString *)getNewUserSignupUrl;

+(NSString *)getExistingUserSignupUrl;

+(NSString *)getActivationUrl;

+(NSString *)getMyAlbumsUrl;

+(NSString *)deleteAlbumUrl:(long)albumId;

+(NSString *)deleteAccountUrl;

+(NSString *)sendSnagletUrl:(long)albumId photoId:(long)photoId;

+(NSString *)addNewContactUrl:(long)albumId;

+(NSString *)updateExistingContactUrl:(long)albumId contactId:(long)contactId;

+(NSString *)deleteExistingContactUrl:(long)albumId contactId:(long)contactId;

+(NSString *)getMyPhotosUrl:(long)albumId;

+(NSString *)deleteExistingPhotoUrl:(long)albumId photoId:(long)photoId;

+(NSString *)updateDeviceTokenUrl;

+(NSString*)getOwnerId;
+(void)saveOwnerId:(NSString*)ownerId;

+(NSString*)getToken;
+(void)saveToken:(NSString*)accessToken;

+(NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj;

@end

