//
//  UploadManager.m
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "UploadManager.h"
#import "SnagletMutableDictionary.h"
#import "SnagletDataAccess.h"

@interface UploadManager ()

@property (nonatomic, strong) SnagletMutableDictionary *uploadAssets;

@end

@implementation UploadManager

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.uploadAssets = [[SnagletMutableDictionary alloc] init];
    }
    return self;
}

-(void)addAssetForUploading:(NSUInteger)albumId asset:(MyPhotoInfo *)asset
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    MyPhotoInfo *photoExists = [self getAssetBeingUploadedByUrl:albumId photoUrlOnDevice:asset.photoUrlOnDevice];
    
    if (!photoExists)
    {
        [dataAccess insertUploadPhotoProgressInfo:asset];
    }
}

-(void)removeAssetAfterUploading:(NSUInteger)albumId asset:(MyPhotoInfo *)asset
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    [dataAccess removeUploadPhotoProgressInfo:asset.albumId url:asset.photoUrlOnDevice];
}

-(NSArray *)getAssetsBeingUploadedByAlbumId:(NSUInteger)albumId
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

    return [dataAccess getPhotosBeingUploadedByAlbumId:albumId];
}

-(MyPhotoInfo *)getAssetBeingUploadedByUrl:(NSUInteger)albumId photoUrlOnDevice:(NSString*)photoUrlOnDevice
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    return [dataAccess getPhotosBeingUploadedByAlbumIdAndPhotoUrl:albumId url:photoUrlOnDevice];
}

@end
