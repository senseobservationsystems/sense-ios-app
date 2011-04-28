//
//  LoginSettings.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/17/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoginSettings : UIViewController <UITextFieldDelegate>{
	UITextField* username;
	UITextField* password;

}

@property (nonatomic, retain) IBOutlet UITextField* username;
@property (nonatomic, retain) IBOutlet UITextField* password;

- (IBAction) registerAccount;
- (IBAction) loginAccount;

@end