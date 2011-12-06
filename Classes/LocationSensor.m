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
#import "math.h"

@implementation LocationSensor
//constants
static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* altitudeKey = @"altitude";
static NSString* horizontalAccuracyKey = @"accuracy";
static NSString* verticalAccuracyKey = @"vertical accuracy";
static NSString* speedKey = @"speed";
static const int maxSamples = 7;
static const int minDistance = 10; //meters
static const int minInterval = 30; //seconds

static CLLocation* lastAcceptedPoint;

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
	self = [super init];
	if (self) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[Settings settingChangedNotificationNameForSensor:[self class]] object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[Settings settingChangedNotificationNameForType:@"position"] object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[Settings settingChangedNotificationNameForType:@"adaptive"] object:nil];
		
		samples = [[NSMutableArray alloc] initWithCapacity:maxSamples];
        previousLocation = nil;
        newSampleTimer = nil;
        
		//operations queue
		operations = [[NSOperationQueue alloc] init];
	}
	return self;
}


// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	double longitude = newLocation.coordinate.longitude;
	double latitude = newLocation.coordinate.latitude;
	double altitude = newLocation.altitude;
	double horizontalAccuracy = newLocation.horizontalAccuracy;
	double verticalAccuracy = newLocation.verticalAccuracy;
	double speed = newLocation.speed;
    
	
	/* filter on location accuracy */
    bool rejected = false;
	//remove least recent sample
	if ([samples count] >= maxSamples)
		[samples removeLastObject];
	//insert this sample at beginning
	[samples insertObject:[NSNumber numberWithDouble: horizontalAccuracy ] atIndex:0];
	
	//sort so we can calculate quantiles
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
	NSArray *sorters = [[NSArray alloc] initWithObjects:sorter, nil];
	NSArray *sortedSamples = [samples sortedArrayUsingDescriptors:sorters];

	
	//100m, or within desiredAccuracy is a good start
	int goodStartAccuracy = locationManager.desiredAccuracy;
	if (goodStartAccuracy < 100) goodStartAccuracy = 100;
    int adaptedGoodEnoughAccuracy;
	//decide wether to accept the sample
	if ([samples count] >= maxSamples) {
		//we expect within 2* second quartile, this rejects outliers
		adaptedGoodEnoughAccuracy = [[sortedSamples objectAtIndex:(int)(maxSamples/2)] intValue] * 2;
		//NSLog(@"adapted: %d", adaptedGoodEnoughAccuracy);
		if (horizontalAccuracy <= adaptedGoodEnoughAccuracy)
			;
		else
			rejected = YES;;
	}
	else if ([samples count] < maxSamples && horizontalAccuracy <= goodStartAccuracy)
		; //accept if we haven't collected many samples, but accuracy is alread quite good
	else 
		rejected = YES; //reject sample
    if (rejected)
        return;
    
    /* filter points when not moving. This avoids a lot of unnecessary points to upload. Without this filter at best accuracy it will generate a point every second. */
    if (lastAcceptedPoint != nil) {
        double distance = [newLocation distanceFromLocation:lastAcceptedPoint];
        double interval = [newLocation.timestamp timeIntervalSinceDate:lastAcceptedPoint.timestamp];
        if (!(distance >= minDistance || interval >= minInterval || newLocation.horizontalAccuracy < lastAcceptedPoint.horizontalAccuracy))
            return;
    }
    lastAcceptedPoint = newLocation;


	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%.8f", longitude], longitudeKey,
									[NSString stringWithFormat:@"%.8f", latitude], latitudeKey,
									[NSString stringWithFormat:@"%.0f", horizontalAccuracy], horizontalAccuracyKey,
									nil];
	if (newLocation.speed >=0) {
		[newItem setObject:[NSString stringWithFormat:@"%.1f",speed] forKey:speedKey];
	}
	if (newLocation.verticalAccuracy >= 0) {
		[newItem setObject:[NSString stringWithFormat:@"%.0f", altitude] forKey:altitudeKey];
		[newItem setObject:[NSString stringWithFormat:@"%.0f", verticalAccuracy] forKey:verticalAccuracyKey];
	}
	
	double timestamp = [newLocation.timestamp timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										[NSString stringWithFormat:@"%.3f",timestamp],@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    
    /* implement strategy to disable location for some time */
    //noise is already filtered, so don't filter for accuracy
    if (isAdaptive) {
    if (locationManager.desiredAccuracy == 0 && abs([newLocation.timestamp timeIntervalSinceNow]) < 5 && abs([lastOn timeIntervalSinceNow]) > 30)  {
        NSTimeInterval dt = previousLocation != nil ? [newLocation.timestamp timeIntervalSinceDate:(previousLocation.timestamp)] : 0;
        double ds = [newLocation distanceFromLocation:previousLocation];
        double maxDistance = MIN(previousLocation.horizontalAccuracy + newLocation.horizontalAccuracy + 20, 100);
        if (previousLocation == nil || ds > maxDistance) {
            previousLocation = newLocation;
        } else if (dt > 60) { //60 is a threshold to prevent the gps from aquiring/releasing a lock too frequently, and has several advantages
            //no change in location for a while, disable location and set the timer
            NSTimeInterval interval = MIN (dt, 1800);
            NSLog(@"invalidate");
            @synchronized(self) {
                [newSampleTimer invalidate];
                newSampleTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(startUpdating) userInfo:nil repeats:NO];
                //[locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
                locationManager.desiredAccuracy = 500;
            }
            NSLog(@"Suspending location updates for %d seconds", (NSInteger)interval);
        }
    } else if (locationManager.desiredAccuracy == 500){
        //detect movement for very inaccurate samples
        if ([newLocation distanceFromLocation:previousLocation] > newLocation.horizontalAccuracy + previousLocation.horizontalAccuracy + 20) {
            NSLog(@"movement detected using inaccurate samples");
            [self startUpdating];
        }
    }
    }
    
    if ([[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"energyAdaptive"] boolValue] && locationManager.desiredAccuracy < 500 &&
        (abs([lastOn timeIntervalSinceNow]) > 60 || newLocation.horizontalAccuracy <= 20)) {
        locationManager.desiredAccuracy = 1000;
    }
    /* end */
}

