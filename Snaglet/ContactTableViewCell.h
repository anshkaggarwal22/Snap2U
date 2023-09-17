//
//  ContactTableViewCell.h
//  Snaglet
//
//  Created by anshaggarwal on 7/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblDisplayName;

@property (weak, nonatomic) IBOutlet UIImageView *imgContactSelected;

@end
