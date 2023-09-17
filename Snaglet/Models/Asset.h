//
//  Asset.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Asset : NSObject

@property (nonatomic, strong) NSString *tmpFileName;
@property (nonatomic, strong) NSString *contentType;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *assetUrl;
@property (nonatomic, strong) NSString *albumUrl;
@property (nonatomic, strong) NSString *albumId;
@property (nonatomic, assign) bool isImage;
@property (nonatomic, assign) bool isVideo;
@property (nonatomic, assign) long long fileSize;

@property (nonatomic, strong) NSData *imageData;

@end
