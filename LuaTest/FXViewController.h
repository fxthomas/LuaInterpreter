//
//  FXViewController.h
//  LuaTest
//
//  Created by François-Xavier Thomas on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FXViewController : UIViewController

- (void) setBackgroundRed;
- (void) showAlert:(NSString*)str title:(NSString*)title;
- (NSString*) helloString:(NSString*)name;
- (double) fdouble:(double)nb;
- (BOOL) fnot:(BOOL)b;
- (NSArray*) fsplit:(NSString*)str;

@end
