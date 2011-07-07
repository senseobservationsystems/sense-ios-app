//
//  PickerTable.h
//  senseApp
//
//  Created by Pim Nijdam on 5/11/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^PickerCallback)();
@interface PickerTable : UITableViewController {
	NSArray* options;
	int picked;
	PickerCallback callback;
}

- (id)initWithStyle:(UITableViewStyle)style name:(NSString*) name options:(NSArray*) providedOptions prePicked:(int) prePicked;

@property (copy) NSArray* options;
@property (assign) int picked;
@property (assign) PickerCallback callback;

@end
