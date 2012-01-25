//
//  AlertPrompt.h
//  sensePlatform
//
//  Created by Pim Nijdam on 1/23/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlertPrompt : UIAlertView 
{
    UITextField *textField;
}
@property (nonatomic, retain) UITextField *textField;
@property (readonly, retain) NSString *enteredText;
- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle;
@end
