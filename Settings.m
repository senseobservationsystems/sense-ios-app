//
//  Settings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "Settings.h"

//notifications
NSString* settingLoginChangedNotification = @"settingLoginChangedNotification";
NSString* anySettingChangedNotification = @"anySettingChangedNotification";

//general settings keys
NSString* generalSettingSenseEnabledKey = @"senseEnabled";
NSString* generalSettingUsernameKey = @"username";
NSString* generalSettingPasswordKey = @"password";
NSString* generalSettingSenseEnabled = @"senseEnabled";
NSString* generalSettingSynchronisationRateKey = @"synchronisationRate";
NSString* generalSettingPollRateKey = @"pollRate";


//location settings keys
NSString* locationSettingAccuracyKey = @"accuracy";
NSString* locationSettingMinimumDistanceKey = @"minimumDistance";

@implementation Setting
@synthesize name;
@synthesize value;
@end


@implementation Settings
@synthesize general;
@synthesize location;

//Singleton instance
static Settings* sharedSettingsInstance = nil;

+ (Settings*) sharedSettings {
	if (sharedSettingsInstance == nil) {
		sharedSettingsInstance = [[super allocWithZone:NULL] init];
	}
	return sharedSettingsInstance;	
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedSettings];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id) init {
	self = [super init];
	if (self) {
		//initialise settings from plist
        NSString* plistPath;
		
		//Try to load saved settings
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
			//fallback to default settings
			plistPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        }
		@try {
			[self loadSettingsFromPath:plistPath];
		}
		@catch (NSException * e) {
			NSLog(@"Settings: exception thrown while loading settings: %@", e);
			settings = nil;
		}
		if (settings == nil) {
			//fall back to defaults
			@try {
				[self loadSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"]];
			}
			@catch (NSException * e) {
				NSLog(@"Settings: exception thrown while loading default settings. THIS IS VERY SERIOUS: %@", e);
				settings = nil;
			}
		}
	}
	return self;
}

#pragma mark - 
#pragma mark Settings

+ (NSString*) enabledChangedNotificationNameForSensor:(Class) sensor {
	return [NSString stringWithFormat:@"%@EnabledChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForSensor:(Class) sensor {
	return [NSString stringWithFormat:@"%@SettingChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForType:(NSString*) type {
	return [NSString stringWithFormat:@"%@SettingChangedNotificationType", type];
}

- (BOOL) isSensorEnabled:(Class) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	return enabled;
}

- (void) sendNotificationForSensor:(Class) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	NSNumber* enableObject = [NSNumber numberWithBool:enabled];
	
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
}

- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable {
    return [self setSensor:sensor enabled:enable permanent:YES];
}

- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable permanent:(BOOL) permanent {
	NSNumber* enableObject = [NSNumber numberWithBool:enable];
    NSString* key = [NSString stringWithFormat:@"%@", sensor];
    if (permanent) {
        //store enable settings
        [sensorEnables setObject:enableObject forKey:key];
        //write back to file
        [self storeSettings];
    }
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
	[self anySettingChanged:key value:enable?@"true":@"false"];
	return YES;
}

- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password {
	[general setObject:user forKey:generalSettingUsernameKey];
	[general setObject:password forKey:generalSettingPasswordKey];
	//write back to file
	[self storeSettings];
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:settingLoginChangedNotification object:nil]];
	return YES;
}


- (id) getSettingType: (NSString*) type setting:(NSString*) setting {
	NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
	NSMutableDictionary* typeSettings = [settings valueForKey:name];
	if (typeSettings != nil) {
		return [typeSettings objectForKey: setting];
	}
	return nil;
}

- (BOOL) commitSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent {
    if (persistent) {
        //get sensor settings;
        NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
        NSMutableDictionary* typeSettings = [settings valueForKey:name];
        if (typeSettings == nil) {
            //create if it doesn't already exist
            typeSettings = [NSMutableDictionary new];
            [settings setObject:typeSettings forKey:name];
        }
        
        //commit setting
        [typeSettings setObject:value forKey:setting];
        [self storeSettings];
    }
	
	//create notification object
	Setting* notificationObject = [[Setting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] settingChangedNotificationNameForType:type] object:notificationObject]];
	[self anySettingChanged:setting value:value];
	
	//free
	
	return YES;
}



#pragma mark -
#pragma mark Private

- (void) anySettingChanged:(NSString*)setting value:(NSString*)value {
	//create notification object
	Setting* notificationObject = [[Setting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:anySettingChangedNotification object:notificationObject]];
	
	//free
}

- (void) loadSettingsFromPath:(NSString*)path {
	NSLog(@"Loading settings from %@", path);
	NSString* errorDesc = nil;
	NSPropertyListFormat format;
	
	NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:path];
	settings = (NSMutableDictionary *)[NSPropertyListSerialization
									   propertyListFromData:plistXML
									   mutabilityOption:NSPropertyListMutableContainersAndLeaves
									   format:&format
									   errorDescription:&errorDesc];
	if (!settings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
	//instantiate subsections of settings
	general = [settings valueForKey:@"general"];
	location = [settings valueForKey:@"location"];
	sensorEnables = [settings valueForKey:@"sensorEnables"];
	if (sensorEnables == nil) {
		sensorEnables = [NSMutableDictionary new];
		[settings setObject:sensorEnables forKey:@"sensorEnables"];
	}
}

- (void) storeSettings {
	@try {
		NSString *error;
		NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
		NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:settings
																	   format:NSPropertyListXMLFormat_v1_0
															 errorDescription:&error];
		if(plistData) {
			[plistData writeToFile:plistPath atomically:YES];
		}
		else {
			NSLog(@"%@", error);
		}
	}
	@catch (NSException * e) {
		NSLog(@"Settings:Exception thrown while storing settings: %@", e);
	}
}
@end
