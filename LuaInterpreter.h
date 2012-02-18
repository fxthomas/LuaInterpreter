//
//  LuaInterpreter.h
//  LuaTest
//
//  Created by François-Xavier Thomas on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Basic LUA argument types, for smooth interaction with ObjC types.
 */
typedef enum {
    LuaArgumentTypeNone,
    LuaArgumentTypeString,
    LuaArgumentTypeNumber,
    LuaArgumentTypeObject
} LuaArgumentType;

/**
 * Lua Interpreter class. Holds the LUA state and releases it when deallocated.
 */
@interface LuaInterpreter : NSObject

/**
 * Loads a LUA source/binary file in memory, specified by `filepath`, without running it.
 */
- (BOOL) load:(NSString*)filepath;

/**
 * Runs the previously loaded LUA file.
 */
- (BOOL) run;

/**
 * Register a selector under a global name, for use inside the LUA program.
 */
- (void) registerSelector:(SEL)selector target:(id)target name:(NSString*)name agumentTypes:(int)count, ...;

@end