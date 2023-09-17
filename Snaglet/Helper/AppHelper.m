//
//  AppHelper.m
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AppHelper.h"
#import "UICKeyChainStore.h"
#import <objc/runtime.h>

@implementation AppHelper

+(id)getPlistData:(NSString *)key
{
    NSString *path = [[NSBundle mainBundle] bundlePath];

    NSString *fileName = [NSString stringWithFormat:@"%@.%@", @"Info", @"plist"];

    NSString *finalPath = [path stringByAppendingPathComponent:fileName];
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: finalPath];
    
    return [data objectForKey:key];
}

+(NSString *)getBaseUrl
{
    NSString *env = [AppHelper getPlistData:@"env"];
    
    NSDictionary *dictUrl = [AppHelper getPlistData:@"ApiUrl"];
    
    return [dictUrl objectForKey:env];
}

+(NSString *)getNewUserSignupUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Account/RegisterPhoneNumber", baseUrl];
}

+(NSString *)getExistingUserSignupUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Account/ReRegisterPhoneNumber", baseUrl];
}

+(NSString *)getActivationUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/Token", baseUrl];
}

+(NSString *)getMyAlbumsUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums", baseUrl];
}

+(NSString *)deleteAlbumUrl:(long)albumId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld", baseUrl, albumId];
}

+(NSString *)deleteAccountUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/User/DeleteAccount", baseUrl];
}

+(NSString *)sendSnagletUrl:(long)albumId photoId:(long)photoId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Photos/%ld/Send", baseUrl, albumId, photoId];
}

+(NSString *)addNewContactUrl:(long)albumId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Contact", baseUrl, albumId];
}

+(NSString *)updateExistingContactUrl:(long)albumId contactId:(long)contactId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Contacts/%ld", baseUrl, albumId, contactId];
}

+(NSString *)deleteExistingContactUrl:(long)albumId contactId:(long)contactId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Contacts/%ld", baseUrl, albumId, contactId];
}

+(NSString *)getMyPhotosUrl:(long)albumId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Photos", baseUrl, albumId];
}

+(NSString *)deleteExistingPhotoUrl:(long)albumId photoId:(long)photoId
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/Albums/%ld/Photos/%ld", baseUrl, albumId, photoId];
}

+(NSString *)updateDeviceTokenUrl
{
    NSString *baseUrl = [AppHelper getBaseUrl];
    
    return [NSString stringWithFormat:@"%@/api/User/DeviceTokens", baseUrl];
}

+(NSString*)getOwnerId
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.snaglet"];
    return keychain[@"OwnerId"];
}

+(void)saveOwnerId:(NSString*)ownerId
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.snaglet"];
    keychain[@"OwnerId"] = ownerId;
}

+(NSString*)getToken
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.snaglet"];
    return keychain[@"access_token"];
}

+(void)saveToken:(NSString*)accessToken
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.snaglet"];
    keychain[@"access_token"] = accessToken;
}

+(NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSUInteger count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (NSInteger i = 0; i < count; i++)
    {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        [dict setObject:[obj valueForKey:key] forKey:key];
    }
    
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

