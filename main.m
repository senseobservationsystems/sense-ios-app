//
//  main.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
void exceptionHandler(NSException *exception);
void exceptionHandler(NSException *exception) {
    NSLog(@"Uncaught exception %@(%@):\n%@", exception.name, exception.description, exception.callStackSymbols);
}

int main(int argc, char *argv[]) {
      	NSSetUncaughtExceptionHandler(&exceptionHandler);
    int retVal;
        retVal = UIApplicationMain(argc, argv, nil, nil);
    return retVal;
}

