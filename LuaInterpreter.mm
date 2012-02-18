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
    LuaArgumentType returnType = (LuaArgumentType)lua_tonumber(L, lua_upvalueindex(4));
    
    // The argument count passed to ObjC by the LUA program is at the top of the stack
    int argCount = lua_gettop(L);
    
    // If it differs from the expected number of arguments, tell the user, but try to perform the selector anyway
    if (argTypes.count != argCount) {
        NSLog(@"LuaInterpreter: Warning: Wrong number of arguments in C closure");
    }
    
    // Converts all LUA types into their respective ObjC values
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
    [inv setSelector:selector];
    [inv setTarget:target];
    for (int i = 0; i < argCount; i++) {
        switch ([[argTypes objectAtIndex:i] intValue]) {
            // String: Convert C String to NSString
            case LuaArgumentTypeString: {
                __unsafe_unretained NSString *str = [NSString stringWithCString:lua_tostring(L, -argCount + i) encoding:NSUTF8StringEncoding];
                [inv setArgument:&str atIndex:2+i];
                break;
            }
            
            // TODO: Implement other data types
            default:
                break;
        }
    }
    
    // Invoke selector
    [inv invoke];
    
    // Clear the stack
    lua_pop(L, argCount);
    
    // Put the returned value on the stack, if any
    switch (returnType) {
        case LuaArgumentTypeString: {
            __unsafe_unretained NSString *ret; [inv getReturnValue:&ret];
            lua_pushstring(L, [ret cStringUsingEncoding:NSUTF8StringEncoding]);
            return 1;
            break;
        }
            
        case LuaArgumentTypeNone:
        default:
            return 0;
            break;
    }
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

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(LuaArgumentType)returnType agumentTypes:(int)count, ... {
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
    lua_pushnumber(state, returnType); // Push return type
    
    // Create a LUA-C closure with these upvalues
    lua_pushcclosure(state, &_runSelector, 4);
    
    // And register it under the provided name
    lua_setglobal(state, [name cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
