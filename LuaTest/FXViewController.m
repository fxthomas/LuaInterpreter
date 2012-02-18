//
//  FXViewController.m
//  LuaTest
//
//  Created by François-Xavier Thomas on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FXViewController.h"
#import "LuaInterpreter.h"

@implementation FXViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    LuaInterpreter *interp = [[LuaInterpreter alloc] init];
    [interp registerSelector:@selector(showAlert:title:) target:self name:@"showalert" returnType:LuaArgumentTypeNone agumentTypes:2, LuaArgumentTypeString, LuaArgumentTypeString];
    [interp registerSelector:@selector(helloString:) target:self name:@"helloString" returnType:LuaArgumentTypeString agumentTypes:1, LuaArgumentTypeString];
    [interp load:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"lua"]];
    [interp run];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void) showAlert:(NSString *)str title:(NSString*)title {
    [[[UIAlertView alloc] initWithTitle:title message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (NSString*) helloString:(NSString *)name {
    return [@"Hello " stringByAppendingString:name];
}

@end
