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

@interface senseLocationAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *navigationController;
	
	SettingsViewController* settingsViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;
@property (nonatomic, strong) IBOutlet SettingsViewController* settingsViewController;

@end

