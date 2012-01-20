//  SettingsViewController.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/16/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SensorStore.h"
#import "WebViewController.h"
#import "ApplicationStateChange.h"
#import "ActivityFeedbackController.h"


@interface SettingsViewController : UITableViewController {
	NSDictionary* generalSettings;
	
	UIBarButtonItem* webViewButton;
	WebViewController* webViewController;
    ActivityFeedbackController* activityFeedbackController;
	
	//sensors
	NSArray* sensorClasses;
	NSMutableArray* sensorEnableSwitches;
	UISwitch* senseSwitch;
	UISwitch* motionSwitch;
    UISwitch* phoneStateSwitch;
	
	BOOL firstTimeCommonSense;
    NSString* applicationState;
}
@property (retain) NSArray* sensorClasses;

- (void) edited;
- (void) gotoWebView;
- (void) displayWelcomeMessage;

- (void) switchChanged:(UISwitch*) switchButton;
- (BOOL) supportsBackground;
- (void) foregroundEnabled:(BOOL) enable;
- (void) applicationStateChanged:(NSNotification*) notification;
@end