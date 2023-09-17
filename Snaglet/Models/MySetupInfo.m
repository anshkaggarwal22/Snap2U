//
//  MySetupInfo.m
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "MySetupInfo.h"
#import "MyAlbumInfo.h"
#import "SnagletDataAccess.h"

@implementation MySetupInfo

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.contactsInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@end