- (BOOL) isEnabled {return isEnabled;}

- (void) startUpdating {
    lastOn = [[NSDate alloc] init];
    //[locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
    @synchronized(self) {
        locationManager.desiredAccuracy = 0;
        if (![[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"energyAdaptive"] boolValue]) {
            newSampleTimer = nil;
        }
    }
    //NSLog(@"startUpdating");
}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling location sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		@try {
			locationManager.desiredAccuracy = [[[Settings sharedSettings] getSettingType:@"position" setting:@"accuracy"] intValue];
		} @catch (NSException* e) {
			NSLog(@"Exception setting position accuracy: %@", e);
		}
		[samples removeAllObjects];
        if ([[[Settings sharedSettings] getSettingType:@"adaptive" setting:@"locationAdaptive"] boolValue]) {
            [self startUpdating];
            [self motion];
        }
        [locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
        
	}
	else {
        [newSampleTimer invalidate];
        [locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
		[samples removeAllObjects];
        [motionManager stopDeviceMotionUpdates];
        motionManager = nil;
	}
	isEnabled = enable;
}

- (void) motion {
    [motionManager stopDeviceMotionUpdates];
    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1;
    
    CMDeviceMotionHandler deviceMotionHandler = ^ (CMDeviceMotion *deviceMotion, NSError *error) {
    CMAcceleration a = deviceMotion.userAcceleration;
        double magnitude = sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
        if (magnitude*9.81 > 2) {
            NSLog(@"motion!");
            @synchronized(self) {
                if (newSampleTimer != nil) {
                    NSTimeInterval deltaT = [[newSampleTimer fireDate] timeIntervalSinceNow];
                    deltaT /= 1 + 0.15;
                
                    if (deltaT > 5) {
                        NSLog(@"next sample in %d seconds", (int) deltaT);
                        NSNumber* t = [NSNumber numberWithDouble:deltaT];
                        [self performSelectorOnMainThread:@selector(setSampleInterval:) withObject:t waitUntilDone:YES];
                    }
                }
            }
        }
    };
    [motionManager startDeviceMotionUpdatesToQueue:operations withHandler:deviceMotionHandler];      
}

- (void) setSampleInterval:(NSNumber*) interval {
    [newSampleTimer invalidate];
    newSampleTimer = [NSTimer scheduledTimerWithTimeInterval:[interval doubleValue] target:self selector:@selector(startUpdating) userInfo:nil repeats:NO];
}

- (void) settingChanged: (NSNotification*) notification  {
	@try {
		Setting* setting = notification.object;
		NSLog(@"Location setting %@ changed to %@.", setting.name, setting.value);

		if ([setting.name isEqualToString:@"accuracy"]) {
			locationManager.desiredAccuracy = [setting.value integerValue];
		} else if ([setting.name isEqualToString:@"interval"]) {
            [newSampleTimer invalidate];
            newSampleTimer = [NSTimer scheduledTimerWithTimeInterval:[setting.value doubleValue] target:self selector:@selector(startUpdating) userInfo:nil repeats:YES];
        } else if ([setting.name isEqualToString:@"locationAdaptive"]) {
            isAdaptive = [setting.value boolValue];
            if (isAdaptive) {
                [self startUpdating];
                [self motion];
            } else {
                [motionManager stopDeviceMotionUpdates];
                [newSampleTimer invalidate];
            }
        }
	}
	@catch (NSException * e) {
		NSLog(@"LocationSensor: Exception thrown while applying location settings: %@", e);
	}
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}
@end