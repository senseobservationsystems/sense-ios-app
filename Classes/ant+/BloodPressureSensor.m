//
//  BloodPressureSensor.m
//  sensePlatform
//
//  Created by Pim Nijdam on 4/17/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "BloodPressureSensor.h"
#import <WFConnector/WFHardwareConnector.h>
#import <WFConnector/WFAntFS.h>
#import <WFConnector/WFAntFileManager.h>
#import <WFConnector/WFFitFileInfo.h>

@implementation BloodPressureSensor {
    WFBloodPressureManager* bpm;
    WFHardwareConnector* hardwareConnector;
}

- (id) init {
    self = [super init];
    if (self) {
        // configure the hardware connector.
        hardwareConnector = [WFHardwareConnector sharedConnector];
    }
    return self;
}


- (void) scan {
        [hardwareConnector requestAntFSDevice: WF_ANTFS_DEVTYPE_BLOOD_PRESSURE_CUFF
                                   toDelegate:	self];
}


- (void) connectToBloodPressure {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSArray* passArray = [defaults arrayForKey:@"antPass"];
    
    if (passArray == nil || [passArray isKindOfClass:[NSArray class]] == NO) {
        NSNumber* zero = [NSNumber numberWithChar:0];
        passArray = [NSArray arrayWithObjects:zero, zero, zero, zero, nil];
    }
    UCHAR pass[[passArray count]];
    for (int i=0; i < [passArray count]; i++) {
        pass[i] = [[passArray objectAtIndex:i] charValue];
    }
    NSLog(@"Trying to connect with pass %@", passArray);
    [bpm connectToDevice:pass passkeyLength:[passArray count]];
}

- (void) syncTime {
    [bpm setDeviceTime];
}

- (void) getDirectoryInfo {
    NSLog(@"get directory info");
    [bpm requestDirectoryInfo];
}

//implement the WFAntFSDelegate

