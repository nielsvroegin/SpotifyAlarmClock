//
//  AppDelegate.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 13-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "AppDelegate.h"
#import "appkey.h"
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "CocoaLibSpotify.h"
#import "Tools.h"
#import "Alarm.h"

@interface AppDelegate ()

@property (nonatomic, strong) AVAudioPlayer * audioPlayer;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize clockVisible;
@synthesize audioPlayer;
@synthesize startedWithAlarm;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Audio will also play when mute switch is on
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //Set default settings when no value yet present
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:@"BackupAlarmSound"] == nil)
        [userDefaults setInteger:0 forKey:@"BackupAlarmSound"];
    
    if([userDefaults objectForKey:@"BlinkSecondsMarker"] == nil)
        [userDefaults setBool:YES forKey:@"BlinkSecondsMarker"];
    
    if([userDefaults objectForKey:@"ShowBackgroundGlow"] == nil)
        [userDefaults setBool:YES forKey:@"ShowBackgroundGlow"];
    
    if([userDefaults objectForKey:@"MaxVolume"] == nil)
        [userDefaults setFloat:0.5 forKey:@"MaxVolume"];
    
    if([userDefaults objectForKey:@"Brightness"] == nil)
        [userDefaults setFloat:[[UIScreen mainScreen] brightness] forKey:@"Brightness"];
    
    if([userDefaults objectForKey:@"UseAlarmClockWithoutSpotify"] == nil)
        [userDefaults setBool:NO forKey:@"UseAlarmClockWithoutSpotify"];
    
    if([userDefaults objectForKey:@"BackgroundAlarm"] == nil)
        [userDefaults setBool:YES forKey:@"BackgroundAlarm"];
    
    [userDefaults synchronize];
    
    //Set brightness for app
    [[UIScreen mainScreen] setBrightness:[[NSUserDefaults standardUserDefaults] floatForKey:@"Brightness"]];
    
    //Initialize spotify session spotify
    NSError *error = nil;
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_appkey length:g_appkey_size]  userAgent:@"nl.startsmart.SpotifyAlarmClock" loadingPolicy:SPAsyncLoadingManual error:&error];
    if(error != nil)
    {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not initialize spotify!" delegate:nil cancelButtonTitle:@"Oke!" otherButtonTitles:nil] show];
        NSLog(@"Could not initialize spotify, error: %@", error);
    }
    else
    {
        //Login when credentials are available
        if([[userDefaults objectForKey:@"SpotifyUsername"] length] > 0 && [[userDefaults objectForKey:@"SpotifyPassword"] length] > 0)
            [[SPSession sharedSession] attemptLoginWithUserName:[userDefaults objectForKey:@"SpotifyUsername"] existingCredential:[userDefaults objectForKey:@"SpotifyPassword"]];
        else
            [[SPSession sharedSession] logout:nil];
    }
    
    //Register notification types
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationSettings * notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    }
    
    //Check for start by notification
    UILocalNotification *locationNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (locationNotification)
    {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *time = [NSDate date];
        NSDateComponents * timeComponents = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit fromDate:time];
        NSDateComponents * alarmDateComponents = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit fromDate:[locationNotification fireDate]];
        
        if (timeComponents.weekday == alarmDateComponents.weekday && timeComponents.hour == alarmDateComponents.hour && timeComponents.minute == alarmDateComponents.minute)
        {
            NSURL * alarmUrl = [NSURL URLWithString:[locationNotification.userInfo objectForKey:@"Alarm"]];
            Alarm * alarm = (Alarm *)[[self managedObjectContext] objectWithURI:alarmUrl];
            
            if(alarm != nil)
                self.startedWithAlarm = alarm;
        }
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //Set brightness for app
    [[UIScreen mainScreen] setBrightness:[[NSUserDefaults standardUserDefaults] floatForKey:@"Brightness"]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIApplicationState state = [application applicationState];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *time = [NSDate date];
    NSDateComponents * timeComponents = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit fromDate:time];
    NSDateComponents * alarmDateComponents = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSWeekdayCalendarUnit fromDate:[notification fireDate]];
    
    if (state == UIApplicationStateInactive && (timeComponents.weekday != alarmDateComponents.weekday || timeComponents.hour != alarmDateComponents.hour || timeComponents.minute != alarmDateComponents.minute))
        return;
    
    //Return when clock visible
    if(clockVisible)
        return;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alarm" message:@"Your alarm goes off!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"background" withExtension:@"mp3"] fileTypeHint:@"AVFileTypeMPEGLayer3" error:nil];
    audioPlayer.numberOfLoops = -1;
    [audioPlayer play];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0)
    {
        [audioPlayer stop];
        audioPlayer = nil;
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SpotifyAlarmClock" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SpotifyAlarmClock.sqlite"];
    
    
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
