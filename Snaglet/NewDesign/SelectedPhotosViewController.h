//
//  SelectedPhotosViewController.h
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoSelectionUpdateDelegate.h"
#import "PhotoSentDelegate.h"

@class MyAlbumInfo;

@interface SelectedPhotosViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PhotoSelectionUpdateDelegate,
    PhotoSentDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil albumInfo:(MyAlbumInfo*)albumInfo parentViewController:(UIViewController *)parentViewController;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
