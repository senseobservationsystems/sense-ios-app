//
//  MyClass.m
//  sensePlatform
//
//  Created by Pim Nijdam on 8/9/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "SampleStrategy.h"
#import <math.h>

static const int reservedEnergy = 20;
static const float aggressiveness = 0.7; //slightly conservative

//energy model
static const float P_location = 15.0 / 3600 * 60, P_noise = 2.4 / 3600, P_motion = 3.5 / 3600, P_compass=2.5/3600;

@implementation SampleStrategy

- (id) init {
	self = [super init];
	if (self) {        
        consumptionFactor = 1;
        recordedTime = 0;
        //initialise from storage
        NSString* s1 = [[Settings sharedSettings] getSettingType:@"adaptive" setting:@"consumptionFactor"];
        NSString* s2 = [[Settings sharedSettings] getSettingType:@"adaptive" setting:@"recordedTime"];
        NSString* s3 = [[Settings sharedSettings] getSettingType:@"adaptive" setting:@"P_user"];
        NSString* s4 = [[Settings sharedSettings] getSettingType:@"adaptive" setting:@"estimatedChargeCycle"];
        if (s1 != nil && s2 != nil) {
            consumptionFactor = [s1 doubleValue];
            recordedTime = [s2 intValue];
        }
        
        P_user = s3 != nil ? [s3 doubleValue] : 1. / 3600;
        
        estimatedChargeCycle = s4 != nil ? estimatedChargeCycle = [s4 doubleValue] : 16 * 3600;
        
        chargeCycle = [[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"chargeCycle"] intValue];
        NSLog(@"consumptionFactor = %@, recordedTime = %@", s1, s2);

        
        [self setIsEnabled:[[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"energyAdaptive"] boolValue]];
	}
	return self;
}

- (void) check {
    UIDevice* currentDevice = [UIDevice currentDevice];
    UIDeviceBatteryState batteryState = [currentDevice batteryState];
    
    float batteryLevel = [currentDevice batteryLevel] * 100;
    BOOL plugged = batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
    
    
    // record expected and observed power consumption (done here so it is done before adjusting the settings)
    if (!plugged) {
        NSTimeInterval dt = -[recordedDate timeIntervalSinceNow];
        float observedConsumption = recordedBatteryLevel - batteryLevel;
        //TODO: if enabled checks
        float expectedConsumption =  P_location * dt / T_location +
                     P_noise * dt / T_noise +
                     P_motion * dt / T_motion;
        //if (observedConsumption > 0) this if statement isn't a good idea, we update this every time we don't skip any change in the variables
        {
            float observedConsumptionFactor = observedConsumption / expectedConsumption;
            
            //low pass filter for consumption factor. alpha depends on the timeframe, the maximum time is the magic parameter here (12 hours gives a half-time of approx 9 hours)
            float dt2 = MIN(recordedTime, 12 * 60 * 60);
            float alpha = dt2 / (dt + dt2);
            //calculate weighted average for consumption factor
            consumptionFactor = alpha * consumptionFactor + (1-alpha) * observedConsumptionFactor;
            recordedTime += dt;
            P_user = alpha * P_user + (1-alpha) * (observedConsumption - expectedConsumption)/dt;
            
            recordedBatteryLevel = batteryLevel;
            recordedDate = [NSDate date];
            
            [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"consumptionFactor" value:[NSString stringWithFormat:@"%g", consumptionFactor] persistent:YES];
            [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"P_user" value:[NSString stringWithFormat:@"%g", P_user] persistent:YES];
            [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"recordedTime" value:[NSString stringWithFormat:@"%d", recordedTime] persistent:YES];
        }
    }
    
    [self updateStrategy];    
}

