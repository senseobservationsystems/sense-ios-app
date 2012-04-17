//
//  AntViewController.h
//  sensePlatform
//
//  Created by Pim Nijdam on 4/16/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AntViewController : UIViewController {
    UITextView* detail;
}
@property (nonatomic, strong) IBOutlet UITextView* detail;

- (IBAction) scan;
- (IBAction) connectBloodPressure;
- (IBAction) getDirectoryInfo;
- (IBAction) getFile;
@end
