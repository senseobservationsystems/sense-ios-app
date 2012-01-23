//
//  ActivityFeedbackController.h
//  sensePlatform
//
//  Created by Pim Nijdam on 1/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Activity.h"

@interface ActivityFeedbackController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    UIPickerView*       activityPicker;
    NSArray*            activities;
    UILabel*            currentActivityLabel;
    UILabel*            lastActivityLabel;
    UILabel*            batteryConsumptionLabel;
    UIButton*            startStopButton;
    UIButton*            cancelButton;
    
    Activity*   currentActivity;
    Activity*   lastActivity;
    
    //for calculating power consumption
    NSMutableArray* consumptionWindow;
}

@property (strong, nonatomic) IBOutlet UIPickerView* activityPicker;
@property (strong, nonatomic) IBOutlet UILabel* currentActivityLabel;
@property (strong, nonatomic) IBOutlet UILabel* lastActivityLabel;
@property (strong, nonatomic) IBOutlet UILabel* batteryConsumptionLabel;
@property (strong, nonatomic) NSArray* activities;
@property (strong, nonatomic) IBOutlet UIButton* startStopButton;
@property (strong, nonatomic) IBOutlet UIButton* cancelButton;
- (IBAction) startStopAction:(id)sender;
- (IBAction) cancelAction:(id)sender;

- (void) batteryStateChanged:(NSNotification*) notification;
@end  