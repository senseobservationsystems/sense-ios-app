//
//  SpatialProvider.m
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "SpatialProvider.h"
#import "JSON.h"

static const double G = 9.81;


@implementation SpatialProvider

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation{
	self = [super init];
	if (self) {
		NSLog(@"spatial provider init");
		compassSensor = compass; orientationSensor = orientation; accelerometerSensor = accelerometer; accelerationSensor = acceleration; rotationSensor = rotation;		
		motionManager = [[CMMotionManager alloc] init];
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
        
		//Set settings
		@try {
			interval = [[[Settings sharedSettings] getSettingType:@"spatial" setting:@"pollInterval"] doubleValue];
   			//frequency = [[[Settings sharedSettings] getSettingType:@"spatial" setting:@"frequency"] doubleValue];
            //sampleTime = [[[Settings sharedSettings] getSettingType:@"spatial" setting:@"sampleTime"] doubleValue];
            //TODO: properly use the options
            frequency = 50;
            sampleTime = 1;
			motionManager.gyroUpdateInterval = interval;
			motionManager.accelerometerUpdateInterval = interval;
			motionManager.deviceMotionUpdateInterval = interval;
            NSLog(@"freq=%f, dt=%f", frequency, sampleTime);
		}
		@catch (NSException * e) {
			NSLog(@"spatial provider: Exception thrown while setting: %@", e);
		}
		//TODO: properly manage this setting
		locationManager.headingFilter = 10;
		
		//operations queue
		operations = [[NSOperationQueue alloc] init];
   		pollQueue = [[NSOperationQueue alloc] init];
        
        headingAvailable = [[NSCondition alloc] init];
        updatingHeading = NO;
		
		//enable
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accelerometerEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[accelerometerSensor class]] object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rotationEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[rotationSensor class]] object:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(orientationEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[orientationSensor class]] object:nil];
		
		//register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[Settings settingChangedNotificationNameForType:@"spatial"] object:nil];
	}
    
	return self;
}

- (void) accelerometerEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue];
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerationSensor != nil && accelerationSensor.isEnabled) || (rotationSensor != nil && rotationSensor.isEnabled) || (orientationSensor != nil && orientationSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) rotationEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue] && (rotationSensor != nil);
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerometerSensor != nil && accelerometerSensor.isEnabled) || (orientationSensor != nil && orientationSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) orientationEnabledChanged:(id)notification {
	bool enable = [[notification object] boolValue] && (orientationSensor != nil);
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerationSensor != nil && accelerationSensor.isEnabled) || (rotationSensor != nil && rotationSensor.isEnabled) || (accelerometerSensor != nil && accelerometerSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) schedulePoll {
    @try {
        //make an upload operation
        NSInvocationOperation* pollOp = [[NSInvocationOperation alloc]
                                         initWithTarget:self selector:@selector(poll) object:nil];
        
        [pollQueue addOperation:pollOp];
    }
    @catch (NSException * e) {
        NSLog(@"Catched exception while scheduling poll. Exception: %@", e);
    }
}

