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
        
    // Initialize interpreter
    LuaInterpreter *interp = [[LuaInterpreter alloc] init];
    
    // Register selectors as globals inside LUA
    [interp registerSelector:@selector(setBackgroundRed) target:self name:@"showred"];
    [interp registerSelector:@selector(showAlert:title:) target:self name:@"showalert" argumentTypes:2, LuaArgumentTypeString, LuaArgumentTypeString];
    [interp registerSelector:@selector(helloString:) target:self name:@"helloString" returnType:LuaArgumentTypeString argumentTypes:1, LuaArgumentTypeString];
    [interp registerSelector:@selector(fdouble:) target:self name:@"fdouble" returnType:LuaArgumentTypeNumber argumentTypes:1,LuaArgumentTypeNumber];
    [interp registerSelector:@selector(fnot:) target:self name:@"fnot" returnType:LuaArgumentTypeBoolean argumentTypes:1, LuaArgumentTypeBoolean];
    [interp registerSelector:@selector(fsplit:) target:self name:@"fsplit" returnType:LuaArgumentTypeMultiple argumentTypes:1, LuaArgumentTypeString];
    [interp registerSelector:@selector(freverse:) target:self name:@"freverse" returnType:LuaArgumentTypeTable argumentTypes:1, LuaArgumentTypeTable];
    
    // Load test file
    [interp load:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"lua"]];
    
    // Run file
    [interp run];
    
    // Call function with 1 expected return value
    NSString *str = [interp call:@"testFunction" expectedReturnCount:1 withArguments:@"FX", nil];
    NSLog(@"Lua testFunction(\"FX\"){1} returned \"%@\"", str);
    
    // Call function with 2
    NSArray *ar = [interp call:@"testFunction" expectedReturnCount:2 withArguments:@"FX", nil];
    NSLog(@"Lua testFunction(\"FX\"){2} returned \"%@\" and \"%@\"", [ar objectAtIndex:0], [ar objectAtIndex:1]);
    
    NSDictionary *dic = [interp call:@"testArray" expectedReturnCount:LuaArgumentTypeTable withArguments:nil];
    NSLog(@"%@", dic);
    
    [interp call:@"testArray2" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:@"FX", @"Thomas", @"John", @"Doe", nil], nil];
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

#pragma mark - Tests functions for LUA

- (void) showAlert:(NSString *)str title:(NSString*)title {
    [[[UIAlertView alloc] initWithTitle:title message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (NSString*) helloString:(NSString *)name {
    return [@"Hello " stringByAppendingString:name];
}

- (double) fdouble:(double)nb {
    return nb*2;
}

- (BOOL) fnot:(BOOL)b {
    return !b;
}

- (NSArray*) fsplit:(NSString *)str {
    return [str componentsSeparatedByString:@" "];
}

- (void) setBackgroundRed {
    self.view.backgroundColor = [UIColor redColor];
}

- (NSDictionary *) freverse:(NSDictionary *)ar {
    NSMutableDictionary *newdic = [NSMutableDictionary dictionary];
    for (NSString *key in ar.allKeys) {
        [newdic setObject:key forKey:[ar objectForKey:key]];
    }
    return newdic;
}

@end
