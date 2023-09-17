//
//  NSString+Utilities.m
//  Snaglet
//
//  Created by anshaggarwal on 5/4/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

+ (BOOL)isNilOrEmpty:(NSString *)string
{
    if ((NSNull *) string == [NSNull null])
    {
        return YES;
    }
    
    if (!string || string.length <= 0)
    {
        return YES;
    }

    if([string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length <= 0)
    {
        return YES;
    }
    return NO;
}

@end

