//
//  MySetupInfo.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MyAlbumInfo;

@interface MySetupInfo : NSObject

@property (nonatomic, strong) MyAlbumInfo *albumInfo;
@property (nonatomic, strong) NSArray *photosInfo;
@property (nonatomic, strong) NSMutableDictionary *contactsInfo;

@end
