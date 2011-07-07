//
//  senseLocationAppAppDelegate.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "senseLocationAppAppDelegate.h"

@implementation senseLocationAppAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize settingsViewController;



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	//We need the sensorstore to be up and running, so make sure it is created.
	sensorStore = [[SensorStore sharedSensorStore] retain];

	[window addSubview:[navigationController view]];
   
    [self.window makeKeyAndVisible];

	NSLog(@"app launched");
  
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	NSLog(@"App entered background");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
	[[SensorStore sharedSensorStore] forceDataFlush];
	NSLog(@"App terminated");
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	NSLog(@"Received memory warning.");
	[[SensorStore sharedSensorStore] forceDataFlush];
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
