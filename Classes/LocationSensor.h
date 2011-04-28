//
//  LocationSensor.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sensor.h"
#import <CoreLocation/CoreLocation.h>

@interface LocationSensor : Sensor <CLLocationManagerDelegate>{
	CLLocationManager* locationManager;
}

@property BOOL isEnabled;
- (void) applyLocationSettings;
@end
