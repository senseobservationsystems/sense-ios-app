//
//  WebViewController.h
//  senseApp
//
//  Created by Pim Nijdam on 2/23/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WebViewController : UIViewController {
	UIWebView* webView;
	UIBarButtonItem* settingsButton;
	UIBarButtonItem* loadHomeButton;
}

-(void) gotoSettings;
- (void) loadHome;
@end
