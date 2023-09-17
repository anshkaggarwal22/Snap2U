//
//  UploadManager.h
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyPhotoInfo.h"

@interface UploadManager : NSObject

-(void)addAssetForUploading:(NSUInteger)albumId asset:(MyPhotoInfo*)asset;

-(void)removeAssetAfterUploading:(NSUInteger)albumId asset:(MyPhotoInfo*)asset;

-(NSArray*)getAssetsBeingUploadedByAlbumId:(NSUInteger)albumId;

-(MyPhotoInfo *)getAssetBeingUploadedByUrl:(NSUInteger)albumId photoUrlOnDevice:(NSString*)photoUrlOnDevice;

@end
