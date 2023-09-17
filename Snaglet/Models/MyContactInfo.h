//
//  MyContactInfo.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyContactInfo : NSObject

@property (nonatomic, assign) long Id;
@property (nonatomic, assign) long serverId;
@property (nonatomic, strong) NSString* phoneContactId;
@property (nonatomic, assign) long albumId;

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

@property (nonatomic, strong) NSString *mobilePhoneNumber;
@property (nonatomic, strong) NSString *otherPhoneNumber;

@property (nonatomic, assign) double createdDate;
@property (nonatomic, assign) double modifiedDate;

+(UIImage*)getImage:(NSString*)contactId;

-(bool)IsPhoneNumberSelected;

@end
