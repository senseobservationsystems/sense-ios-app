//
//  Settings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "Settings.h"

//notifications
NSString* settingSenseEnabledChangedNotification = @"settingSenseEnabledChangedNotification";
NSString* settingLoginChangedNotification = @"settingLoginChangedNotification";

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
    return [[self sharedSettings] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (id) init {
	[super init];
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

- (BOOL) setSenseEnabled:(BOOL) enable {
	NSNumber* enableObject = [NSNumber numberWithBool:enable];
	//write back to file
	[self storeSettings];
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:settingSenseEnabledChangedNotification object:enableObject]];
	return YES;
}

+ (NSString*) enabledChangedNotificationNameForSensor:(Class) sensor {
	return [NSString stringWithFormat:@"%@EnabledChangedNotification", sensor];
}

- (BOOL) isSensorEnabled:(Class) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	return enabled;
}

- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable {
	NSNumber* enableObject = [NSNumber numberWithBool:enable];
	//store enable settings
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	[sensorEnables setObject:enableObject forKey:key];
	//write back to file
	[self storeSettings];
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
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

#pragma mark -
#pragma mark Private

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
	[settings retain];
	if (!settings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
	//instantiate subsections of settings
	general = [[settings valueForKey:@"general"] retain];
	location = [[settings valueForKey:@"location"] retain];
	sensorEnables = [[settings valueForKey:@"sensorEnables"] retain];
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
			[error release];
		}
	}
	@catch (NSException * e) {
		NSLog(@"Settings:Exception thrown while storing settings: %@", e);
	}
}
@end
