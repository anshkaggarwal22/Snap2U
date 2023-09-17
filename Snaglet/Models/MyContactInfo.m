//
//  MyContactInfo.m
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "MyContactInfo.h"
#import "SnagletDataAccess.h"

@implementation MyContactInfo

-(bool)IsPhoneNumberSelected
{
    if(![NSString isNilOrEmpty:self.otherPhoneNumber] || ![NSString isNilOrEmpty:self.mobilePhoneNumber])
        return YES;
    
    return NO;
}

+ (UIImage *)getImage:(NSString*)contactId
{
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    CNContact *contact = [contactStore unifiedContactWithIdentifier:contactId keysToFetch:@[CNContactThumbnailImageDataKey] error:nil];
    
    UIImage *newImage = nil;
    if (contact.thumbnailImageData)
    {
        UIImage *defaultImage = [UIImage imageWithData:contact.thumbnailImageData];
        
        CGSize newSize = CGSizeMake(48, 48);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        [defaultImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return newImage;
}

@end
