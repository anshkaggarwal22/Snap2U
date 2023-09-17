//
//  MyAlbumInfo.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyAlbumInfo : NSObject

@property (nonatomic, assign) NSInteger Id;
@property (nonatomic, assign) NSInteger serverId;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, assign) double createdDate;
@property (nonatomic, assign) double modifiedDate;
@property (nonatomic, assign, readonly) NSInteger photosInQueueCount;
@property (nonatomic, assign, readonly) NSInteger photosCount;
@property (nonatomic, assign, readonly) NSInteger recipientsCount;
@property (nonatomic, assign, readonly) UIImage *albumImage;

@end
