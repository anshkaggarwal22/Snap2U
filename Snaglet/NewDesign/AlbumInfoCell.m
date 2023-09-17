//
//  AlbumInfoCell.m
//  Snaglet
//
//  Created by anshaggarwal on 9/24/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "AlbumInfoCell.h"
#import "UIImageView+Snaglet.h"

@implementation AlbumInfoCell

- (void)awakeFromNib
{
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setImageURL:(NSURL *)imageURL
{
    if (_imageURL != imageURL)
    {
        _imageURL = imageURL;
        [self configureView];
    }
}

- (void)configureView
{
    if (self.imageURL)
    {
        [self.imgAlbum snaglet_setImageWithURL:self.imageURL imageSent:NO placeholderImage:[UIImage imageNamed:@"img-default-album"]];
    }
}


@end
