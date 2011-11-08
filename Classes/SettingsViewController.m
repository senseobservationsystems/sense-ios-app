//
//  SettingsViewController.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/16/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "SettingsViewController.h"
#import "LoginSettings.h"
#import "SensorStore.h"
#import "Settings.h"
#import "Preferences.h"
#import <UIKit/UIKit.h>

//sensors
#import "BatterySensor.h"
#import "CallSensor.h"
#import "ConnectionSensor.h"



@implementation SettingsViewController
@synthesize sensorClasses;

/* Settings menu */
enum Sections {
	generalSection=0,
	enableSection,
	NR_SECTIONS
};

enum GeneralSectionRow{ 
	generalSectionEnabled = 0,
	generalSectionLogin,
	generalSectionPreferences,
	//generalSectionSyncRate,
	NR_GENERALSECTION_ROWS
};

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	firstTimeCommonSense = YES;
	//load properties
	generalSettings = [Settings sharedSettings].general;
	
	//setup navigation bar
	self.navigationItem.title = @"Sense";
	webViewButton= [[UIBarButtonItem alloc] initWithTitle:@"CommonSense" style:UIBarButtonItemStylePlain target:self action:@selector(gotoWebView)];
	self.navigationItem.rightBarButtonItem = webViewButton;
	//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(displayWelcomeMessage)];
	
	//setup sensors
	NSArray* sensors = [SensorStore sharedSensorStore].allAvailableSensorClasses;
	//filter out motion sensors
	//NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"NOT (name == '')"];
	NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"NOT (name == 'orientation' OR name == 'accelerometer' OR name == 'acceleration' OR name == 'gyroscope'\
                                       OR name == 'battery' OR name == 'call state' OR name == 'connection type')"];

	self.sensorClasses = [sensors filteredArrayUsingPredicate:availablePredicate];
	//create single switch for motion sensors
	motionSwitch = [[UISwitch alloc]init];
	[motionSwitch setOn:[[Settings sharedSettings] isSensorEnabled:[AccelerometerSensor class]]];
	[motionSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if (false == [self supportsBackground]) {
        [self foregroundEnabled: motionSwitch.on];
    }
    
    //create single switch for phone state
    phoneStateSwitch = [[UISwitch alloc]init];
	[phoneStateSwitch setOn:[[Settings sharedSettings] isSensorEnabled:[BatterySensor class]]];
	[phoneStateSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

	//setup switches
	senseSwitch = [[UISwitch alloc]init];
	[senseSwitch setOn:[[generalSettings valueForKey:generalSettingSenseEnabledKey] boolValue]];
	[senseSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
	
	sensorEnableSwitches = [NSMutableArray new];
	for (Class sensorClass in sensorClasses) {
		UISwitch*  enableSwitch = [[UISwitch alloc]init];
		[enableSwitch setOn:[[Settings sharedSettings] isSensorEnabled:sensorClass]];
		[enableSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		[sensorEnableSwitches addObject:enableSwitch];
	}
    
    //register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationStateChanged:) name:applicationStateChangeNotification object:nil];
    
    
	NSString* displayed = [[Settings sharedSettings] getSettingType: @"messages" setting:@"welcomeMessageDisplayed"];
	if (![displayed isEqual:@"true"]) {
		[self displayWelcomeMessage];
		[[Settings sharedSettings] commitSettingType: @"messages" setting:@"welcomeMessageDisplayed" value:@"true" persistent:YES];
	}
    
	
	//show login immediately if we don't have a username
    NSLog(@"username: '%@'",[generalSettings valueForKey:generalSettingUsernameKey]);
	if ([[generalSettings valueForKey:generalSettingUsernameKey] isEqualToString:@""]) {
			//create LoginSettings
			LoginSettings* login = [[LoginSettings alloc] initWithNibName:@"LoginSettings" bundle:[NSBundle mainBundle]];
			[self.navigationController pushViewController:login animated:YES];
	}
}



- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
	//return YES;
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return NR_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
		case generalSection:
			return NR_GENERALSECTION_ROWS;
		case enableSection:
			return [sensorClasses count] + 2; //switches + motionSwitch + phoneStateSwitch
		default:
			return 0; //ai
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case generalSection:
			return @"General settings";
		case enableSection:
			return @"Sensors";
		default:
			return @"Unknown settings";
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
	cell.detailTextLabel.text = @"";
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if (indexPath.section == generalSection) {
		// Configure the cell...
		switch (indexPath.row) {
			case generalSectionEnabled:
			{
                cell.detailTextLabel.text = applicationState;
				cell.textLabel.text = @"Sense (main switch)";
				cell.accessoryView = senseSwitch;
				break;
			}
			case generalSectionLogin:
			{
                NSString* user = [generalSettings valueForKey:generalSettingUsernameKey];
				NSString* detail = [user isEqualToString:@""] ? @"No account" : user;
				cell.textLabel.text = @"Account";
				cell.detailTextLabel.text = detail;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				break;
			}
			case generalSectionPreferences:
			{
				cell.textLabel.text = @"Preferences";
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				break;
			}
		}
	} else if (indexPath.section == enableSection) {
        if (indexPath.row == 0) {
			cell.textLabel.text = @"Phone state";
			cell.accessoryView = phoneStateSwitch;
        } else if (indexPath.row == 1) {
			cell.textLabel.text = @"Motion";
            if (false == [self supportsBackground]) {
                cell.detailTextLabel.text = @"works only in foreground";
            }
			cell.accessoryView = motionSwitch;
		} else {
            NSInteger idx = indexPath.row - 2;
            Class sensorClass = [sensorClasses objectAtIndex:idx];
            cell.textLabel.text = [sensorClass displayName];
            if (sensorClass == [LocationSensor class])
                cell.detailTextLabel.text = @"Required for background mode";
            else
				cell.detailTextLabel.text = nil;//[sensorClass guiDescription];
            cell.accessoryView = [sensorEnableSwitches objectAtIndex:idx];
		}
	}
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void) switchChanged:(UISwitch*) switchButton {
	if (senseSwitch == switchButton)
		[[Settings sharedSettings] setSenseEnabled:switchButton.on];
	else if (motionSwitch == switchButton) {
		[[Settings sharedSettings] setSensor:[AccelerometerSensor class] enabled:switchButton.on];
		[[Settings sharedSettings] setSensor:[AccelerationSensor class] enabled:switchButton.on];
		[[Settings sharedSettings] setSensor:[RotationSensor class] enabled:switchButton.on];
		[[Settings sharedSettings] setSensor:[OrientationSensor class] enabled:switchButton.on];
		if (false == [self supportsBackground]) {
            [self foregroundEnabled: motionSwitch.on]; 
            if (switchButton.on) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Foreground" message:@"Motion sensors only work when this app is running in the foreground. Autolocking is disabled and the display will be    disabled when you put the device in your pocket." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                [alert show];
            }
        }
	} else if (phoneStateSwitch == switchButton) {
		[[Settings sharedSettings] setSensor:[BatterySensor class] enabled:switchButton.on];
		[[Settings sharedSettings] setSensor:[CallSensor class] enabled:switchButton.on];
		[[Settings sharedSettings] setSensor:[ConnectionSensor class] enabled:switchButton.on];
    }
    else {
		NSInteger sensorClassIdx = [sensorEnableSwitches indexOfObject:switchButton];
		if (sensorClassIdx == NSNotFound) {
			NSLog(@"Internal error in gui switch logic");
		}
		Class sensorClass = [sensorClasses objectAtIndex:sensorClassIdx];
		NSLog(@"switch for %@ changed", sensorClass);
		[[Settings sharedSettings] setSensor:sensorClass enabled:switchButton.on];
	}
	//[self edited];
}

- (BOOL) supportsBackground {
    //it seems that as of ios5.0 motion sensor work in the background
    return [[UIDevice currentDevice].systemVersion floatValue] >= 5;
}

- (void) foregroundEnabled:(BOOL) enable {
	//disable auto lock
	[UIApplication sharedApplication].idleTimerDisabled = enable;
	//enable prximity monitoring to disable screen (to save battery)
	[UIDevice currentDevice].proximityMonitoringEnabled = enable;
}


#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == generalSection) {
		switch (indexPath.row) {
			case generalSectionLogin: {
				//create LoginSettings
				LoginSettings* login = [[LoginSettings alloc] initWithNibName:@"LoginSettings" bundle:[NSBundle mainBundle]];
				[self.navigationController pushViewController:login animated:YES];
				[self edited];
				break;
			}
			case generalSectionPreferences: {
				Preferences* prefs = [[Preferences alloc] init];
				[self.navigationController pushViewController:prefs animated:YES];
				break;
			}
		}
	}
				
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}



