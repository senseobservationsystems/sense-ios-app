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
#import "SampleStrategy.h"


@interface SensorStore : NSObject <DataStore> {
	Sender* sender;
	
	NSMutableDictionary* sensorData;
	BOOL serviceEnabled;
	NSTimeInterval syncRate;
    NSTimeInterval waitTime;
	NSDate* lastUpload;
	NSTimeInterval pollRate;
	NSDate* lastPoll;
	NSOperationQueue* operationQueue;
	
	NSTimer* uploadTimer;
    SampleStrategy* sampleStrategy;
	
	//Sensor classes, this variable is used to instantiate sensors
	NSArray* allSensorClasses;
	NSArray* allAvailableSensorClasses;
	NSMutableArray* sensors;
    NSMutableDictionary* sensorIdMap;
	
	SpatialProvider* spatialProvider;
}

@property (readonly) Sender* sender;
@property (readonly, retain) NSArray* allAvailableSensorClasses;

+ (SensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;
- (void) setSyncRate: (int) newRate;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk (not impemented)
 * - delete
 */
- (void) forceDataFlush;
- (void) generalSettingChanged: (NSNotification*) notification;


@end
