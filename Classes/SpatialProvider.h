//
//  SpatialProvider.h
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "CompassSensor.h"
#import "OrientationSensor.h"
#import "AccelerometerSensor.h"
#import "AccelerationSensor.h"
#import "RotationSensor.h"
#import <pthread.h>

@interface SpatialProvider : NSObject <CLLocationManagerDelegate>{
	CLLocationManager* locationManager;
	CMMotionManager* motionManager;
	
	CompassSensor* compassSensor;
	AccelerometerSensor* accelerometerSensor;
	OrientationSensor* orientationSensor;
	AccelerationSensor* accelerationSensor;
	RotationSensor* rotationSensor;
	
	NSOperationQueue* operations;
	
	BOOL deallocating;
	
	//shadow sensor.isEnabled variables since order of notificaion reception is undefined
	BOOL compassEnabled;
	BOOL orientationEnabled;
	BOOL accelerometerEnabled;
	BOOL rotationEnabled;
}

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation;
- (void) setAccelerometerEnabled:(BOOL) enable;
- (void) accelerometerEnabledChanged: (id) notification;
- (void) setRotationEnabled:(BOOL) enable;
- (void) rotationEnabledChanged: (id) notification;
- (void) orientationEnabledChanged: (id) notification;
- (void) setOrientationEnabled:(BOOL) enable;
- (void) compassEnabledChanged: (id) notification;
- (void) setCompassEnabled:(BOOL) enable;
- (void) settingChanged: (NSNotification*) notification;

@end
