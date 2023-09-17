//
//  PhotoFullScreenViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 10/1/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyAlbumInfo.h"
#import "SnagletManager.h"
#import "PhotoSentDelegate.h"

@class MyPhotoInfo;

@interface PhotoFullScreenViewController : UIViewController<UploadManagerDelegate,
    MBProgressHUDDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil photoInfo:(MyPhotoInfo*)photoInfo albumInfo:(MyAlbumInfo *)albumInfo cellIndex:(NSInteger)cellIndex setupMode:(BOOL)setupMode;

@property (weak, nonatomic) IBOutlet UIImageView *imgPhotoView;
@property (weak, nonatomic) IBOutlet UIButton *btnSendSms;
@property (weak, nonatomic) IBOutlet UILabel *lblProgress;
@property (assign, nonatomic) NSInteger cellIndex;

@property (weak, nonatomic) id<PhotoSentDelegate> delegate;

- (IBAction)sendPhoto:(id)sender;

@end
