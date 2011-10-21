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
    adaptiveSection,
	NR_SECTIONS
};

enum GeneralSectionRow{ 
	generalSectionWifi = 0,
	NR_GENERALSECTION_ROWS
};

enum SensorSectionRow{ 
	sensorSectionPositionAccuracy = 0,
	sensorSectionMotionPollInterval,
    sensorSectionNoisePollInterval,
	NR_SENSORSECTION_ROWS
};

enum AdaptiveSectionRow {
    adaptiveSectionEnableAdaptive = 0,
    adaptiveSectionLocationMotion,
    adaptiveSectionChargeCycle,
  	NR_ADAPTIVESECTION_ROWS
};

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Preferences";
    
    //initialise switches
	adaptiveSwitch = [[UISwitch alloc]init];
	[adaptiveSwitch setOn:[[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"energyAdaptive"] boolValue]];
	[adaptiveSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    locationMotionSwitch = [[UISwitch alloc]init];
	[locationMotionSwitch setOn:[[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"locationAdaptive"] boolValue]];
	[locationMotionSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    //charge cycle slider
    chargeCycleSlider = [[UISlider alloc] init];
    chargeCycleSlider.minimumValue = 1;
    chargeCycleSlider.maximumValue = 48;
    chargeCycleSlider.continuous = NO;
    //[chargeCycleSlider setShowValue:YES];
    [chargeCycleSlider setValue: [[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"chargeCycle"] floatValue] / 3600
     ];
    [chargeCycleSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
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
        case adaptiveSection:
            return NR_ADAPTIVESECTION_ROWS;
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
        case adaptiveSection:
			return @"Adaptive (experimental)";
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
            case sensorSectionNoisePollInterval:
				cell.textLabel.text = @"Noise update interval";
				break;
		}
	} else if (indexPath.section == adaptiveSection) {
		switch (indexPath.row) {
			case adaptiveSectionEnableAdaptive: {
				cell.textLabel.text = @"Adapt to energy";
                cell.accessoryView = adaptiveSwitch;
				break;
			}
            case adaptiveSectionLocationMotion: {
				cell.textLabel.text = @"Location adapt to motion";
                cell.accessoryView = locationMotionSwitch;
				break;
			}
            case adaptiveSectionChargeCycle: {
                cell.textLabel.text = @"Charge cycle";
                cell.accessoryView = chargeCycleSlider;
				break;
            }
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

					[[Settings sharedSettings] commitSettingType:@"general" setting:generalSettingSynchronisationRateKey value:[NSString stringWithFormat:@"%d",interval] persistent:YES];
				};
				[self.navigationController pushViewController:picker animated:YES];

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
					
					[[Settings sharedSettings] commitSettingType:@"position" setting:@"accuracy" value:[NSString stringWithFormat:@"%d",accuracy] persistent:YES];
				};
				[self.navigationController pushViewController:picker animated:YES];
			} break;
			case sensorSectionMotionPollInterval: {
				NSInteger prePicked = -1;
				//get current option
				NSString* currentOption = [[Settings sharedSettings] getSettingType:@"spatial" setting:@"pollInterval"];
				NSTimeInterval optionValue = currentOption == nil ? -1 : [currentOption doubleValue];
                double epsilon = 0.001;
				if (fabsf(optionValue - 1) < epsilon) {
                    prePicked = 0;
                } else if (fabsf(optionValue - 15) < epsilon) {
                    prePicked = 1;
                } else if (fabsf(optionValue - 60) < epsilon) {
                    prePicked = 2;
                } else if (fabsf(optionValue - 300) < epsilon) {
                    prePicked = 3;
                } else {
                    prePicked = 2;
                }
				
				NSArray* options = [[NSArray alloc] initWithObjects:@"every second", @"every 15 seconds", @"every minute ", @"every 5 minutes", nil];
				PickerTable* picker = [[PickerTable alloc] initWithStyle:UITableViewStyleGrouped name:@"Motion update" options: options prePicked: prePicked];
				picker.callback = ^void (int picked) {
					NSTimeInterval interval;
					if (picked == 0) interval = 1;
					else if (picked == 1) interval = 15;
					else if (picked == 2) interval = 60;
					else if (picked == 3) interval = 300;
					else {
						NSLog(@"Error unknown option picked for spatial update frequency.");
						interval = 15;
					}
					
					[[Settings sharedSettings] commitSettingType:@"spatial" setting:@"pollInterval" value:[NSString stringWithFormat:@"%g",interval] persistent:YES];
				};
				[self.navigationController pushViewController:picker animated:YES];
				
		} break;
            case sensorSectionNoisePollInterval: {
				int prePicked = -1;
				//get current option
				NSString* currentOption = [[Settings sharedSettings] getSettingType:@"noise" setting:@"interval"];
				int optionValue = currentOption == nil ? -1 : [currentOption intValue];
				switch (optionValue) {
					case 5:
						prePicked = 0;
						break;
					case 30:
						prePicked = 1;
						break;
					case 60:
						prePicked = 2;
						break;
					case 300:
						prePicked = 3;
						break;
				}
				
				NSArray* options = [[NSArray alloc] initWithObjects:@"every 5 seconds", @"every 30 seconds", @"every minute", @"every 5 minutes", nil];
				PickerTable* picker = [[PickerTable alloc] initWithStyle:UITableViewStyleGrouped name:@"noise update" options: options prePicked: prePicked];
				picker.callback = ^void (int picked) {
					int interval;
					if (picked == 0) interval = 5;
					else if (picked == 1) interval = 30;
					else if (picked == 2) interval = 60;
					else if (picked == 3) interval = 300;
					else {
						NSLog(@"Error unknown option picked for noise sample interval.");
						interval = 60;
					}
					
					[[Settings sharedSettings] commitSettingType:@"noise" setting:@"interval" value:[NSString stringWithFormat:@"%d", interval] persistent:YES];
				};
				[self.navigationController pushViewController:picker animated:YES];
			} break;		
		}
	} 
}

- (void) switchChanged:(UISwitch*) switchButton {
    NSString* on = switchButton.on ? @"1" : @"0";
	if (switchButton == adaptiveSwitch) {
        [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"energyAdaptive" value:on persistent:YES];
        
    } else if (switchButton == locationMotionSwitch) {
        [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"locationAdaptive" value:on persistent:YES];
        
    }
}

- (void) sliderChanged:(UISlider*) slider {
    NSString* value = [NSString stringWithFormat:@"%f", round(slider.value) * 3600];
    if (slider == chargeCycleSlider) {
        [chargeCycleSlider setValue:round(slider.value)];
        [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"chargeCycle" value:value persistent:YES];
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



@end
