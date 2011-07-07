    //
//  WebViewController.m
//  senseApp
//
//  Created by Pim Nijdam on 2/23/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "WebViewController.h"


@implementation WebViewController

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


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];
	//setup navigationbar
	self.navigationItem.title = @"CommonSense";
	//settingsButton = [[[UIBarButtonItem alloc] initWithTitle:@"Sense" style:UIBarButtonItemStylePlain target:self action:@selector(gotoSettings)] retain];
	//self.navigationItem.leftBarButtonItem = settingsButton;
	
	//instantiate button to go to the start page
	//loadHomeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Common sense" style:UIBarButtonItemStylePlain target:self action:@selector(loadHome)] retain];
	//self.navigationItem.rightBarButtonItem = loadHomeButton;
	
	//setup webview
	webView = [[[UIWebView alloc] init] retain];
	webView.userInteractionEnabled = YES;
	webView.multipleTouchEnabled = YES;
	webView.scalesPageToFit = YES;
	webView.autoresizesSubviews = YES;
	
	self.view = webView;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadHome];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

-(void) gotoSettings {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) loadHome {
	NSURL* url = [NSURL URLWithString:@"http://common.sense-os.nl"];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	[webView loadRequest:request];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[settingsButton release];
	[webView release];
    [super dealloc];
}


@end