- (void) updateStrategy {
    UIDevice* currentDevice = [UIDevice currentDevice];
    UIDeviceBatteryState batteryState = [currentDevice batteryState];

    float batteryLevel = [currentDevice batteryLevel] * 100;
    BOOL plugged = batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
    
    // available energy and time till charging
    NSTimeInterval ttc = lastTimeCharging != nil ?  (chargeCycle - -[lastTimeCharging timeIntervalSinceNow]) : chargeCycle;
    ttc = MAX(ttc, 1 * 3600);
    float dE = batteryLevel - reservedEnergy - (ttc * P_user);

    if (plugged && batteryLevel >= 70) {
        // free to use all power ;-)
        T_location = 1;
        T_noise = 5;
        T_motion = 1;
    } else if (plugged) {
        //intermediate mode, use some power, but not all
        T_location = 300;
        T_noise = 15;
        T_motion = 15;
    } else if (dE <= 0) {
        // ai, go to full eco mode. Minimum or no sampling
        T_location = 60 * 60;
        T_noise = 15 * 60;
        T_motion = 15 * 60;
    } else {
        //Don't use consumption factor, as it leads to stupid behaviour. The whole consumption factor idea doesn't make much sense!
        dE = dE * aggressiveness;
        // no information, so fixed sample interval
        // some simple code, as this needs to be implemented later with adaptive sampling
        T_location = P_location * ttc / (dE * 0.7);
        T_noise = P_noise * ttc / (dE * 0.1);
        T_motion = P_motion * ttc / (dE * 0.2);
        
        //saturate
        T_location = MAX(1, MIN(60 * 60, T_location));
        T_noise = MAX(5, MIN(15 * 60, T_noise));
        T_motion = MAX(5, MIN(15 * 60, T_motion));
    }
    
    //update settings
    Settings* settings = [Settings sharedSettings];
    [settings commitSettingType:@"spatial" setting:@"pollInterval" value:[NSString stringWithFormat:@"%g", T_motion] persistent:NO];
    [settings commitSettingType:@"position" setting:@"interval" value:[NSString stringWithFormat:@"%g", T_location] persistent:NO];
    [settings commitSettingType:@"noise" setting:@"interval" value:[NSString stringWithFormat:@"%g", T_noise] persistent:NO];
}


- (void) batteryStateChanged:(NSNotification*) notification {
    UIDevice* currentDevice = [UIDevice currentDevice];
    UIDeviceBatteryState batteryState = [currentDevice batteryState];
    
    float batteryLevel = [currentDevice batteryLevel] * 100;
    BOOL plugged = batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
    BOOL lastPlugged = lastBatteryState == UIDeviceBatteryStateCharging || lastBatteryState == UIDeviceBatteryStateFull;

    
    //record when charging starts
    if (plugged && lastPlugged == NO) {
        startChargingTime = [NSDate date];
    }
    //when charging stops
    if (plugged == NO && lastPlugged) {
        //if at least 3/4 charged and charging lasted an hour, this counts as charging the phone
        if (batteryLevel >= 75 && -[startChargingTime timeIntervalSinceNow] > 3600) {
            //record time between recharges to automatically tune the charging interval
            if (lastTimeCharging != nil) {
                NSTimeInterval dt = [startChargingTime timeIntervalSinceDate:lastTimeCharging];

                //use p-th quartile, use an online algorithm to estimate it 
                double alpha = 2 * 3600;
                double p = 0.9;
                estimatedChargeCycle += dt > estimatedChargeCycle ? 2 * alpha * p : -2 * alpha * (1-p);
                [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"estimatedChargeCycle" value:[NSString stringWithFormat:@"%g", estimatedChargeCycle] persistent:YES];
                [[Settings sharedSettings] commitSettingType:@"adaptive" setting:@"observedChargeCycle" value:[NSString stringWithFormat:@"%g", dt] persistent:YES];
            }
            
           //record time of charging, this is used in updateStrategy() to determine how long until a recharge
           lastTimeCharging = [NSDate date];
        }

        startChargingTime = [NSDate date];
    }
    


    if (!plugged) {
        recordedBatteryLevel = batteryLevel;
        recordedDate = [NSDate date];
    }
    
    
    lastBatteryState = batteryState;
    if (isEnabled) {
        [self updateStrategy];
    }
}

- (void) setIsEnabled:(BOOL) enable {
    if (enable) {
        [checkTimer invalidate];
        checkTimer = [NSTimer scheduledTimerWithTimeInterval:30 * 60 target:self selector:@selector(check) userInfo:nil repeats:YES];
        
        recordedBatteryLevel = [[UIDevice currentDevice] batteryLevel];
        lastBatteryState = [[UIDevice currentDevice] batteryState];
        recordedDate = [NSDate date];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(batteryStateChanged:)
													 name:UIDeviceBatteryStateDidChangeNotification object:nil];
        //register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[Settings settingChangedNotificationNameForType:@"adaptive"] object:nil];
                
        [self updateStrategy];
    } else {
        //TODO: set settings to user specified settings
        [checkTimer invalidate];
    }
    isEnabled = enable;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) settingChanged: (NSNotification*) notification {
		Setting* setting = notification.object;
		NSLog(@"sampleStrategy: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:@"energyAdaptive"]) {
            [self setIsEnabled:[setting.value boolValue]];
		} else if ([setting.name isEqualToString:@"chargeCycle"]) {
            chargeCycle = [setting.value intValue];
		}
}
@end