//
//  MyAlbumInfo.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadProgressInfo : NSObject

@property (nonatomic, assign) int64_t bytesSent;
@property (nonatomic, assign) int64_t totalBytesSent;
@property (nonatomic, assign) int64_t totalBytesExpectedToSend;

@end
