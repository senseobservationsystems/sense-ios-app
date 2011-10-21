//
//  sensorStore.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SensorStore.h"
#import "Settings.h"

#import "LocationSensor.h"
#import "BatterySensor.h"
#import "CompassSensor.h"
#import "AccelerometerSensor.h"
#import "OrientationSensor.h"
#import "UserProximity.h"
#import "OrientationStateSensor.h"
#import "NoiseSensor.h"
#import "CallSensor.h"
#import "ConnectionSensor.h"
#import "PreferencesSensor.h"
#import "MiscSensor.h"

#define IGNORE_DATA 0
#if IGNORE_DATA != 0
#warning Compiling with IGNORE_DATA, so no data will be committed to commonSense
#endif


@implementation SensorStore
@synthesize sender;
@synthesize allAvailableSensorClasses;

//Singleton instance
static SensorStore* sharedSensorStoreInstance = nil;

+ (SensorStore*) sharedSensorStore {
	if (sharedSensorStoreInstance == nil) {
		sharedSensorStoreInstance = [[super allocWithZone:NULL] init];
	}
	return sharedSensorStoreInstance;	
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedSensorStore];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id) init {
	self = [super init];
	if (self) {
		sender = [[Sender alloc] init];
		//setup attributes
		sensorData = [[NSMutableDictionary alloc] init];
		operationQueue = [[NSOperationQueue alloc] init];
		lastUpload = [NSDate date];
		lastPoll = [NSDate date];
		
		//all sensor classes
		allSensorClasses = [NSArray arrayWithObjects:
							[LocationSensor class],
							[BatterySensor class],
							[CallSensor class],
 							[ConnectionSensor class],
   							[NoiseSensor class],
							[OrientationSensor class],
							[CompassSensor class],
							//[UserProximity class],
							//[OrientationStateSensor class],
 							[AccelerometerSensor class],
							[AccelerationSensor class],
							[RotationSensor class],
							[PreferencesSensor class],
							[MiscSensor class],
							nil];
		
		NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"isAvailable == YES"];
		allAvailableSensorClasses = [allSensorClasses filteredArrayUsingPredicate:availablePredicate];
		sensors = [[NSMutableArray alloc] init];

        //instantiate sample strategy
        sampleStrategy = [[SampleStrategy alloc] init];
        
		//set settings and initialise sensors
		[self applyGeneralSettings];
        
		

		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enabledChanged:) name:settingSenseEnabledChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged) name:settingLoginChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[Settings settingChangedNotificationNameForType:@"general"] object:nil];
	}
	return self;
}

- (void) makeRemoteDeviceSensors {
	//get list of sensors from the server
	NSDictionary* response = [sender listSensorsForDevice:[SensorStore device]];
	NSArray* remoteSensors = [response valueForKey:@"sensors"];
	
	//forall local sensors
	for (Sensor* sensor in sensors) {
		//match against all remote sensors
		for (id remoteSensor in remoteSensors) {
			//determine whether the sensor matches
			if ([remoteSensor isKindOfClass:[NSDictionary class]] && [[sensor class] matchesDescription:remoteSensor]) {
				NSLog(@"Matched sensor of type %@", [sensor class]);
				id sensorId = [remoteSensor valueForKey:@"id"];
				sensor.sensorId = [sensorId integerValue];
				break;
			}
		}
	}
	
	//create sensors that aren't assigned an id yet
	for (Sensor* sensor in sensors) {
		if (sensor.sensorId == -1) {
			NSDictionary* description = [sender createSensorWithDescription:[[sensor class] sensorDescription]];
			id sensorId = [description valueForKey:@"id"];
			if (description != nil && sensorId != nil) {
				sensor.sensorId = [sensorId integerValue];
				//link sensor to this device
				[sender connectSensor:sensor.sensorId ToDevice:[SensorStore device]];
				NSLog(@"Created %@ sensor with id %@", [sensor class], sensorId);
			}
		}
	}
}