- (void) antFSDevice:(WFAntFSDevice *) fsDevice instanceCreated:(BOOL) 	bSuccess {
    NSLog(@"ant fs device instance created. %@", bSuccess ? @"succeed" : @"failed");
    
    if (true) {
        bpm = (WFBloodPressureManager*) fsDevice;
        NSLog(@"Connected to bloodpressure monitor with serial number %lui", bpm.clientSerialNumber);
        [self connectToBloodPressure];
    }
}

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       downloadFinished:		(BOOL) 	bSuccess
               filePath:		(NSString *) 	filePath {
    BOOL wtf = NO;
    NSArray* records = [bpm getFitRecordsFromFile:filePath cancelPointer:&wtf];
    
    for (NSObject* o in records) {
        if ([o isKindOfClass:WFFitMessageBloodPressure.class]) {
            WFFitMessageBloodPressure* record = (WFFitMessageBloodPressure*)o;
            USHORT heartRate = record.heartRate;
            USHORT diastollicPressure = record.diastolicPressure;
            USHORT systollicPressure = record.systolicPressure;
            NSTimeInterval timestamp = [record.timestamp timeIntervalSince1970];
            NSLog(@"Record at %.0f. Contains (%u, %u, %u)",timestamp, (unsigned int)heartRate, (unsigned int)systollicPressure, (unsigned int)diastollicPressure);
        }
    }
}

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       downloadProgress:		(ULONG) 	bytesReceived {
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
  receivedDirectoryInfo:		(WFAntFSDirectory *) 	directoryInfo {
    //log directory structure
    NSMutableString* log = [[NSMutableString alloc] init];
    [log appendFormat:@"%i entries.", directoryInfo.numberOfEntries];
    
    for (size_t i =0; i < directoryInfo.numberOfEntries; i++) {
        ANTFSP_DIRECTORY* dir = [directoryInfo entryAtIndex:i];
        [log appendFormat:@"entry %i: %c, %c, size %il, fileIndex %i, fileNumber %i\n", i, dir->ucFileDataType, dir->ucFileSubType, dir->ulFileSize, (int)dir->usFileIndex, (int)dir->usFileNumber];
    }
    
    NSLog(@"%@", log);
    
    int i=2;
    ULONG size = [directoryInfo entryAtIndex:i]->ulFileSize;
    [antFileManager requestFile:i fileSize: size];
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       receivedResponse:		(ANTFS_RESPONSE) 	responseCode {
    NSLog(@"received response %i (%@)", responseCode, [self stringFromReturnCode:responseCode]);
    
    /*
     if (responseCode == ANTFS_RESPONSE_CONNECTION_LOST) {
     [hardwareConnector releaseAntFSDevice:bpm];
     //try to connect to an ant fs device
     [hardwareConnector requestAntFSDevice: WF_ANTFS_DEVTYPE_BLOOD_PRESSURE_CUFF
     toDelegate:	self];
     }
     */
    
    /*
     if (responseCode == ANTFS_RESPONSE_OPEN_PASS || responseCode == ANTFS_RESPONSE_CONNECT_PASS) {
     [self connectToBloodPressure];
     [bpm requestDirectoryInfo];
     } else if (responseCode == ANTFS_RESPONSE_AUTHENTICATE_PASS) {
     [bpm requestDirectoryInfo];
     }
     */
} 

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
          updatePasskey:		(UCHAR *) 	pucPasskey
                 length:		(UCHAR) 	ucLength {
    NSLog(@"update pass key with length %d",(NSInteger) ucLength);
    NSMutableArray* pass = [[NSMutableArray alloc] init];
    NSMutableString *passString = [[NSMutableString alloc] init];
    for (int i = 0; i < ucLength; i++) {
        NSNumber* o = [NSNumber numberWithChar:pucPasskey[i]];
        [pass addObject:o];
        [passString appendFormat:@"%i:", [o intValue]];
        
    }
    NSLog(@"pass key: %@", passString);
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pass forKey:@"antPass"];
    [defaults synchronize];
}

- (NSString*) stringFromReturnCode:(ANTFS_RESPONSE) responseCode {
    switch (responseCode) {
            
        case ANTFS_RESPONSE_NONE 	:
            return @"ANTFS_RESPONSE_NONE";	
        case ANTFS_RESPONSE_OPEN_PASS 	:
            return @"ANTFS_RESPONSE_OPEN_PASS";	
        case ANTFS_RESPONSE_SERIAL_FAIL 	:
            return @"ANTFS_RESPONSE_SERIAL_FAIL";	
        case ANTFS_RESPONSE_BEACON_OPEN 	:
            return @"ANTFS_RESPONSE_BEACON_OPEN";	
        case ANTFS_RESPONSE_BEACON_CLOSED 	:
            return @"ANTFS_RESPONSE_BEACON_CLOSED";	
        case ANTFS_RESPONSE_CONNECT_PASS 	:
            return @"ANTFS_RESPONSE_CONNECT_PASS";	
        case ANTFS_RESPONSE_DISCONNECT_PASS 	:
            return @"ANTFS_RESPONSE_DISCONNECT_PASS";	
        case ANTFS_RESPONSE_DISCONNECT_BROADCAST_PASS 	:
            return @"ANTFS_RESPONSE_DISCONNECT_BROADCAST_PASS";	
        case ANTFS_RESPONSE_CONNECTION_LOST 	:
            return @"ANTFS_RESPONSE_CONNECTION_LOST";	
        case ANTFS_RESPONSE_AUTHENTICATE_NA 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_NA";	
        case ANTFS_RESPONSE_AUTHENTICATE_PASS 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_PASS";	
        case ANTFS_RESPONSE_AUTHENTICATE_REJECT 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_REJECT";	
        case ANTFS_RESPONSE_AUTHENTICATE_FAIL 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_FAIL";	
        case ANTFS_RESPONSE_PAIRING_REQUEST 	:
            return @"ANTFS_RESPONSE_PAIRING_REQUEST";	
        case ANTFS_RESPONSE_PAIRING_TIMEOUT 	:
            return @"ANTFS_RESPONSE_PAIRING_TIMEOUT";	
        case ANTFS_RESPONSE_DOWNLOAD_REQUEST 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_REQUEST";	
        case ANTFS_RESPONSE_DOWNLOAD_PASS 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_PASS";	
        case ANTFS_RESPONSE_DOWNLOAD_REJECT 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_REJECT";	
        case ANTFS_RESPONSE_DOWNLOAD_INVALID_INDEX 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_INVALID_INDEX";	
        case ANTFS_RESPONSE_DOWNLOAD_FILE_NOT_READABLE 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_FILE_NOT_READABLE";	
        case ANTFS_RESPONSE_DOWNLOAD_NOT_READY 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_NOT_READY";	
        case ANTFS_RESPONSE_DOWNLOAD_FAIL 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_FAIL";	
        case ANTFS_RESPONSE_UPLOAD_REQUEST 	:
            return @"ANTFS_RESPONSE_UPLOAD_REQUEST";	
        case ANTFS_RESPONSE_UPLOAD_PASS 	:
            return @"ANTFS_RESPONSE_UPLOAD_PASS";	
        case ANTFS_RESPONSE_UPLOAD_REJECT 	:
            return @"ANTFS_RESPONSE_UPLOAD_REJECT";	
        case ANTFS_RESPONSE_UPLOAD_INVALID_INDEX 	:
            return @"ANTFS_RESPONSE_UPLOAD_INVALID_INDEX";	
        case ANTFS_RESPONSE_UPLOAD_FILE_NOT_WRITEABLE 	:
            return @"ANTFS_RESPONSE_UPLOAD_FILE_NOT_WRITEABLE";	
        case ANTFS_RESPONSE_UPLOAD_INSUFFICIENT_SPACE 	:
            return @"ANTFS_RESPONSE_UPLOAD_INSUFFICIENT_SPACE";	
        case ANTFS_RESPONSE_UPLOAD_FAIL 	:
            return @"ANTFS_RESPONSE_UPLOAD_FAIL";	
        case ANTFS_RESPONSE_ERASE_REQUEST 	:
            return @"ANTFS_RESPONSE_ERASE_REQUEST";	
        case ANTFS_RESPONSE_ERASE_PASS 	:
            return @"ANTFS_RESPONSE_ERASE_PASS";	
        case ANTFS_RESPONSE_ERASE_REJECT 	:
            return @"ANTFS_RESPONSE_ERASE_REJECT";	
        case ANTFS_RESPONSE_ERASE_FAIL 	:
            return @"ANTFS_RESPONSE_ERASE_FAIL";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_PASS 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_PASS";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_TRANSMIT_FAIL 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_TRANSMIT_FAIL";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_RESPONSE_FAIL 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_RESPONSE_FAIL";	
        case ANTFS_RESPONSE_CANCEL_DONE :
            return @"ANTFS_RESPONSE_CANCEL_DON"; 
            
        default:
            return @"unknown response code";
    }
}

@end