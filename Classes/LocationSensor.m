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
		[self applyLocationSettings];
		self.isEnabled = [[Settings sharedSettings] isSensorEnabled:[self class]];
		//register for change in settings
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyLocationSettings) name:locationSettingsChangedNotification object:nil];
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
		[locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
	}
	else {
		[locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
	}
	isEnabled = enable;
}
- (void) applyLocationSettings {
	@try {
		NSLog(@"applying location settings");
		//get dictionary
		NSDictionary* properties = [Settings sharedSettings].location;
		
		//determine location accuracy
		locationManager.desiredAccuracy = [[properties valueForKey:locationSettingAccuracyKey] doubleValue];;
		locationManager.distanceFilter = [[properties valueForKey:locationSettingMinimumDistanceKey] doubleValue];
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