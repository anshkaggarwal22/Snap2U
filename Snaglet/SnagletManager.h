//
//  SnagletManager.h
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyContactInfo.h"
#import "DbHistory.h"

@class MyPhotoInfo;
@class UploadManager;

typedef void (^snagletResultBlock)(bool success);

@interface UploadAssetWrapper : NSObject

@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, strong) NSURLSessionTask *uploadTask;
@property (nonatomic, assign) BOOL sendSnaglet;

@end

@protocol UploadManagerDelegate <NSObject>

@optional

-(void)smsNotificationBegin;

-(void)UploadSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

-(void)UploadSessionCompleted:(NSURLSession *)session task:(NSURLSessionTask *)task error:(NSError *)error;

-(void)contactNotified:(MyContactInfo *)contact history:(DbHistory*)history error:(NSError *)error;

-(void)smsNotificationCompleted:(NSError *)error;

@end


@interface SnagletManager : NSObject

@property (nonatomic, weak) id<UploadManagerDelegate> delegate;

-(id)initWithUploadManager:(UploadManager*)uploadManager;

-(void)uploadSnaglets:(NSArray*)assets albumId:(long)albumId;

-(void)uploadAndSendSnaglets:(NSArray*)assets albumId:(long)albumId;

-(void)sendSnagletSmsOnly:(MyPhotoInfo*)photoInfo albumId:(long)albumId;

@end
