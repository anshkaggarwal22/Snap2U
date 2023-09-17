//
//  UIImageView+Snaglet.h
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Snaglet)

-(void)snaglet_setImageWithURL:(NSURL *)url imageSent:(BOOL)imageSent placeholderImage:(UIImage *)placeholder;

@end
