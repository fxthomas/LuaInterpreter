//
//  LuaInterpreter.m
//  LuaTest
//
//  Created by François-Xavier Thomas on 2/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LuaInterpreter.h"

extern "C" {
    
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
    
int _runSelector (lua_State *L);

}

int _runSelector (lua_State *L) {
    // Load upvalues from stack
    id target = (__bridge id)lua_touserdata(L, lua_upvalueindex(1)); // Target
    SEL selector = (SEL)lua_touserdata(L, lua_upvalueindex(2)); // Selector to run
    NSArray *argTypes = (__bridge NSArray*)lua_touserdata(L, lua_upvalueindex(3)); // Argument types
    
    // The argument count passed to ObjC by the LUA program is at the top of the stack
    int argCount = lua_gettop(L);
    
    // If it differs from the expected number of arguments, tell the user, but try to perform the selector anyway
    if (argTypes.count != argCount) {
        NSLog(@"LuaInterpreter: Warning: Wrong number of arguments in C closure");
    }
    
    // Converts all LUA types into their respective ObjC values
    NSMutableArray *arguments = [NSMutableArray array];
    for (int i = 0; i < argCount; i++) {
        switch ([[argTypes objectAtIndex:i] intValue]) {
            // String: Convert C String to NSString
            case LuaArgumentTypeString:
                [arguments addObject:[NSString stringWithCString:lua_tostring(L, -argCount + i) encoding:NSUTF8StringEncoding]];
                break;
            
            // TODO: Implement other data types
            default:
                break;
        }
    }
    
    // Perform selector, given the number of expected arguments
    switch (argTypes.count) {
        case 0:
            [target performSelector:selector];
            break;
        case 1:
            [target performSelector:selector withObject:[arguments objectAtIndex:0]];
            break;
        case 2:
            [target performSelector:selector withObject:[arguments objectAtIndex:0] withObject:[arguments objectAtIndex:1]];
            break;
        default:
            break;
    }
    return 0;
}

@interface LuaInterpreter() {
    lua_State *state; // Holds the current LUA state
}
@end

@implementation LuaInterpreter

- (void) dealloc {
    // Close the LUA state
    lua_close(state);
}

- (id) init {
    self = [super init];
    if (self) {
        // Create a new LUA state
        state = luaL_newstate();
        
        // Open all libraries for use within LUA programs
        luaL_openlibs(state);
    }
    return self;
}

- (BOOL) load:(NSString *)filepath {
    // Loads the LUA file
    int ret = luaL_loadfile(state, [filepath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    // If it did not succeed, tell the user
    if (ret) {
        NSLog(@"LuaInterpreter: Error loading file [%@]", filepath);
        return NO;
    }
    return YES;
}

- (BOOL) run {
    // Run the program at the top of the stack
    int ret = lua_pcall(state, 0, LUA_MULTRET, 0);
    
    // If the call did not succeed, display the error
    if (ret) {
        NSLog(@"LuaInterpreter: Error: %@", [NSString stringWithCString:lua_tostring(state, -1) encoding:NSUTF8StringEncoding]);
    }
    return YES;
}

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name agumentTypes:(int)count, ... {
    // Copy argument types into an array for use with _runSelector
    NSMutableArray *argumentTypesArray = [NSMutableArray array];
    va_list argumentTypes;
    va_start(argumentTypes, count);
    for (int i = 0; i < count; i++) {
        [argumentTypesArray addObject:[NSNumber numberWithInt:va_arg(argumentTypes, LuaArgumentType)]];
    }
    va_end(argumentTypes);
    
    // Now push these values onto the LUA stack
    lua_pushlightuserdata(state, (__bridge void*)target); // We need to know the target in order to call the selector
    lua_pushlightuserdata(state, selector); // We need to know the selector
    lua_pushlightuserdata(state, (__bridge void*)argumentTypesArray); // We need to know the argument types to convert them from ObjC values
    
    // Create a LUA-C closure with these upvalues
    lua_pushcclosure(state, &_runSelector, 3);
    
    // And register it under the provided name
    lua_setglobal(state, [name cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
