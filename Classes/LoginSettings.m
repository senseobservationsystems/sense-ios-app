//
//  LoginSettings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/17/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "LoginSettings.h"
#import "Senseplatform/CSSensePlatform.h"
#import "SensePlatform/CSSettings.h"
#import "RegisterUserView.h"

@implementation LoginSettings {
    UIAlertView* loginAlert;
    UIAlertView* registerAlert;
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = @"Login account";
	    
    //Initialize alert views
    loginAlert = [[UIAlertView alloc] initWithTitle:@"Login" message:@"Username and password?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login",nil];
    loginAlert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    registerAlert = [[UIAlertView alloc] initWithTitle:@"Register" message:@"Enter your details" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Register",nil];
    registerAlert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
//    [registerAlert textFieldAtIndex:2] = [[UITextField alloc] init];
}


- (void)viewWillAppear:(BOOL)animated {
    [self updateText];
}

- (void) updateText {
    CSSettings* settings = [CSSettings sharedSettings];
    
	NSString* username = [settings getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
    NSString* text;
    if (username) {
        text = [NSString stringWithFormat:@"Logged in as %@.", username];
    } else {
        text = [NSString stringWithFormat:@"Not logged in."];
    }
    [self.textLabel setText:text];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
	//return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction) registerAccount {
        [self updateText];
    RegisterUserView* view = [[RegisterUserView alloc] initWithStyle:UITableViewStyleGrouped];
    self.navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:view animated:YES completion:^(void){}];
    //[self.navigationController presentModalViewController:view animated:YES];
    //[self.navigationController pushViewController:view animated:YES];
    //Show UIView with the fields
    
    /*
	//show activity indicator
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = self.view.center;
	[self.view addSubview:activityIndicator];
	[self.view bringSubviewToFront:activityIndicator];
	[activityIndicator setNeedsDisplay];
	[activityIndicator startAnimating];

	//register new user
	NSString* error = nil;
	BOOL succes = [CSSensePlatform registerUser:username.text withPassword:password.text];
    
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];
	
	//Alert on failure
	if (!succes) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to register" message:error delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
		[alert show];
	} else {
		//and login
		[self loginAccount];
	}
     */
}


- (IBAction) loginAccount {
    [loginAlert show];
}

- (void) performLoginWithUser:(NSString*) user andPassword:(NSString*) password {    
     //show activity indicator
     UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
     activityIndicator.center = self.view.center;
     [self.view addSubview:activityIndicator];
     [self.view bringSubviewToFront:activityIndicator];
     [activityIndicator startAnimating];
     
     //[[SensorStore sharedSensorStore].sender setUser:username.text andPassword:password.text];
     BOOL succes = [CSSensePlatform loginWithUser:user andPassword:password];
     [activityIndicator stopAnimating];
     [activityIndicator removeFromSuperview];
     
     
     //Alert on failure
     if (!succes) {
         UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"Couldn't login" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
         [alert show];
     } else {
         //save settings
         [[CSSettings sharedSettings] setLogin:user withPassword:password];
         //dismiss this view
         [self.navigationController popViewControllerAnimated:YES];
     }

}


- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == loginAlert) {
        switch (buttonIndex) {
            case 0:
                break;
            case 1: {
                NSString* username = [alertView textFieldAtIndex:0].text;
                NSString* password = [alertView textFieldAtIndex:1].text;
                [self performLoginWithUser:username andPassword:password];
                
                break;
            }
        }
    }
}

@end
