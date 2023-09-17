//
//  MyAlbumInfo.m
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "MyAlbumInfo.h"
#import "SnagletDataAccess.h"

@implementation MyAlbumInfo


-(NSInteger)photosInQueueCount
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    return [dataAccess getPhotosInQueueCount:self.serverId];
}

-(NSInteger)photosCount
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    return [dataAccess getPhotosCount:self.serverId];
}

-(NSInteger)recipientsCount
{
    SnagletDataAccess *dataAccess = [SnagletDataAccess sharedSnagletDbAccess];
    
    return [dataAccess getRecipientsCount:self.serverId];
}

@end
