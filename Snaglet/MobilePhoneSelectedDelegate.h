//
//  MobilePhoneSelectedDelegate.h
//  Snaglet
//
//  Created by anshaggarwal on 7/20/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyContactInfo.h"

@protocol MobilePhoneSelectedDelegate <NSObject>

@optional

-(void)mobilePhoneAdded:(MyContactInfo*)contact;
-(void)mobilePhoneUpdated:(MyContactInfo*)contact;
-(void)mobilePhoneDeleted:(NSString*)phoneContactId success:(BOOL)success;

@end
