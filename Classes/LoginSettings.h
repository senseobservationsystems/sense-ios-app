//
//  LoginSettings.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/17/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoginSettings : UIViewController <UIAlertViewDelegate>{
}

@property (nonatomic, strong) IBOutlet UILabel* textLabel;

- (IBAction) registerAccount;
- (IBAction) loginAccount;

@end