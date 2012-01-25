//
//  Activity.h
//  sensePlatform
//
//  Created by Pim Nijdam on 1/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

//Class used to store activity related information
@interface Activity : NSObject {
    NSString* type;
    NSDate* start;
    NSDate* stop; 
    NSString* comment;
}
@property (strong, nonatomic) NSString* type;
@property (strong, nonatomic) NSDate* start;
@property (strong, nonatomic) NSDate* stop;
@property (strong, nonatomic) NSString* comment;
@end
