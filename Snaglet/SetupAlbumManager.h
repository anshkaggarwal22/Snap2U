//
//  SetupAlbumManager.h
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadManager.h"

@class MySetupInfo;
@class MyAlbumInfo;
@class MyContactInfo;
@class SnagletManager;

@protocol SetupAlbumManagerDelegate <NSObject>

@optional

-(void)albumDataInvalid:(MyAlbumInfo*)albumInfo;

-(void)albumCreationBegin:(MyAlbumInfo*)albumInfo;

-(void)albumCreationEnd:(NSError *)error albumInfo:(MyAlbumInfo*)albumInfo;

-(void)contactCreationBegin:(MyContactInfo*)contactInfo;

-(void)contactCreationEnd:(NSError *)error contactInfo:(MyContactInfo*)contactInfo;

@end

@interface SetupAlbumManager : NSObject

@property (nonatomic, weak) id<SetupAlbumManagerDelegate> delegate;

-(id)initWithSetupInfo:(MySetupInfo*)setupInfo;

-(void)setupAlbum;

@end
