//
//  ContactInfoCell.h
//  Snaglet
//
//  Created by anshaggarwal on 9/27/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgContact;
@property (weak, nonatomic) IBOutlet UILabel *lblDisplayName;
@property (weak, nonatomic) IBOutlet UILabel *lblPhone;
@property (weak, nonatomic) IBOutlet UILabel *lblPhone2;

@end
