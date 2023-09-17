//
//  AlbumInfo.m
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "MyPhotoInfo.h"

@implementation MyPhotoInfo

-(id)copyWithZone:(NSZone *)zone
{
    MyPhotoInfo *photoInfo = [[MyPhotoInfo allocWithZone:zone] init];
    
    [photoInfo setId:self.Id];
    [photoInfo setAlbumId:self.albumId];
    [photoInfo setServerId:self.serverId];
    [photoInfo setDateAdded:self.dateAdded];
    [photoInfo setIsPhotoSent:self.isPhotoSent];
    [photoInfo setDateSent:self.dateSent];
    [photoInfo setFileSize:self.fileSize];
    [photoInfo setPhotoUrlOnDevice:self.photoUrlOnDevice];
    [photoInfo setFileUrl:self.fileUrl];
    [photoInfo setContentType:self.contentType];
    [photoInfo setFileName:self.fileName];
    [photoInfo setAsset:self.asset];
    [photoInfo setThumbnailUrl:self.thumbnailUrl];
    [photoInfo setIsThumbnailProcessed:self.isThumbnailProcessed];
    
    return photoInfo;
}

-(NSString*)getPhotoUrl
{
    if (self.isThumbnailProcessed)
    {
        return self.thumbnailUrl;
    }
    return self.fileUrl;
}

@end
