//
//  AntDevicesWahooDongle.m
//  sensePlatform
//
//  Created by Pim Nijdam on 3/30/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "AntPlusController.h"
#import "FootpodSensor.h"
#import "SensorStore.h"

@interface AntPlusController (Private)
- (void) connectSensorType:(WFSensorType_t) sensorType;
- (void) scan;
@end

@implementation AntPlusController {
    WFHardwareConnector* hardwareConnector;
    NSMutableArray* sensors;
    NSTimer* scanTimer;
}

- (id) init {
    self = [super init];
    if (self) {
        // configure the hardware connector.
        hardwareConnector = [WFHardwareConnector sharedConnector];
        hardwareConnector.delegate = self;
        hardwareConnector.sampleRate = 5;
        sensors = [[NSMutableArray alloc] init];
        // determine support for BTLE.
        if ( hardwareConnector.hasBTLESupport ) {
            // enable BTLE.
            [hardwareConnector enableBTLE:TRUE];
        }
        NSLog(@"%@", hardwareConnector.hasBTLESupport?@"DEVICE HAS BTLE SUPPORT":@"DEVICE DOES NOT HAVE BTLE SUPPORT");
        
        // set HW Connector to call hasData only when new data is available.
        [hardwareConnector setSampleTimerDataCheck:YES];
    }
    return self;
}



- (void) connectSensorType:(WFSensorType_t) sensorType {
    WFConnectionParams* params = [[WFConnectionParams alloc] init];
    params.sensorType = sensorType;
    
    WFSensorConnection* sensorConnection;
    sensorConnection = [hardwareConnector requestSensorConnection:params];
 }

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector connectedSensor:(WFSensorConnection*)connection
{
    NSLog(@"Sensor connected: %@", connection.deviceIDString);
    //create new sensor
    if (connection.sensorType == WF_SENSORTYPE_FOOTPOD) {
        FootpodSensor* s = [[FootpodSensor alloc] initWithConnection:connection];
        s.dataStore = [SensorStore sharedSensorStore];
        [sensors addObject:s];
        
    }
}

//--------------------------------------------------------------------------------
- (void)hardwareConnector:(WFHardwareConnector*)hwConnector disconnectedSensor:(WFSensorConnection*)connectionInfo
{
    NSLog(@"Sensor disconnected %@: %@", connectionInfo.deviceIDString, connectionInfo.description);
    
}

//--------------------------------------------------------------------------------
- (void)hardwareConnector:(WFHardwareConnector*)hwConnector stateChanged:(WFHardwareConnectorState_t)currentState
{
    BOOL connected = ((currentState & WF_HWCONN_STATE_ACTIVE) || (currentState & WF_HWCONN_STATE_BT40_ENABLED)) ? TRUE : FALSE;
    NSLog(@"connector %@", connected ? @"present" : @"not present");
    [scanTimer invalidate];
    scanTimer = nil;
    if (connected) {
        scanTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scan) userInfo:nil repeats:YES];
    }
}

- (void) scan {
    NSLog(@"ant+ scan");
    //TODO: create manual to scan for devices, and automatically connect to devices we've connected to in the past?
    WFSensorType_t sensorTypes[] = {WF_SENSORTYPE_FOOTPOD};
    size_t nrSensorTypes = sizeof(sensorTypes) / sizeof(sensorTypes[0]);
    
    for (int i = 0; i < nrSensorTypes; i++) {
        WFSensorType_t sensorType = sensorTypes[i];
        //already have a connection to such a sensor
        if ([[hardwareConnector getSensorConnections:sensorType] count] > 0) {
            //skip
        } else if ([[Settings sharedSettings] isSensorEnabled:[FootpodSensor class]]){ 
            //try to connect to such a sensor
            [self connectSensorType:sensorType];
        }
    }
}

- (void)hardwareConnectorHasData
{
    NSLog(@"connector has data. %d sensors", sensors.count);
    for (FootpodSensor* sensor in sensors) {
        [sensor checkData];
    }
}


@end