//
//  LoginSettings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/17/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "LoginSettings.h"
#import "SensorStore.h"
#import "Sender.h"


@implementation LoginSettings
@synthesize username;
@synthesize password;

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
	Settings* settings = [Settings sharedSettings];
	username.text = [settings.general valueForKey:generalSettingUsernameKey];
	//really?
	password.text = [settings.general valueForKey:generalSettingPasswordKey];
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


- (void)dealloc {
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (IBAction) registerAccount {
	//show activity indicator
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = self.view.center;
	[self.view addSubview:activityIndicator];
	[self.view bringSubviewToFront:activityIndicator];
	[activityIndicator setNeedsDisplay];
	[activityIndicator startAnimating];

	
	//register new user
	NSString* error = nil;
	BOOL succes = [[SensorStore sharedSensorStore].sender registerUser:username.text withPassword:password.text error:&error];
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];
	[activityIndicator release];
	
	//Alert on failure
	if (!succes) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to register" message:error delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		//and login
		[self loginAccount];
	}
}

- (IBAction) loginAccount {
	//show activity indicator
	UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = self.view.center;
	[self.view addSubview:activityIndicator];
	[self.view bringSubviewToFront:activityIndicator];
	[activityIndicator startAnimating];
	
	[[SensorStore sharedSensorStore].sender setUser:username.text andPassword:password.text];
	BOOL succes = [[SensorStore sharedSensorStore].sender login];
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];
	[activityIndicator release];
	
	
	//Alert on failure
	if (!succes) {
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"Couldn't login" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		//save settings
		[[Settings sharedSettings] setLogin:username.text withPassword:password.text];
		//dismiss this view
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end
