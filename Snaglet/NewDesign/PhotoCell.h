//
//  PhotoCell.h
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UICollectionViewCell<MBProgressHUDDelegate>

@property (nonatomic, strong) NSURL *imageURL;

@property (nonatomic, strong) PHAsset *asset;

@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@property (nonatomic, assign) BOOL photoSelected;
@property (nonatomic, assign) long albumId;

@property (nonatomic, assign) BOOL isPhotoSent;
@property (weak, nonatomic) IBOutlet UIView *progressView;

@property (nonatomic, assign) BOOL showUploadedOverlay;

- (void)resetForNotification:(BOOL)notify;

@end
