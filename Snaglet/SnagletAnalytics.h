//
//  SnagletAnalytics.h
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface SnagletAnalytics : NSObject

+ (id)sharedSnagletAnalytics;

- (void)logScreen:(UIViewController*)viewController;
- (void)logScreenView:(NSString *)screenName;

- (void)logButtonPress:(NSString *)screenName button:(UIButton*)button;
- (void)logButtonPress:(NSString *)screenName buttonTitle:(NSString*)buttonTitle;

@end
