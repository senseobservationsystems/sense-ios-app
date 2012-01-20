//
//  ActivityFeedback.h
//  sensePlatform
//
//  Created by Pim Nijdam on 1/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "Sensor.h"
#import "Activity.h"

@interface ActivityFeedback : Sensor
+ (void) commitActivity: (Activity*) activity;
@end
