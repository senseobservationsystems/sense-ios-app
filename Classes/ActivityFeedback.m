//
//  ActivityFeedback.m
//  sensePlatform
//
//  Created by Pim Nijdam on 1/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "ActivityFeedback.h"
#import "JSON.h"
#import "SensorStore.h"

@implementation ActivityFeedback
//constants
static NSString* typeKey = @"type";
static NSString* startKey = @"start";
static NSString* stopKey = @"stop";

+ (NSString*) name {return @"activityFeedback";}
+ (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", typeKey,
							@"float", startKey,
  							@"float", stopKey,
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
	self = [super init];
	if (self) {
	}
	return self;
}

+ (void) commitActivity: (Activity*) activity {
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    activity.type, typeKey,
                                    [NSString stringWithFormat:@"%f",[activity.start timeIntervalSince1970]], startKey,
                                    [NSString stringWithFormat:@"%f",[activity.stop timeIntervalSince1970]], stopKey,
									nil];
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp,@"date",
										nil];
	[[SensorStore sharedSensorStore] commitFormattedData:valueTimestampPair forSensorId:[ActivityFeedback sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ activityFeedback sensor (id=%@)", self.sensorId, enable ? @"Enabling":@"Disabling");
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end