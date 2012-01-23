//
//  ActivityFeedbackController.m
//  sensePlatform
//
//  Created by Pim Nijdam on 1/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "ActivityFeedbackController.h"
#import "SensorStore.h"
#import "ActivityFeedback.h"


@implementation ActivityFeedbackController
@synthesize activities;
@synthesize activityPicker;
@synthesize currentActivityLabel;
@synthesize lastActivityLabel;
@synthesize batteryConsumptionLabel;
@synthesize startStopButton;
@synthesize cancelButton;

static const NSUInteger windowSize = 4;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        consumptionWindow = [NSMutableArray arrayWithCapacity:windowSize];

        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(batteryStateChanged:)
													 name:UIDeviceBatteryStateDidChangeNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.activities = [[NSArray alloc] initWithObjects:
                         @"Idle", @"Walking", @"Running",
                         @"Biking", @"Else", nil];
    batteryConsumptionLabel.text = @"Unknown";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [activities count];
}
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [activities objectAtIndex:row];
}

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{   
}

- (IBAction) startStopAction:(id)sender {
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    if (currentActivity == nil) {
        //create activity
        currentActivity = [Activity new];
        currentActivity.type = [activities objectAtIndex:[activityPicker selectedRowInComponent:0]];
        currentActivity.start = [NSDate new];
        //update button text
        [startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        currentActivityLabel.text = [NSString stringWithFormat:@"%@ since %@", currentActivity.type, [dateFormatter stringFromDate:currentActivity.start]];
    } else {
        currentActivity.stop = [NSDate new];
        lastActivity = currentActivity;
        currentActivity = nil;
        //update state
        lastActivityLabel.text = [NSString stringWithFormat:@"%@ from %@ till %@", lastActivity.type, [dateFormatter stringFromDate:lastActivity.start], [dateFormatter stringFromDate:lastActivity.stop]];
        currentActivityLabel.text = @"None";
        //update button
        [startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        //commit activity
        [ActivityFeedback commitActivity:lastActivity];
    }
}

- (IBAction)cancelAction:(id)sender {
    currentActivityLabel.text = @"None";
    if (currentActivity != nil) { //check there is something to cancel...
        currentActivity = nil;
        //update button
        [startStopButton setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (void) batteryStateChanged:(NSNotification*) notification {
    UIDevice* currentDevice = [UIDevice currentDevice];
    UIDeviceBatteryState batteryState = [currentDevice batteryState];
    
    float batteryLevel = [currentDevice batteryLevel] * 100;
    BOOL plugged = batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
    if (plugged) {
        batteryConsumptionLabel.text = @"Charging";
        [consumptionWindow removeAllObjects];
        return;
    }
    NSDate* now = [NSDate new];
    //create entry with date and battery level
    NSMutableDictionary* entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:now, @"date",
                                 [NSNumber numberWithFloat:batteryLevel], @"level",
                                 nil];
    //remove least recent sample
	if ([consumptionWindow count] >= windowSize)
		[consumptionWindow removeLastObject];
	//insert this sample at beginning
	[consumptionWindow insertObject:entry atIndex:0];
    
    //compute power over the last samples
    if ([consumptionWindow count] > 1 ) {
        //get least recent entry
        NSDictionary* lrEntry = [consumptionWindow lastObject];
        NSTimeInterval dt = [[lrEntry objectForKey:@"date"] timeIntervalSinceNow];
        double dE = [[lrEntry objectForKey:@"level"] doubleValue] - batteryLevel;
        if (dt >0 && dE > 0) {
            batteryConsumptionLabel.text = [NSString stringWithFormat:@"%.1f hours (based on last %.0f %)", 24 / (dE / dt), dE];
        }else {
             batteryConsumptionLabel.text = [NSString stringWithFormat:@"Unknown"];
        }
    }
}

@end