- (void) instantiateSensors {
	//release current sensors
	spatialProvider=nil;
	[sensors removeAllObjects];

	//instantiate sensors
	for (Class aClass in allAvailableSensorClasses) {
		if ([aClass isAvailable]) {
			id newSensor = [[aClass alloc] init];
			[sensors addObject:newSensor];
		}
	}
	
	//get or create online sensors, this will assign ids to the local sensors
	[self makeRemoteDeviceSensors];
	
	//set self as data storage
	for (Sensor* sensor in sensors) {
		sensor.dataStore = self;
	}
	
	//initialise spatial provider
	CompassSensor* compass=nil; OrientationSensor* orientation=nil; AccelerometerSensor* accelerometer=nil; AccelerationSensor* acceleration = nil; RotationSensor* rotation = nil;
	for (Sensor* sensor in sensors) {
		if ([sensor isKindOfClass:[CompassSensor class]])
			compass = (CompassSensor*)sensor;
		else if ([sensor isKindOfClass:[OrientationSensor class]])
			orientation = (OrientationSensor*)sensor;
		else if ([sensor isKindOfClass:[AccelerometerSensor class]])
			accelerometer = (AccelerometerSensor*)sensor;
		else if ([sensor isKindOfClass:[AccelerationSensor class]])
			acceleration = (AccelerationSensor*)sensor;
		else if ([sensor isKindOfClass:[RotationSensor class]])
			rotation = (RotationSensor*)sensor;
	}
	
	spatialProvider = [[SpatialProvider alloc] initWithCompass:compass orientation:orientation accelerometer:accelerometer acceleration:acceleration rotation:rotation];
	
	//enable sensors.
	for (Sensor* sensor in sensors) {
			[[Settings sharedSettings] sendNotificationForSensor:[sensor class]];
	}
}

- (void) commitFormattedData:(NSDictionary*) data forSensorId:(NSInteger)sensorId {
    if (IGNORE_DATA) return;
	//retrieve/create entry for this sensor
	NSString* key = [NSString stringWithFormat:@"%d", sensorId];
	@synchronized(self) {
		NSMutableArray* entry = [sensorData valueForKey:key];
		if (entry == nil) {
			entry = [[NSMutableArray alloc] init];
			[sensorData setValue:entry forKey:key];
		}

		//add data
		[entry addObject:data];
	}
}

- (void) enabledChanged:(id) notification {
	BOOL enable = [[notification object] boolValue];
	serviceEnabled = enable;

	if (NO == enable) { 
		//disable sensors
		for (Sensor* sensor in sensors) {
			sensor.isEnabled = NO;
		}
		//release sensors
		spatialProvider = nil;
		[sensors removeAllObjects];
		//flush data
		[self forceDataFlush];
	} else {
		[self instantiateSensors];
	}
}

- (void) loginChanged {
	//flush current data before making any changes
	[self forceDataFlush];
	
	//get new settings
	NSDictionary* settings = [Settings sharedSettings].general;
	
	//change login
	[sender setUser:[settings valueForKey:generalSettingUsernameKey] andPassword:[settings valueForKey:generalSettingPasswordKey]];
	
	if (serviceEnabled) {
		//instantiate sensors
		[self instantiateSensors];
	}
}

- (void) scheduleUpload {
	@try {
		//make an upload operation
		NSInvocationOperation* uploadOp = [[NSInvocationOperation alloc]
											initWithTarget:self selector:@selector(uploadData) object:nil];

		[operationQueue addOperation:uploadOp];
	}
	@catch (NSException * e) {
		NSLog(@"Catched exception while scheduling upload. Exception: %@", e);
	}
}

- (void) uploadAndClearData {
	[self uploadData];
	@synchronized(self){
		[sensorData removeAllObjects];
	}
		
}

