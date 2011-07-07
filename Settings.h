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
extern NSString* settingSynchronisationChangedNotification;
extern NSString* anySettingChangedNotification;

//general settings
extern NSString* generalSettingUsernameKey;
extern NSString* generalSettingPasswordKey;
extern NSString* generalSettingSenseEnabledKey;
extern NSString* generalSettingSynchronisationRateKey;
extern NSString* generalSettingPollRateKey;

//location settings
extern NSString* locationSettingAccuracyKey;
extern NSString* locationSettingMinimumDistanceKey;

@interface Setting : NSObject
{
	NSString* name;
	NSString* value;
}

@property (copy) NSString* name;
@property (copy) NSString* value;

@end


@interface Settings : NSObject {
	@private NSMutableDictionary* settings;
	@private NSMutableDictionary* general;
	@private NSMutableDictionary* location;
	@private NSMutableDictionary* sensorEnables;
}
+ (Settings*) sharedSettings;
+ (NSString*) enabledChangedNotificationNameForSensor:(Class) sensor;
+ (NSString*) settingChangedNotificationNameForSensor:(Class) sensor;
+ (NSString*) settingChangedNotificationNameForType:(NSString*) type;
- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable;
- (BOOL) isSensorEnabled:(Class) sensor;
- (void) sendNotificationForSensor:(Class) sensor;
- (id) getSettingType: (NSString*) type setting:(NSString*) setting;
- (BOOL) commitSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value;

- (void) storeSettings;
- (void) loadSettingsFromPath:(NSString*)path;
- (void) anySettingChanged:(NSString*)setting value:(NSString*)value;

//used to get groups of properties
@property (assign, readonly) NSMutableDictionary* general;
@property (assign, readonly) NSMutableDictionary* location;

//used to set individual settings, returns whether the setting was accepted
- (BOOL) setSenseEnabled:(BOOL) enable;
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;
@end
