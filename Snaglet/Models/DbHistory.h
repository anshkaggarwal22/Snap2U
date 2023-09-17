//
//  DbHistory.h
//  Snaglet
//
//  Created by anshaggarwal on 7/17/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DbHistory : NSObject

@property (nonatomic, assign) NSInteger rowId;
@property (nonatomic, strong) NSString *albumId;
@property (nonatomic, strong) NSString *albumUrl;
@property (nonatomic, strong) NSString *assetUrl;
@property (nonatomic, strong) NSString *assetFileName;
@property (nonatomic, assign) NSInteger contactId;
@property (nonatomic, assign) NSString *cloudFileName;
@property (nonatomic, assign) double dateSentTimeStamp;

@end
