//
//  Settings.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>

//notifications
extern NSString* settingSenseEnabledChangedNotification;
extern NSString* settingLoginChangedNotification;

//general settings
extern NSString* generalSettingUsernameKey;
extern NSString* generalSettingPasswordKey;
extern NSString* generalSettingSenseEnabledKey;
extern NSString* generalSettingSynchronisationRateKey;
extern NSString* generalSettingPollRateKey;

//location settings
extern NSString* locationSettingAccuracyKey;
extern NSString* locationSettingMinimumDistanceKey;

@interface Settings : NSObject {
	@private NSMutableDictionary* settings;
	@private NSMutableDictionary* general;
	@private NSMutableDictionary* location;
	@private NSMutableDictionary* sensorEnables;
}
+ (Settings*) sharedSettings;
+ (NSString*) enabledChangedNotificationNameForSensor:(Class) sensor;
- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable;
- (BOOL) isSensorEnabled:(Class) sensor;

- (void) storeSettings;
- (void) loadSettingsFromPath:(NSString*)path;

//used to get groups of properties
@property (assign, readonly) NSMutableDictionary* general;
@property (assign, readonly) NSMutableDictionary* location;

//used to set individual settings, returns whether the setting was accepted
- (BOOL) setSenseEnabled:(BOOL) enable;
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;
@end
