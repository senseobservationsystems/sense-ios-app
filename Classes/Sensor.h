//
//  Sensor.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "DataStore.h"

@interface Sensor : NSObject {
	NSInteger sensorId;
	
	BOOL isEnabled;
	//delegate
	id dataStore;
}

@property (assign) BOOL isEnabled;
@property (assign) NSInteger sensorId;
@property (strong) id dataStore;


//TODO: use selector for comparison
+ (BOOL) matchesDescription:(NSDictionary*) description;

//common methods
- (void) enabledChanged: (id) notification;

//implemented by device if it needs a 'run' method
- (void) dealloc;

//overridden by subclass
+ (NSString*) name;
+ (NSString*) displayName;
+ (NSString*) deviceType;
+ (NSDictionary*) sensorDescription;
+ (BOOL) isAvailable;
@end
