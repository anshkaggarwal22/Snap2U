//
//  PhotoSentDelegate.h
//  Snaglet
//
//  Created by anshaggarwal on 9/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PhotoSentDelegate <NSObject>

-(void)photoSent:(long)albumId cellIndex:(NSInteger)cellIndex;

@end
