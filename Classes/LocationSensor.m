//
//  LocationSensor.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LocationSensor.h"
#import "JSON.h"
#import "Settings.h"


@implementation LocationSensor
//constants
static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* altitudeKey = @"altitude";
static NSString* horizontalAccuracyKey = @"accuracy";
static NSString* verticalAccuracyKey = @"vertical accuracy";
static NSString* speedKey = @"speed";
static int maxSamples = 6;

+ (NSString*) name {return @"position";}
+ (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return [CLLocationManager locationServicesEnabled];}

+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
								@"float", longitudeKey,
								@"float", latitudeKey,
								@"float", altitudeKey,
								@"float", horizontalAccuracyKey,
								@"float", verticalAccuracyKey,
								@"float", speedKey,
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
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[Settings settingChangedNotificationNameForSensor:[self class]] object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[Settings settingChangedNotificationNameForType:@"position"] object:nil];
		
		samples = [[NSMutableArray alloc] initWithCapacity:maxSamples];
	}
	return self;
}


// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	NSNumber* longitude = [NSNumber numberWithFloat:newLocation.coordinate.longitude];
	NSNumber* latitude = [NSNumber numberWithFloat:newLocation.coordinate.latitude];
	NSNumber* altitude = [NSNumber numberWithFloat:newLocation.altitude];
	NSNumber* horizontalAccuracy = [NSNumber numberWithFloat:newLocation.horizontalAccuracy];
	NSNumber* verticalAccuracy = [NSNumber numberWithFloat:newLocation.verticalAccuracy];
	NSNumber* speed = [NSNumber numberWithFloat:newLocation.speed];
	
	/* filter on location accuracy */
	//remove least recent sample
	if ([samples count] >= maxSamples)
		[samples removeLastObject];
	//insert this sample at beginning
	[samples insertObject:horizontalAccuracy atIndex:0];
	
	//sort so we can calculate quartiles
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
	NSArray *sorters = [[NSArray alloc] initWithObjects:sorter, nil];
	[sorter release];
	NSArray *sortedSamples = [samples sortedArrayUsingDescriptors:sorters];
	[sorters release];
	
	//50m, or within desiredAccuracy is a good start
	int goodStartAccuracy = locationManager.desiredAccuracy;
	if (goodStartAccuracy < 50) goodStartAccuracy = 50;
	//decide wether to accept the sample
	if ([samples count] >= maxSamples) {
		//we expect within 2* second quartile, this rejects outliers
		int adaptedGoodEnoughAccuracy = [[sortedSamples objectAtIndex:(int)(maxSamples/2)] intValue] * 2;
		NSLog(@"adapted: %d", adaptedGoodEnoughAccuracy);
		if ([horizontalAccuracy intValue] <= adaptedGoodEnoughAccuracy)
			;
		else
			return;
	}
	else if ([samples count] < maxSamples && [horizontalAccuracy intValue] <= goodStartAccuracy)
		; //accept if we haven't collected many samples, but accuracy is alread quite good
	else 
		return; //reject sample
	
	/* commit sensor value */
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									longitude, longitudeKey,
									latitude, latitudeKey,
									horizontalAccuracy, horizontalAccuracyKey,
									nil];
	if (newLocation.speed >=0) {
		[newItem setObject:speed forKey:speedKey];
	}
	if (newLocation.verticalAccuracy >= 0) {
		[newItem setObject:altitude forKey:altitudeKey];
		[newItem setObject:verticalAccuracy forKey:verticalAccuracyKey];
	}
	
  	
	
	NSNumber* timestamp = [NSNumber numberWithInt:[newLocation.timestamp timeIntervalSince1970]];
	
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
	
	NSLog(@"Enabling location sensor (id=%d): %@", sensorId, enable ? @"yes":@"no");
	if (enable) {
		@try {
			locationManager.desiredAccuracy = [[[Settings sharedSettings] getSettingType:@"position" setting:@"accuracy"] intValue];
		} @catch (NSException* e) {
			NSLog(@"Exception setting position accuracy: %@", e);
		}
		[samples removeAllObjects];
		[locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
	}
	else {
		[locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
		[samples removeAllObjects];
	}
	isEnabled = enable;
}

- (void) settingChanged: (NSNotification*) notification  {
	@try {
		Setting* setting = notification.object;
		NSLog(@"Location setting %@ changed to %@.", setting.name, setting.value);

		if ([setting.name isEqualToString:@"accuracy"]) {
			locationManager.desiredAccuracy = [setting.value integerValue];
		}
	}
	@catch (NSException * e) {
		NSLog(@"LocationSensor: Exception thrown while applying location settings: %@", e);
	}
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[locationManager release];
	
	[super dealloc];
}
@end