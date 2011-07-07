//
//  BatterySensor.m
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "Meter.h"
#import "JSON.h"
#import "SensorStore.h"


@implementation MeterSensor
//constants
static NSString* variableKey = @"variable";
static NSString* valueKey = @"value";

+ (NSString*) name {return @"meter";}
+ (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", variableKey,
							@"string", valueKey,
							nil];
	//make string, as per spec
	NSString* json = [format JSONRepresentation];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"json", @"data_type",
			json, @"data_structure",
			nil];
}

- (id) init {
	[super init];
	if (self) {
		//register for battery notifications, notifications will be received at the current thread
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitBatteryState:)
													 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitBatteryState:)
													 name:UIDeviceBatteryStateDidChangeNotification object:nil];
		//seed randomizer
		srandom(time(NULL));
		
		//register for all posibble settings
	}
	return self;
}

- (void) commitBatteryState:(NSNotification*) notification {
	
	int choice = random() % 100;
	//20% chance to change the syncRate
	if (choice >= 20) return;
	
	//choose new syncRate
	int syncRate = 1 + random() % (60*5);
	[[SensorStore sharedSensorStore] setSyncRate:syncRate];
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"syncRate", variableKey,
								   [NSString stringWithFormat:@"%d",syncRate], valueKey,
									nil];
	
	NSNumber* timestamp = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling battery sensor (id=%d): %@", sensorId, enable ? @"yes":@"no");
	//rely upon the battery sensor to enable
	//[UIDevice currentDevice].batteryMonitoringEnabled = enable;
	//choose new syncRate
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

@end