- (void) poll {

    NSLog(@"Polling motion sensors");
    BOOL hasOrientation = orientationSensor != nil && orientationSensor.isEnabled;
    BOOL hasAccelerometer = accelerometerSensor != nil && accelerometerSensor.isEnabled;
    BOOL hasAcceleration = accelerationSensor != nil && accelerationSensor.isEnabled;
    BOOL hasRotation = rotationSensor != nil && rotationSensor.isEnabled;
    
    
    //prepare arrays for data
    const int nrSamples = frequency * sampleTime;
    CMAcceleration* accelerometerData = (CMAcceleration*) malloc(sizeof(CMAcceleration) * nrSamples);
    CMAcceleration* accelerationData = (CMAcceleration*) malloc(sizeof(CMAcceleration) * nrSamples);
    CMRotationRate* rotationRateData = (CMRotationRate*) malloc(sizeof(CMRotationRate) * nrSamples);
    __block CMAttitude* attitude;
    __block double timestamp;
    __block int sample = 0;
    
    NSCondition* dataCollectedCondition = [NSCondition new];
    
    CMDeviceMotionHandler deviceMotionHandler = ^(CMDeviceMotion *deviceMotion, NSError *error) {
        timestamp = [[NSDate date] timeIntervalSince1970];
        if (sample >= nrSamples) {
            return;
        }
        
        //report attitude only once
        if (attitude == nil && hasOrientation) {
            attitude = [deviceMotion.attitude copy];
        }
        
        //report accelerometer
        if (hasAccelerometer) { 
            CMAcceleration acceleration = deviceMotion.userAcceleration;
            CMAcceleration gravity = deviceMotion.gravity;
            accelerometerData[sample].x = (acceleration.x + gravity.x);
            accelerometerData[sample].y = (acceleration.y + gravity.y);
            accelerometerData[sample].z = (acceleration.z + gravity.z);
        }
        //report acceleration
        if (hasAcceleration) { 
            accelerationData[sample] = deviceMotion.userAcceleration;
        }
        
        //report rotation
        if (hasRotation) {
            rotationRateData[sample] = deviceMotion.rotationRate;
        }
        
        //and move on to the next sample, or stop the sampling
        if (++sample >= nrSamples) {
            [dataCollectedCondition broadcast];
            [motionManager stopDeviceMotionUpdates];
        }
    };
    motionManager.deviceMotionUpdateInterval = 1./frequency;
    [dataCollectedCondition lock];
    [motionManager startDeviceMotionUpdatesToQueue:operations withHandler:deviceMotionHandler];
    // Aquire heading, this may take some time ( 1 second)
    float heading = -1;
    /*
     if (hasOrientation) {
     if (!updatingHeading) {
     //wait for heading to be available 
     [headingAvailable lock];
     [locationManager startUpdatingHeading];
     updatingHeading = YES;
     [headingAvailable wait];
     [headingAvailable unlock];
     }
     heading = locationManager.heading.magneticHeading;
     }
     */
    //wait until all data collected
    [dataCollectedCondition wait];
    [dataCollectedCondition unlock];
    
    const double radianInDegrees = 180 / M_PI;
    
    //TODO: convert to the desired format. i.e. pitch <-180, 180] and roll <-90,90], now the default iOS format has pitch <-90,90] and roll <-180,180]
    //Commit samples for the sensors
    if (hasOrientation) {
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSString stringWithFormat:@"%.3f", attitude.pitch * radianInDegrees], attitudePitchKey,
                                        [NSString stringWithFormat:@"%.3f", attitude.roll * radianInDegrees], attitudeRollKey,
                                        [NSString stringWithFormat:@"%.0f", heading], attitudeYawKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [newItem JSONRepresentation], @"value",
                                            [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                            nil];
        [orientationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:orientationSensor.sensorId];
        
    }
    
    if (hasAccelerometer) {
        //generate csv from array data
        NSMutableString* csv = [NSMutableString new];
        for(int i=0; i < nrSamples; i++) {
            [csv appendFormat:@"%.3f,%.3f,%.3f\n",accelerometerData[i].x * G, accelerometerData[i].y * G, accelerometerData[i].z * G];
        }
        NSMutableDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%.3f",frequency], @"frequency",
                                      @"x,y,z", @"header",
                                      csv, @"data",
                                      nil];
        NSMutableDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [value JSONRepresentation], @"value",
                                                   [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                   nil];
        [accelerometerSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerometerSensor.sensorId];
    }
    
    if (hasAcceleration) {
        //generate csv from array data
        NSMutableString* csv = [NSMutableString new];
        for(int i=0; i < nrSamples; i++) {
            [csv appendFormat:@"%.3f,%.3f,%.3f\n",accelerationData[i].x * G, accelerationData[i].y * G, accelerationData[i].z * G];
        }
        NSMutableDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%.3f",frequency], @"frequency",
                                      @"x,y,z", @"header",
                                      csv, @"data",
                                      nil];
        NSMutableDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [value JSONRepresentation], @"value",
                                                   [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                   nil];
        [accelerationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerationSensor.sensorId];
    }
    
    if (hasRotation) {
        //generate csv from array data
        NSMutableString* csv = [NSMutableString new];
        for(int i=0; i < nrSamples; i++) {
            [csv appendFormat:@"%.3f,%.3f,%.3f\n",rotationRateData[i].x * radianInDegrees, rotationRateData[i].y * radianInDegrees, rotationRateData[i].z * radianInDegrees];
        }
        NSMutableDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithFormat:@"%.3f",frequency], @"frequency",
                                      @"x,y,z", @"header",
                                      csv, @"data",
                                      nil];
        NSMutableDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [value JSONRepresentation], @"value",
                                                   [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                   nil];
        [rotationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:rotationSensor.sensorId];
    }
    
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return NO;
}


//implement delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    //wake up threads waiting for a heading
    [headingAvailable broadcast];
	//if compass isn't enabled, it was just a one time need for a heading, so stop updating
	if (compassSensor.isEnabled == NO && interval > 1) {
        [locationManager stopUpdatingHeading];
        updatingHeading = false;
        return;
    }
}

- (void) settingChanged: (NSNotification*) notification {
	@try {
		Setting* setting = notification.object;
		NSLog(@"Spatial: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:@"pollInterval"]) {
            interval = [setting.value doubleValue];
            [pollTimer invalidate];
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
		} else if ([setting.name isEqualToString:@"frequency"]) {
			frequency = [setting.value doubleValue];
		} else if ([setting.name isEqualToString:@"sampleTime"]) {
			sampleTime = [setting.value doubleValue];
		}
	}
	@catch (NSException * e) {
		NSLog(@"spatial provider: Exception thrown while changing setting: %@", e);
	}
	
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [pollTimer invalidate];
	
	[operations cancelAllOperations];
}

@end
