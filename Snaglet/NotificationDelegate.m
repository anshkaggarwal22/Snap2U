//
//  NotificationDelegate.m
//  Snaglet
//
//  Created by Ansh Aggarwal on 6/3/23.
//  Copyright © 2023 Snaglet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NotificationDelegate.h"

@implementation NotificationDelegate

// Handle foreground presentation of notifications
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    // Customize the presentation options based on your app's requirements
    // For example, you can choose to display the notification banner, play a sound, or update the app's badge count
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

// Handle tapping on a notification to open the app
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    // Handle the notification response here
    // For example, you can extract information from the notification and perform app-specific actions
    
    // Call the completion handler after you have finished processing the notification
    completionHandler();
}

@end
