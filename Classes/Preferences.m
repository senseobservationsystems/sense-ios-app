//
//  Preferences.m
//  senseApp
//
//  Created by Pim Nijdam on 5/12/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "Preferences.h"
#import "PickerTable.h"

@implementation Preferences
/* Settings menu */
enum Sections {
	generalSection=0,
	sensorSection,
	NR_SECTIONS
};

enum GeneralSectionRow{ 
	generalSectionWifi = 0,
	NR_GENERALSECTION_ROWS
};

enum SensorSectionRow{ 
	sensorSectionPositionAccuracy = 0,
	sensorSectionMotionPollInterval,
	NR_SENSORSECTION_ROWS
};

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Preferences";
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
		case sensorSection:
			return NR_SENSORSECTION_ROWS;
		default:
			return 0; //ai
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case generalSection:
			return @"General";
		case sensorSection:
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.detailTextLabel.text = @"";
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	if (indexPath.section == generalSection) {
		switch (indexPath.row) {
			case generalSectionWifi: {
				cell.textLabel.text = @"Upload interval";
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				break;
			}
		}
	} else if (indexPath.section == sensorSection) {
		switch (indexPath.row) {
			case sensorSectionPositionAccuracy:
				cell.textLabel.text = @"Position accuracy";
				break;
			case sensorSectionMotionPollInterval:
				cell.textLabel.text = @"Motion update interval";
				break;
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



#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == generalSection) {
		switch (indexPath.row) {
			case generalSectionWifi: {
				int prePicked = -1;
				//get current option
				NSString* currentOption = [[Settings sharedSettings] getSettingType:@"general" setting:generalSettingSynchronisationRateKey];
				int optionValue = currentOption == nil ? -1 : [currentOption intValue];
				switch (optionValue) {
					case 10:
						prePicked = 0;
						break;
					case 60:
						prePicked = 1;
						break;
					case 300:
						prePicked = 2;
						break;
					case 900:
						prePicked = 3;
						break;
				}

				NSArray* options = [[NSArray alloc] initWithObjects:@"every 10 seconds", @"every minute", @"every 5 minutes (recommended)", @"every 15 minutes", nil];
				PickerTable* picker = [[PickerTable alloc] initWithStyle:UITableViewStyleGrouped name:@"Upload" options: options prePicked: prePicked];
				picker.callback = ^void (int picked) {
					int interval;
					if (picked == 0) interval = 10;
					else if (picked == 1) interval = 60;
					else if (picked == 2) interval = 300;
					else if (picked == 3) interval = 900;
					else {
						NSLog(@"Error unknown option picked for synchronisation rate.");
						interval = 300;
					}

					[[Settings sharedSettings] commitSettingType:@"general" setting:generalSettingSynchronisationRateKey value:[NSString stringWithFormat:@"%d",interval]];
				};
				[self.navigationController pushViewController:picker animated:YES];
				[picker release];
				[options release];

			} break;
		}
	} else if (indexPath.section == sensorSection) {
		switch (indexPath.row) {
			case sensorSectionPositionAccuracy: {
				int prePicked = -1;
				//get current option
				NSString* currentOption = [[Settings sharedSettings] getSettingType:@"position" setting:@"accuracy"];
				int optionValue = currentOption == nil ? -1 : [currentOption intValue];
				switch (optionValue) {
					case 0:
						prePicked = 0;
						break;
					case 50:
						prePicked = 1;
						break;
					case 100:
						prePicked = 2;
						break;
					case 500:
						prePicked = 3;
						break;
					case 1000:
						prePicked = 4;
						break;
				}
				
				NSArray* options = [[NSArray alloc] initWithObjects:@"best", @"50 meter", @"100 meter (recommended)", @"500 meter", @"1 km", nil];
				PickerTable* picker = [[PickerTable alloc] initWithStyle:UITableViewStyleGrouped name:@"Position accuracy" options: options prePicked: prePicked];
				picker.callback = ^void (int picked) {
					int accuracy;
					if (picked == 0) accuracy = 0;
					else if (picked == 1) accuracy = 50;
					else if (picked == 2) accuracy = 100;
					else if (picked == 3) accuracy = 500;
					else if (picked == 4) accuracy = 1000;
					else {
						NSLog(@"Error unknown option picked for position accuracy.");
						accuracy = 100;
					}
					
					[[Settings sharedSettings] commitSettingType:@"position" setting:@"accuracy" value:[NSString stringWithFormat:@"%d",accuracy]];
				};
				[self.navigationController pushViewController:picker animated:YES];
				[picker release];
				[options release];
			} break;
			case sensorSectionMotionPollInterval: {
				int prePicked = -1;
				//get current option
				NSString* currentOption = [[Settings sharedSettings] getSettingType:@"spatial" setting:@"pollInterval"];
				int optionValue = currentOption == nil ? -1 : [currentOption intValue];
				switch (optionValue) {
					case 1:
						prePicked = 0;
						break;
					case 10:
						prePicked = 1;
						break;
					case 60:
						prePicked = 2;
						break;
					case 300:
						prePicked = 3;
						break;
				}
				
				NSArray* options = [[NSArray alloc] initWithObjects:@"every second", @"every 10 seconds", @"every minute (recommended)", @"every 5 minutes", nil];
				PickerTable* picker = [[PickerTable alloc] initWithStyle:UITableViewStyleGrouped name:@"Motion update" options: options prePicked: prePicked];
				picker.callback = ^void (int picked) {
					int interval;
					if (picked == 0) interval = 1;
					else if (picked == 1) interval = 10;
					else if (picked == 2) interval = 60;
					else if (picked == 3) interval = 300;
					else {
						NSLog(@"Error unknown option picked for spatial update frequency.");
						interval = 60;
					}
					
					[[Settings sharedSettings] commitSettingType:@"spatial" setting:@"pollInterval" value:[NSString stringWithFormat:@"%d",interval]];
				};
				[self.navigationController pushViewController:picker animated:YES];
				[picker release];
				[options release];
				
		} break;
		

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


- (void)dealloc {
    [super dealloc];
}

@end
