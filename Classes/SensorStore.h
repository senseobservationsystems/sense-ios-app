//
//  sensorStore.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationSensor.h"
#import "BatterySensor.h"
#import "Sender.h"
#import "DataStore.h"
#import "SpatialProvider.h"


@interface SensorStore : NSObject <DataStore> {
	Sender* sender;
	
	NSMutableDictionary* sensorData;
	BOOL serviceEnabled;
	NSTimeInterval syncRate;
	NSDate* lastUpload;
	NSTimeInterval pollRate;
	NSDate* lastPoll;
	NSOperationQueue* operationQueue;
	
	NSTimer* uploadTimer;
	NSTimer* pollTimer;
	
	//Sensor classes, this variable is used to instantiate sensors
	NSArray* allSensorClasses;
	NSArray* allAvailableSensorClasses;
	NSMutableArray* sensors;
	
	SpatialProvider* spatialProvider;
}

@property (readonly) Sender* sender;
@property (readonly, assign) NSArray* allAvailableSensorClasses;

+ (SensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) uploadData;
- (void) instantiateSensors;
- (void) applyGeneralSettings;
- (void) loginChanged;
- (void) enabledChanged:(id) notification;
//run hook is used to give SensorStore execution time to upload data
- (void) scheduleUpload;
- (void) pollSensors;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk (not impemented)
 * - delete
 */
- (void) forceDataFlush;


@end