- (void) uploadData {
	NSMutableDictionary* myData;
	//take over sensorData
	@synchronized(self){
		myData = sensorData;
		sensorData = [NSMutableDictionary new];
	}
	
	for (NSString* sensorId in myData) {
		@try {
			NSMutableArray* data= [myData valueForKey:sensorId];
			if (data == nil) continue;
			NSLog(@"Uploading data for sensor %@", sensorId);
			if (NO == [sender uploadData:data forSensorId: [sensorId integerValue]]) {
				NSLog(@"Upload failed");
				//reinsert data into sensorData
				@synchronized(self) {
					NSMutableArray* entry = [sensorData valueForKey:sensorId];
					if (entry == nil) {
						[sensorData setValue:data forKey:sensorId];
					}
					else {
						[entry addObjectsFromArray:data];
					}
				}
			}
		} @catch (NSException* e) {
			NSLog(@"SenseStore: Exception while uploading data: %@", e);
		}
	}
}

- (void) applyGeneralSettings {
	@try {
		NSLog(@"applying general settings");
		//get new settings
		NSDictionary* settings = [Settings sharedSettings].general;
	
		//apply properties one by one
		[sender setUser:[settings valueForKey:generalSettingUsernameKey] andPassword:[settings valueForKey:generalSettingPasswordKey]];
		syncRate = [[[Settings sharedSettings] getSettingType:@"general" setting:generalSettingSynchronisationRateKey] doubleValue];
				
		serviceEnabled = [[settings valueForKey: generalSettingSenseEnabledKey] boolValue];
		if (serviceEnabled) {
			//instantiate sensors in the background using operation
			//NSInvocationOperation* instantiateOp = [[NSInvocationOperation alloc]
			//								   initWithTarget:self selector:@selector(instantiateSensors) object:nil];
			
			//[operationQueue addOperation:instantiateOp];
			//[instantiateOp release];
			//it seems some sensors don't like to be launched from a non-main thread, locationManager seems to prefer the mainthread...
			[self instantiateSensors];
		}
		
		uploadTimer = [NSTimer scheduledTimerWithTimeInterval:syncRate target:self selector:@selector(scheduleUpload) userInfo:nil repeats:YES];
		//pollTimer = [NSTimer scheduledTimerWithTimeInterval:pollRate target:self selector:@selector(pollSensors) userInfo:nil repeats:YES];
	}
	@catch (NSException * e) {
		NSLog(@"SenseStore: Exception thrown while updating general settings: %@", e);
	}
	
}

- (void) forceDataFlush {
	@try {
		//make an upload operation
		NSInvocationOperation* uploadOp = [[NSInvocationOperation alloc]
										   initWithTarget:self selector:@selector(uploadAndClearData) object:nil];
		
		[operationQueue addOperation:uploadOp];
	}
	@catch (NSException * e) {
		NSLog(@"Catched exception while scheduling upload. Exception: %@", e);
	}
}

- (void) generalSettingChanged: (NSNotification*) notification {
	if ([notification.object isKindOfClass:[Setting class]]) {
		Setting* setting = notification.object;
		NSLog(@"general setting changed: %@,%@", setting.name, setting.value);
		if ([setting.name isEqualToString:generalSettingSynchronisationRateKey]) {
			[self setSyncRate:[setting.value intValue]];
		}
	}

}

- (void) setSyncRate: (int) newRate {
	[uploadTimer invalidate];
	//[uploadTimer release];
	syncRate = newRate;
	uploadTimer = [NSTimer scheduledTimerWithTimeInterval:syncRate target:self selector:@selector(scheduleUpload) userInfo:nil repeats:YES];
}

+ (NSDictionary*) device {
	NSString* type = [[UIDevice currentDevice] model];
	NSString* uuid = [[UIDevice currentDevice] uniqueIdentifier];
	NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							uuid, @"uuid",
							type, @"type",
							nil];
	return device;
}
@end

