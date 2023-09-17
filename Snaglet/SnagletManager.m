//
//  SnagletManager.m
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SnagletManager.h"
#import "SnagletDataAccess.h"
#import "DbHistory.h"
#import "Asset.h"
#import "AppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppHelper.h"
#import "UploadProgressInfo.h"
#import "SnagletRepository.h"
#import "UploadManager.h"
#import "SnagletMutableDictionary.h"

@implementation UploadAssetWrapper


@end

@interface SnagletManager ()  <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) SnagletMutableDictionary *uploadTasks;

@property (nonatomic, weak) UploadManager *uploadManager;

@property (nonatomic, strong) SnagletMutableDictionary *responsesData;

@property (copy) void (^sessionCompletionHandler)(void);

@end

@implementation SnagletManager

typedef void (^assetSuccessBlock)(Asset *asset);
typedef void (^assetForTodayBlock)(NSArray *arrFiles);
typedef void (^failureBlock)(NSError *error);

-(id)initWithUploadManager:(UploadManager*)uploadManager
{
    self = [super init];
    if (self)
    {
        self.uploadTasks = [[SnagletMutableDictionary alloc] init];
        self.responsesData = [[SnagletMutableDictionary alloc] init];
        self.uploadManager = uploadManager;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBackgroundSession:)
                                                     name:@"BackgroundSessionUpdated"
                                                   object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)sendSnagletSmsOnly:(MyPhotoInfo*)photoInfo albumId:(long)albumId {
    if (photoInfo.serverId <= 0) {
        return;
    }
    
    typeof(self) __weak weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate) {
                [weakSelf.delegate smsNotificationBegin];
            }
            
            SnagletRepository *repository = [[SnagletRepository alloc] init];
            
            [repository sendSnaglet:albumId photoId:photoInfo.serverId success:^(BOOL success) {
                typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && strongSelf.delegate) {
                    [strongSelf.delegate smsNotificationCompleted:nil];
                }
            } failure:^(NSError *error) {
                typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && strongSelf.delegate) {
                    [strongSelf.delegate smsNotificationCompleted:error];
                }
            }];
        });
    });
}

-(void)uploadSnaglets:(NSArray*)assets albumId:(long)albumId
{
    [self uploadSnaglets:assets albumId:albumId sendSnaglet:NO];
}

-(void)uploadAndSendSnaglets:(NSArray *)assets albumId:(long)albumId
{
    [self uploadSnaglets:assets albumId:albumId sendSnaglet:YES];
}

- (void)notifyUploadsBeginForAssets:(NSArray<MyPhotoInfo *> *)assets {

    dispatch_async(dispatch_get_main_queue(), ^{
        for (MyPhotoInfo *photoInfo in assets) {
            NSDictionary *userInfo = @{@"uploadedPhotoInfo": photoInfo};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoUploadBegin" object:nil userInfo:userInfo];
        }
    });
}

- (void)uploadSnaglets:(NSArray<MyPhotoInfo *> *)assets albumId:(long)albumId sendSnaglet:(BOOL)sendSnaglet {
    if (assets.count == 0) {
        return;
    }

    [assets enumerateObjectsUsingBlock:^(MyPhotoInfo * _Nonnull photoInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.uploadManager addAssetForUploading:albumId asset:photoInfo];
    }];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        [strongSelf notifyUploadsBeginForAssets:assets];

        NSString *baseUrl = [AppHelper getBaseUrl];
        NSString *fileUploadUrl = [NSString stringWithFormat:@"%@/api/Albums/%ld/AddPhotos", baseUrl, albumId];
        NSURL *url = [NSURL URLWithString:fileUploadUrl];

        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:url.absoluteString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for (MyPhotoInfo *photoInfo in assets) {
                Asset *snagletAsset = nil;

                if (photoInfo.asset != nil) {
                    snagletAsset = [self getAssetUrl:photoInfo.asset albumId:photoInfo.albumId];
                } else {
                    if ([NSString isNilOrEmpty:photoInfo.photoUrlOnDevice]) {
                        continue;
                    }

                    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[photoInfo.photoUrlOnDevice] options:nil];
                    PHAsset *asset = result.firstObject;

                    snagletAsset = [self getAssetUrl:asset albumId:photoInfo.albumId];
                }

                NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
                [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", snagletAsset.fileName, snagletAsset.fileName] forKey:@"Content-Disposition"];
                [mutableHeaders setValue:snagletAsset.contentType forKey:@"Content-Type"];
                [mutableHeaders setValue:snagletAsset.assetUrl forKey:@"PhotoUrlOnDevice"];

                if (snagletAsset.isImage) {
                    [formData appendPartWithHeaders:mutableHeaders body:snagletAsset.imageData];
                } else if (snagletAsset.isVideo) {
                    NSData *fileData = [NSData dataWithContentsOfFile:snagletAsset.tmpFileName];
                    [formData appendPartWithHeaders:mutableHeaders body:fileData];
                }
            }
        } error:nil];

        NSString *authorizationHeaderValue = [NSString stringWithFormat:@"Bearer %@", [AppHelper getToken]];
        [request setValue:authorizationHeaderValue forHTTPHeaderField:@"Authorization"];

        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.allowsCellularAccess = YES;
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];

        NSURLSessionUploadTask *uploadTask = [urlSession uploadTaskWithStreamedRequest:request];
        uploadTask.taskDescription = [[NSUUID UUID] UUIDString];

        UploadAssetWrapper *assetWrapper = [[UploadAssetWrapper alloc] init];
        assetWrapper.assets = assets;
        assetWrapper.uploadTask = uploadTask;
        assetWrapper.sendSnaglet = sendSnaglet;

        [strongSelf.uploadTasks setObject:assetWrapper forKey:uploadTask.taskDescription];

        [uploadTask resume];
    });
}

