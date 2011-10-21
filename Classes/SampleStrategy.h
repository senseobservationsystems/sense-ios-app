//
//  MyClass.h
//  sensePlatform
//
//  Created by Pim Nijdam on 8/9/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SampleStrategy : NSObject {
    BOOL isEnabled;
    NSDate* startChargingTime;
    NSDate* lastTimeCharging;
    NSDate* recordedDate;
    float recordedBatteryLevel;
    
    float consumptionFactor;
    float P_user;
    long recordedTime;
    int chargeCycle;
    NSTimeInterval estimatedChargeCycle;
    
    NSTimer* checkTimer;
    UIDeviceBatteryState lastBatteryState;
    
    NSTimeInterval T_location, T_noise, T_motion;
}

- (void) check;
- (void) updateStrategy;
- (void) batteryStateChanged:(NSNotification*) notification;
- (void) settingChanged: (NSNotification*) notification;

@property (assign) BOOL isEnabled;

@end