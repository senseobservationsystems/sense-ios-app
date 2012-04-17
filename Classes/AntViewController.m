//
//  AntViewController.m
//  sensePlatform
//
//  Created by Pim Nijdam on 4/16/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "AntViewController.h"
#import "AntPlusController.h"

@interface AntViewController ()

@end

@implementation AntViewController {
    AntPlusController* antPlus;
}
@synthesize detail;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    antPlus = [[AntPlusController alloc] initWithTextView:detail];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) scan {
    [antPlus scan];
}

- (IBAction) connectBloodPressure {
    [antPlus connectToBloodPressure];
}
- (IBAction) getDirectoryInfo {
    [antPlus getDirectoryInfo];
}
- (IBAction) getFile {
    //nothing
}

@end
