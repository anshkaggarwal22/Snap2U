//
//  SetupAlbumManager.m
//  Snaglet
//
//  Created by anshaggarwal on 7/29/22.
//  Copyright (c) 2022 Snaglet. All rights reserved.
//

#import "SetupAlbumManager.h"
#import "MySetupInfo.h"
#import "SnagletRepository.h"
#import "MyAlbumInfo.h"
#import "SnagletManager.h"
#import "AppDelegate.h"

@interface SetupAlbumManager ()

@property (nonatomic, strong) MySetupInfo *setupInfo;

@end


@implementation SetupAlbumManager

-(id)initWithSetupInfo:(MySetupInfo*)setupInfo
{
    self = [super init];
    if (self)
    {
        self.setupInfo = setupInfo;
    }
    return self;
}

-(void)setupAlbum
{
    if (self.setupInfo != nil)
    {
        // Create Album
        if(self.setupInfo.albumInfo != nil && ![NSString isNilOrEmpty:self.setupInfo.albumInfo.albumName])
        {
            dispatch_async(dispatch_get_global_queue( QOS_CLASS_DEFAULT, 0),
           ^{
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    if ([self.delegate respondsToSelector:@selector(albumCreationBegin:)])
                    {
                        [self.delegate albumCreationBegin:self.setupInfo.albumInfo];
                    }
                });

                  SnagletRepository *repository = [[SnagletRepository alloc] init];
                  
                  [repository createAlbum:self.setupInfo.albumInfo.albumName
                                  success:^(MyAlbumInfo *album)
                   {
                       if(album != nil && album.serverId > 0)
                       {
                           dispatch_async(dispatch_get_main_queue(),
                          ^{
                              if ([self.delegate respondsToSelector:@selector(albumCreationEnd:albumInfo:)])
                              {
                                  [self.delegate albumCreationEnd:nil albumInfo:self.setupInfo.albumInfo];
                              }
                          });
                           
                           [self.setupInfo.contactsInfo enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop)
                           {
                               MyContactInfo *contactInfo = (MyContactInfo*)object;
                               
                               dispatch_async(dispatch_get_main_queue(),
                              ^{
                                  if ([self.delegate respondsToSelector:@selector(contactCreationBegin:)])
                                  {
                                      [self.delegate contactCreationBegin:contactInfo];
                                  }
                              });

                               [repository addContact:album.serverId contactInfo:contactInfo
                                              success:^(MyContactInfo *contactInfo)
                                {
                                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       if ([self.delegate respondsToSelector:@selector(contactCreationEnd:contactInfo:)])
                                       {
                                           [self.delegate contactCreationEnd:nil contactInfo:contactInfo];
                                       }
                                   });
                                }
                                failure:^(NSError *error)
                                {
                                    dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                       if ([self.delegate respondsToSelector:@selector(contactCreationEnd:contactInfo:)])
                                       {
                                           [self.delegate contactCreationEnd:error contactInfo:contactInfo];
                                       }
                                    });
                                }];
                               
                           }];
                           
                           if ([self.setupInfo.photosInfo count] > 0)
                           {
                               for (MyPhotoInfo *photoInfo in self.setupInfo.photosInfo)
                               {
                                   photoInfo.albumId = album.serverId;
                               }
                               UIApplication *application = [UIApplication sharedApplication];
                               AppDelegate *appDelegate = (AppDelegate*)[application delegate];

                               for (MyPhotoInfo *photoInfo in self.setupInfo.photosInfo)
                               {
                                   SnagletManager *manager = [appDelegate getUploadManager];

                                   [manager uploadSnaglets:[NSArray arrayWithObjects:photoInfo, nil] albumId:photoInfo.albumId];
                               }
                           }
                       }
                   }
                  failure:^(NSError *error)
                   {
                        dispatch_async(dispatch_get_main_queue(),
                        ^{
                          if ([self.delegate respondsToSelector:@selector(albumCreationBegin:)])
                          {
                              [self.delegate albumCreationEnd:error albumInfo:self.setupInfo.albumInfo];
                          }
                        });
                   }];
           });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(),
           ^{
               if ([self.delegate respondsToSelector:@selector(albumDataInvalid:)])
               {
                   [self.delegate albumDataInvalid:self.setupInfo.albumInfo];
               }
           });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),
        ^{
           if ([self.delegate respondsToSelector:@selector(albumDataInvalid:)])
           {
               [self.delegate albumDataInvalid:self.setupInfo.albumInfo];
           }
        });
    }
}

@end
