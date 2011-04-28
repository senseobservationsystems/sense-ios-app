//
//  UserProximity.m
//  senseApp
//
//  Created by Pim Nijdam on 2/28/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "UserProximity.h"


@implementation UserProximity

+ (NSString*) name {return @"user proximity";}
+ (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"bool", @"data_type",
			nil];
}

- (id) init {
	[super init];
	if (self) {
		//register for proximity notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitUserProximity:)
													 name:UIDeviceProximityStateDidChangeNotification object:nil];
		self.isEnabled = [[Settings sharedSettings] isSensorEnabled:[self class]];
	}
	return self;
}

- (void) commitUserProximity:(NSNotification*) notification {
	//get proximity infomation
	NSString* proximityState = [[UIDevice currentDevice] proximityState] ? @"true": @"false";
	
	NSNumber* timestamp = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										proximityState, @"value",
										timestamp,@"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling user proximity sensor (id=%d): %@", sensorId, enable ? @"yes":@"no");
	[UIDevice currentDevice].proximityMonitoringEnabled = enable;
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

@end
