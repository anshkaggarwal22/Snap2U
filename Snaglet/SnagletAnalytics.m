//
//  SnagletAnalytics.m
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//


#import "SnagletAnalytics.h"

@interface SnagletAnalytics ()

- (id)init;

@end

@implementation SnagletAnalytics

+ (id)sharedSnagletAnalytics
{
    static SnagletAnalytics *snagletAnalytics = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        snagletAnalytics = [[self alloc] init];
    });
    return snagletAnalytics;
}

- (id)init
{
    if (self = [super init])
    {

    }
    return self;
}

- (void)logScreen:(UIViewController*)viewController
{
    [self logScreenView:NSStringFromClass([viewController class])];
}

- (void)logScreenView:(NSString *)screenName
{
}

- (void)logButtonPress:(NSString *)screenName button:(UIButton*)button
{
    [self logButtonPress:screenName buttonTitle:[button.titleLabel text]];
}

- (void)logButtonPress:(NSString *)screenName buttonTitle:(NSString*)buttonTitle
{
}

@end
