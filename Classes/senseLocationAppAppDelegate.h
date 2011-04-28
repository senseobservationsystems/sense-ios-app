//
//  senseLocationAppAppDelegate.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "WebViewController.h"
#import "SensorStore.h"

@interface senseLocationAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *navigationController;
	
	SettingsViewController* settingsViewController;
	
	SensorStore* sensorStore;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet SettingsViewController* settingsViewController;

@end

