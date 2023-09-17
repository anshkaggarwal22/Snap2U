//
//  UIImageView+Snaglet.m
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "UIImageView+Snaglet.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation UIImageView (Snaglet)

-(void)snaglet_setImageWithURL:(NSURL *)url imageSent:(BOOL)imageSent placeholderImage:(UIImage *)placeholder
{
    __block UIActivityIndicatorView *activityIndicator;
    __weak UIImageView *weakImageView = self;
    
    bool photoSent = imageSent;
    
    [self sd_setImageWithURL:url
                         placeholderImage:placeholder
                                  options:SDWebImageProgressiveDownload | SDWebImageContinueInBackground
                                 progress:^(NSInteger receivedSize, NSInteger expectedSize)
     {
         dispatch_async(dispatch_get_main_queue(), ^{

             if (!activityIndicator)
             {
                 [weakImageView addSubview:activityIndicator = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
                 activityIndicator.center = weakImageView.center;
                 [activityIndicator startAnimating];
             }
         });
     }
     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
     {
         [activityIndicator removeFromSuperview];
         activityIndicator = nil;
         
         if (photoSent)
         {
             UIImageView *overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, weakImageView.frame.size.width, weakImageView.frame.size.height)];
             overlayImageView.image = [UIImage imageNamed:@"overlay-sent"];
             overlayImageView.tag = 100;
             
             [weakImageView addSubview:overlayImageView];
         }
     }];
}

@end

