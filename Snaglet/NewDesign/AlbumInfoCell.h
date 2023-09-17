//
//  AlbumInfoCell.h
//  Snaglet
//
//  Created by anshaggarwal on 9/24/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlbumInfoCell : UITableViewCell

@property (nonatomic, strong) NSURL *imageURL;

@property (weak, nonatomic) IBOutlet UIImageView *imgAlbum;

@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblPhotoDetails;

@end
