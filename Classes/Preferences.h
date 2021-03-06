//
//  Preferences.h
//  senseApp
//
//  Created by Pim Nijdam on 5/12/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Preferences : UITableViewController {
    UISwitch* adaptiveSwitch;
    UISwitch* locationMotionSwitch;
    UISlider* chargeCycleSlider;
}

- (void) switchChanged:(UISwitch*) switchButton;
- (void) sliderChanged:(UISlider*) slider;

@end
