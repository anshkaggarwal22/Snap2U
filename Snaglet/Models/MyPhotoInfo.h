//
//  AlbumInfo.h
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyPhotoInfo : NSObject<NSCopying>

@property (nonatomic, assign) int Id;
@property (nonatomic, assign) long albumId;
@property (nonatomic, assign) long serverId;
@property (nonatomic, strong) NSString *photoUrlOnDevice;
@property (nonatomic, assign) double dateAdded;
@property (nonatomic, assign) BOOL isPhotoSent;
@property (nonatomic, assign) double dateSent;
@property (nonatomic, assign) double fileSize;
@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic, assign) BOOL isThumbnailProcessed;

@property (nonatomic, strong) PHAsset *asset;

-(id)copyWithZone:(NSZone *)zone;

-(NSString*)getPhotoUrl;


@end