#pragma implementation Private Functions

- (Asset *)getAssetUrl:(PHAsset *)result albumId:(long)albumId {
    PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:result] firstObject];
    if (resource != nil) {
        NSString *assetIdentifier = result.localIdentifier;
        
        BOOL isVideo = result.mediaType == PHAssetMediaTypeVideo;
        BOOL isImage = result.mediaType == PHAssetMediaTypeImage;
        
        NSString *fileName = resource.originalFilename;
        NSString *fileExtension = [fileName pathExtension];
        
        NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)resource.uniformTypeIdentifier, kUTTagClassMIMEType);
        
        NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];
        NSString *tmpFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"%f.%@", ti, fileExtension]];
        
        Asset *fileAsset = [[Asset alloc] init];
        
        if (isVideo) {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHVideoRequestOptionsVersionOriginal;

            [[PHImageManager defaultManager] requestAVAssetForVideo:result options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                if ([asset isKindOfClass:[AVURLAsset class]]) {
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    NSURL *url = urlAsset.URL;
                    
                    if (url != nil) {
                        NSError *error = nil;
                        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
                        
                        if (error == nil && data != nil) {
                            [data writeToFile:tmpFileName atomically:YES];
                            fileAsset.tmpFileName = tmpFileName;
                            fileAsset.isVideo = isVideo;
                            fileAsset.isImage = isImage;
                            fileAsset.contentType = mimeType;
                            fileAsset.fileName = fileName;
                            fileAsset.fileSize = [data length];
                            fileAsset.assetUrl = assetIdentifier;
                            fileAsset.albumUrl = assetIdentifier;
                            fileAsset.albumId = [NSString stringWithFormat:@"%ld", albumId];
                        }
                    }
                }
            }];
        } else if (isImage) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.version = PHImageRequestOptionsVersionOriginal;
            options.synchronous = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:result options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                
                if (imageData != nil) {
                    fileAsset.isVideo = isVideo;
                    fileAsset.isImage = isImage;
                    fileAsset.contentType = mimeType;
                    fileAsset.fileName = fileName;
                    fileAsset.fileSize = [imageData length];
                    fileAsset.assetUrl = assetIdentifier;
                    fileAsset.albumUrl = assetIdentifier;
                    fileAsset.albumId = [NSString stringWithFormat:@"%ld", albumId];
                    fileAsset.imageData = imageData;
                }
            }];
            return fileAsset;
        }
        
        return fileAsset;
    }
    return nil;
}

- (void)handleBackgroundSession:(NSNotification *)notification
{
    UploadAssetWrapper *assetWrapper = [self.uploadTasks objectForKey:notification.userInfo[@"sessionIdentifier"]];
    if (assetWrapper != nil)
    {
        self.sessionCompletionHandler = notification.userInfo[@"completionHandler"];
    }
}

#pragma NSURLSessionTaskDelegate Delegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    UploadProgressInfo *uploadInfo = [UploadProgressInfo new];
    uploadInfo.bytesSent = bytesSent;
    uploadInfo.totalBytesSent = totalBytesSent;
    uploadInfo.totalBytesExpectedToSend = totalBytesExpectedToSend;

    UploadAssetWrapper *assetWrapper = [self.uploadTasks objectForKey:task.taskDescription];

    for (MyPhotoInfo *photoInfo in assetWrapper.assets) {
        float percentageComplete = (float)uploadInfo.totalBytesSent / (float) uploadInfo.totalBytesExpectedToSend;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{
                @"uploadedPhotoInfo": photoInfo,
                @"percentageComplete": [NSString stringWithFormat:@"%f", percentageComplete],
            };

            [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoUploadProgress" object:nil userInfo:userInfo];
        });
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSMutableData *responseData = self.responsesData[@(dataTask.taskIdentifier)];
    
    if (!responseData)
    {
        responseData = [NSMutableData dataWithData:data];
        self.responsesData[@(dataTask.taskIdentifier)] = responseData;
    }
    else
    {
        [responseData appendData:data];
    }
}

