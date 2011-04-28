//
//  SpatialProvider.m
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "SpatialProvider.h"
#import "JSON.h"

static const NSInteger G = 9.81;


@implementation SpatialProvider

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation{
	[super init];
	if (self) {
		deallocating = NO;
		NSLog(@"spatial provider init");
		compassSensor = [compass retain]; orientationSensor = [orientation retain]; accelerometerSensor = [accelerometer retain]; accelerationSensor = [acceleration retain]; rotationSensor = [rotation retain];
		
		motionManager = [[CMMotionManager alloc] init];
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;

		//TODO: properly apply settings
		[motionManager setDeviceMotionUpdateInterval:1];
		[motionManager setAccelerometerUpdateInterval:1];
		locationManager.headingFilter = 5;
		
		//operations queue
		operations = [[NSOperationQueue alloc] init];
		
		//enable
		[self setAccelerometerEnabled: accelerometer.isEnabled];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accelerometerEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[accelerometerSensor class]] object:nil];
		[self setOrientationEnabled: orientation.isEnabled];
		orientationEnabled = orientation.isEnabled;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(orientationEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[orientationSensor class]] object:nil];

		[self setCompassEnabled: compass.isEnabled];
		compassEnabled = compass.isEnabled;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(compassEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:[compassSensor class]] object:nil];
	}

	return self;
}

- (void) accelerometerEnabledChanged: (id) notification {
		[self setAccelerometerEnabled:[[notification object] boolValue]];
}

- (void) setAccelerometerEnabled:(BOOL) enable {
	if (enable) {
		CMAccelerometerHandler accelerometerHandler = ^ (CMAccelerometerData *accelerometerData, NSError *error) {
			CMAcceleration acceleration = accelerometerData.acceleration;
			NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											//acceleration
											[NSNumber numberWithFloat:acceleration.x * G], accelerationXKey,
											[NSNumber numberWithFloat:acceleration.y * G], accelerationYKey,
											[NSNumber numberWithFloat:acceleration.z * G], accelerationZKey,
											nil];
			
			NSNumber* timestamp = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
			
			NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
												[newItem JSONRepresentation], @"value",
												timestamp, @"date",
												nil];
			NSLog(@"prosessed: %@",valueTimestampPair);
			[accelerometerSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerometerSensor.sensorId];
		};
		[motionManager startAccelerometerUpdatesToQueue:operations withHandler:accelerometerHandler];
	}
	else {
		[motionManager stopAccelerometerUpdates];
	}
}

- (void) orientationEnabledChanged: (id) notification {
	BOOL enable = [[notification object] boolValue];
	orientationEnabled = enable;
	[self setOrientationEnabled:enable];
	
}

- (void) setOrientationEnabled:(BOOL) enable {
	//TODO: add rotation sensor
	if (enable) {
		CMDeviceMotionHandler deviceMotionHandler = ^ (CMDeviceMotion *deviceMotion, NSError *error) {
			NSNumber* timestamp = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
			//report attitude
			CMAttitude* attitude = deviceMotion.attitude;
			//CMRotationRate rotation = deviceMotion.rotationRate;
			
			NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											//acceleration
											[NSNumber numberWithFloat:attitude.pitch], attitudePitchKey,
											[NSNumber numberWithFloat:attitude.roll], attitudeRollKey,
											[NSNumber numberWithFloat:locationManager.heading.trueHeading], attitudeYawKey,
											nil];
			
			NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
												[newItem JSONRepresentation], @"value",
												timestamp,@"date",
												nil];
			NSLog(@"prosessed: %@",valueTimestampPair);
			[orientationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:orientationSensor.sensorId];
			
			//report device acceleration without gravity
			if (accelerationSensor != nil && [AccelerometerSensor isAvailable]) { 
				CMAcceleration acceleration = deviceMotion.userAcceleration;
				newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											//acceleration
											[NSNumber numberWithFloat:acceleration.x], accelerationXKey,
   											[NSNumber numberWithFloat:acceleration.y], accelerationYKey,
											[NSNumber numberWithFloat:acceleration.z], accelerationZKey,
											nil];
				valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
									  [newItem JSONRepresentation], @"value",
									  timestamp,@"date",
									  nil];
				[accelerationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerationSensor.sensorId];
			}
			
			//report device rotation rate
			if (rotationSensor != nil && [RotationSensor isAvailable]) {
				CMRotationRate rotation = deviceMotion.rotationRate;
				newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						   //acceleration
						   [NSNumber numberWithFloat:rotation.x], accelerationXKey,
						   [NSNumber numberWithFloat:rotation.y], accelerationYKey,
						   [NSNumber numberWithFloat:rotation.z], accelerationZKey,
						   nil];
				valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
									  [newItem JSONRepresentation], @"value",
									  timestamp,@"date",
									  nil];

			}
			[rotationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:rotationSensor.sensorId];
			
		};
		[motionManager startDeviceMotionUpdatesToQueue:operations withHandler:deviceMotionHandler];
	}
	else {
		[motionManager stopDeviceMotionUpdates];
	}
	//en/dis-able compass as well
	[self setCompassEnabled:enable];
}

- (void) compassEnabledChanged: (id) notification {
	BOOL enable = [[notification object] boolValue];
	compassEnabled = enable;
	[self setCompassEnabled:enable];
	
}

- (void) setCompassEnabled:(BOOL) enable {
	if (enable) {
		[locationManager startUpdatingHeading];
		NSLog(@"Enabling compass.");
	} else if (orientationEnabled == NO && compassEnabled == NO){
		[locationManager stopUpdatingHeading];
		NSLog(@"Disabling compass.");
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return NO;
}


//implement delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	//compass might be enabled for orientation sensor
	if (compassSensor.isEnabled == NO) return;
	
	NSNumber* heading = [NSNumber numberWithFloat:newHeading.magneticHeading];
	NSNumber* accuracy = [NSNumber numberWithFloat:newHeading.headingAccuracy];
	//values are normalised to the range [+128,-128], normalise to [+1,-1]
	NSNumber* devX = [NSNumber numberWithFloat:newHeading.x / 128.0];
	NSNumber* devY = [NSNumber numberWithFloat:newHeading.y / 128.0];
	NSNumber* devZ = [NSNumber numberWithFloat:newHeading.z / 128.0];
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									devX, devXKey,
									devY, devYKey,
									devZ, devZKey,
									nil];
	
	//include heading if no error indicated
	if (newHeading.headingAccuracy >=0) {
		[newItem setObject:heading forKey:magneticHeadingKey];
		[newItem setObject:accuracy forKey:accuracyKey];
	}
  	
	
	NSNumber* timestamp = [NSNumber numberWithInt:[newHeading.timestamp timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp, @"date",
										nil];
	[compassSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:[compassSensor sensorId]];
}

- (void) dealloc {
	//dealloc causes a ^block to be dealloced, which releases the spatial provider invoking dealloc again... prevent recursion
	if (deallocating) return;
	deallocating = YES;
	
	NSLog(@"Spatial provider dealloc. retain count %d", [self retainCount]);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setAccelerometerEnabled:NO];
	[self setCompassEnabled:NO];
	[self setOrientationEnabled:NO];
	[motionManager release];
	[locationManager release];
	
	[operations cancelAllOperations];
	[operations release];
	
	[compassSensor release];
	[accelerometerSensor release];
	[orientationSensor release];
	
	[super dealloc];
}

@end