- (void) edited {
	generalSettings = [Settings sharedSettings].general;
	[self.tableView reloadData];
}

- (void) gotoWebView {
	//instantiate webview
	if (webViewController == nil)
		webViewController = [[WebViewController alloc] init];
	//switch to webview
	[self.navigationController pushViewController:webViewController animated:YES];
	//show some info on commonSense
	if (firstTimeCommonSense) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"CommonSense" message:@"At CommonSense you can manage, view and share your data. You can learn CommonSense to recognise your state (e.g. your pose). Although accessible through your phone it is recommended to use a pc to access CommonSense." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
		firstTimeCommonSense = NO;
	}
		
}

- (void) displayWelcomeMessage {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Welcome" message:@"This app gathers data about your activities and shares it with the CommonSense data storage.\n\nOver time, it will learn to recognize your behaviour and current status. This makes it possible for your phone to help you avoid repetitive or stupid tasks, and alert you about interesting events.\n\nPlease login, or register a free CommonSense account. Manage, view and share your data at CommonSense\'s web interface: http://common.sense-os.nl." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
	[alert show];
	
}

- (void) applicationStateChanged:(NSNotification*) notification {
   ApplicationStateChangeMsg* msg = notification.object;
    NSString* newState;
    switch (msg.applicationStateChange) {
        case kUPLOAD_OK:
            newState = nil;
            break;
        case kUPLOAD_FAILED:
            newState = @"Upload problems";
            break;
    }
        
    if ((newState == nil && applicationState != nil) || (newState != nil && applicationState == nil)) {
        applicationState = newState;
        [self edited];
    }
}

@end