- (MyPhotoInfo *)parseMyPhotoInfoFromJSON:(id)photoInfo {
    MyPhotoInfo *myPhotoInfo = [[MyPhotoInfo alloc] init];
    myPhotoInfo.serverId = [photoInfo[@"Id"] integerValue];
    myPhotoInfo.fileName = photoInfo[@"FileName"];
    myPhotoInfo.fileUrl = photoInfo[@"Url"];
    myPhotoInfo.photoUrlOnDevice = photoInfo[@"PhotoUrlOnDevice"];
    myPhotoInfo.dateAdded = [photoInfo[@"CreatedDate"] doubleValue];
    myPhotoInfo.isPhotoSent = [photoInfo[@"IsPhotoSent"] boolValue];
    myPhotoInfo.albumId = [photoInfo[@"AlbumId"] integerValue];
    myPhotoInfo.dateSent = [photoInfo[@"DateSent"] doubleValue];
    myPhotoInfo.contentType = photoInfo[@"ContentType"];
    myPhotoInfo.fileSize = [photoInfo[@"FileSize"] doubleValue];
    myPhotoInfo.isThumbnailProcessed = [photoInfo[@"IsThumbnailProcessed"] boolValue];
    myPhotoInfo.thumbnailUrl = photoInfo[@"ThumbnailUrl"];

    return myPhotoInfo;
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    UploadAssetWrapper *assetWrapper = [self.uploadTasks objectForKey:task.taskDescription];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:assetWrapper.assets, @"uploadedAssets",
                              [NSString stringWithFormat:@"%d", assetWrapper.sendSnaglet], @"sendSnaglet",
                              nil];

    [self.uploadTasks removeObjectForKey:task.taskDescription];

    if (error == nil && task.state == NSURLSessionTaskStateCompleted)
    {
        SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];

        NSMutableData *responseData = self.responsesData[@(task.taskIdentifier)];
        
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        
        for (id photoInfo in responseDictionary) {
            @autoreleasepool {
                @try {
                    MyPhotoInfo *myPhotoInfo = [self parseMyPhotoInfoFromJSON:photoInfo];
                    [dataAccess insertMyPhotoInfo:myPhotoInfo];
                    [self.uploadManager removeAssetAfterUploading:myPhotoInfo.albumId asset:myPhotoInfo];
                } @catch (NSException *exception) {
                    NSLog(@"An exception occurred: %@", exception);
                    return;
                }
            }
        }

        [self.responsesData removeObjectForKey:@(task.taskIdentifier)];

        if (assetWrapper.sendSnaglet)
        {
            for (MyPhotoInfo *photoInfo in assetWrapper.assets)
            {
                MyPhotoInfo *dbPhotoInfo = [dataAccess readPhotoByAlbumIdAndUrl:photoInfo.albumId url:photoInfo.photoUrlOnDevice];
                
                [self.uploadManager removeAssetAfterUploading:photoInfo.albumId asset:photoInfo];

                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(),
               ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf)
                    {
                        NSDictionary *userPhotoInfo = @{@"uploadedPhotoInfo": photoInfo};
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoUploadComplete" object:nil userInfo:userPhotoInfo];
                        
                        if (strongSelf.delegate)
                        {
                            [strongSelf.delegate smsNotificationBegin];
                        }
                   
                        SnagletRepository *repository = [[SnagletRepository alloc] init];
                   
                        [repository sendSnaglet:dbPhotoInfo.albumId photoId:dbPhotoInfo.serverId success:^(BOOL success)
                         {
                            if (strongSelf.delegate)
                            {
                                [strongSelf.delegate smsNotificationCompleted:nil];
                            }
                        }
                        failure:^(NSError *error)
                        {
                            if (strongSelf.delegate)
                            {
                                [strongSelf.delegate smsNotificationCompleted:error];
                            }
                        }];;
                    }
               });
            }
        }
        else
        {
            for (MyPhotoInfo *photoInfo in assetWrapper.assets)
            {
                dispatch_async(dispatch_get_main_queue(),
               ^{
                   NSDictionary *userPhotoInfo = @{@"uploadedPhotoInfo": photoInfo};
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoUploadComplete" object:nil userInfo:userPhotoInfo];
                });
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UploadComplete" object:nil userInfo:userInfo];

        return;
    }
    else
    {
        for (MyPhotoInfo *photoInfo in assetWrapper.assets)
        {
            dispatch_async(dispatch_get_main_queue(),
           ^{
               NSDictionary *userPhotoInfo = @{@"uploadedPhotoInfo": photoInfo};
               [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoUploadError" object:nil userInfo:userPhotoInfo];
           });
            NSLog(@"Task %@ completed with error: %@", task, [error localizedDescription]);
        }
    }

    task = nil;
}

# pragma NSURLSessionDelegate Delegate methods

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"sadface :( %@", error);
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.sessionCompletionHandler)
    {
        self.sessionCompletionHandler();
        self.sessionCompletionHandler = nil;
    }
    NSLog(@"Task complete");
}


@end
