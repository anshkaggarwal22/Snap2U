//
//  ContactInfoCell.m
//  Snaglet
//
//  Created by anshaggarwal on 9/27/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "ContactInfoCell.h"

@implementation ContactInfoCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Initialization code
    self.imgContact.layer.cornerRadius = 24.0f;
    self.imgContact.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
