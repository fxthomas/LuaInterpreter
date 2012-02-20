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
int lua_pushobject (lua_State *L, id object);
id lua_toobject (lua_State *L, int idx);
NSString *lua_stype (lua_State *L, int idx);
void lua_showstack (lua_State *L);

}

void lua_showstack (lua_State *L) {
    NSLog(@"Stack count : %d", lua_gettop(L));
    for (int i=0; i<lua_gettop(L); i++) NSLog(@"[%d] %@", i, lua_stype(L, -1-i));
}

NSString *lua_stype (lua_State *L, int idx) {
    int _itype = lua_type(L, idx);
    NSString *type = @"";
    
    switch (_itype) {
        case LUA_TNIL:
            type = @"nil";
            break;
            
        case LUA_TSTRING:
            type = @"string";
            break;
            
        case LUA_TTABLE:
            type = @"table";
            break;
            
        case LUA_TTHREAD:
            type = @"thread";
            break;
            
        case LUA_TUSERDATA:
            type = @"userdata";
            break;
            
        case LUA_TLIGHTUSERDATA:
            type = @"lightuserdata";
            break;
            
        case LUA_TNUMBER:
            type = @"number";
            break;
            
        case LUA_TBOOLEAN:
            type = @"boolean";
            break;
            
        case LUA_TFUNCTION:
            type = @"function";
            break;
            
        default:
            type = @"unknown";
            break;
    }
    
    return type;
}

int lua_pushobject (lua_State *L, id object) {
    if ([object isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [(NSString*)object cStringUsingEncoding:NSUTF8StringEncoding]);
    } else if ([object isKindOfClass:[NSNumber class]]) {
        lua_pushnumber(L, [(NSNumber*)object doubleValue]);
    } else {
        NSLog(@"LuaInterpreter: Warning: Unsupported class %@ in `lua_pushobject`", [object class]);
        return 0;
    }
    
    return 1;
}

id lua_toobject (lua_State *L, int idx) {
    if (lua_isnumber(L, idx)) {
        return [NSNumber numberWithDouble:lua_tonumber(L, idx)];
    } else if (lua_isstring(L, idx)) {
        return [NSString stringWithCString:lua_tostring(L, idx) encoding:NSUTF8StringEncoding];
    } else if (lua_isboolean(L, idx)) {
        return [NSNumber numberWithBool:lua_toboolean(L, idx)];
    } else if (lua_istable(L, idx)) {
        // Build table from stack
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        lua_pushvalue(L, idx); /* put the table back on the top of the stack */
        lua_pushnil(L);  /* first key */
        
        // Iterate through table
        while (lua_next(L, -2) != 0) {
            lua_showstack(L);
            /* ‘key’ is at index -2 and ‘value’ at index -1 */
            id obj = lua_toobject(L, -1);
            id key = lua_toobject(L, -2);
            if (obj && key) {
                [dic setObject:obj forKey:key];
            }
            
            lua_pop(L, 1);  /* removes ‘value’; keeps ‘key’ for next iteration */
            lua_showstack(L);
        }
        lua_pop(L, 1);
        lua_showstack(L);
        
        return dic;
    } else {

        NSLog(@"LuaInterpreter: Warning: Unsupported type `%@` in `lua_toobject`", lua_stype(L, idx));
        return nil;
    }
}

int _runSelector (lua_State *L) {
    // Load upvalues from stack
    id target = (__bridge id)lua_touserdata(L, lua_upvalueindex(1)); // Target
    SEL selector = (SEL)lua_touserdata(L, lua_upvalueindex(2)); // Selector to run
    NSArray *argTypes = (__bridge NSArray*)lua_touserdata(L, lua_upvalueindex(3)); // Argument types
    LuaArgumentType returnType = (LuaArgumentType)lua_tonumber(L, lua_upvalueindex(4)); // Return type
    
    // The argument count passed to ObjC by the LUA program is at the top of the stack
    int argCount = lua_gettop(L);
    
    // If it differs from the expected number of arguments, tell the user, but try to perform the selector anyway
    if (argTypes.count != argCount) {
        NSLog(@"LuaInterpreter: Warning: Wrong number of arguments in C closure");
    }
    
    // Prepare method invocation
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
    [inv setSelector:selector];
    [inv setTarget:target];
    
    // Converts all LUA types into their respective ObjC values
    if (argTypes) for (int i = 0; i < argCount; i++) {
        switch ([[argTypes objectAtIndex:i] intValue]) {
            // String: Convert C String to NSString
            case LuaArgumentTypeString: {
                __unsafe_unretained NSString *str = [NSString stringWithCString:lua_tostring(L, -argCount + i) encoding:NSUTF8StringEncoding];
                [inv setArgument:&str atIndex:2+i];
                break;
            }
                
            // Number: All Lua numbers are doubles
            case LuaArgumentTypeNumber: {
                double nb = lua_tonumber(L, -argCount + i);
                [inv setArgument:&nb atIndex:2+i];
                break;
            }
                
            // Boolean: Pretty straightforward now...
            case LuaArgumentTypeBoolean: {
                BOOL b = lua_toboolean(L, -argCount + i);
                [inv setArgument:&b atIndex:2+i];
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
        // String value
        case LuaArgumentTypeString: {
            __unsafe_unretained NSString *ret; [inv getReturnValue:&ret];
            lua_pushstring(L, [ret cStringUsingEncoding:NSUTF8StringEncoding]);
            return 1;
        }
        
        // Number value
        case LuaArgumentTypeNumber: {
            double ret; [inv getReturnValue:&ret];
            lua_pushnumber(L, ret);
            return 1;
        }
            
        // Try to understand an Objective-C object
        case LuaArgumentTypeTryObject: {
            __unsafe_unretained id ret; [inv getReturnValue:&ret];
            return lua_pushobject(L, ret);
        }
        
        // Boolean value
        case LuaArgumentTypeBoolean: {
            BOOL ret; [inv getReturnValue:&ret];
            lua_pushboolean(L, ret);
            return 1;
        }
        
        // Multiple return values need to be stored inside an NSArray
        case LuaArgumentTypeMultiple: {
            __unsafe_unretained id ret; [inv getReturnValue:&ret];
            if ([ret isKindOfClass:[NSArray class]]) {
                for (id obj in ret) lua_pushobject(L, obj);
                return [(NSArray*)ret count];
            } else {
                NSLog(@"LuaInterpreter: Warning: Function registered return type is `multiple`, but the returned object isn't an NSArray");
                return 0;
            }
        }

        case LuaArgumentTypeNone:
        default:
            return 0;
    }
}

@interface LuaInterpreter() {
    lua_State *state; // Holds the current LUA state
    BOOL didRunOnce; // To call a specific function, we need to run the script once to register it
}

- (void) _registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(LuaArgumentType)returnType argumentTypesArray:(NSArray*)argumentTypesArray;

@end

@implementation LuaInterpreter

#pragma mark - Base methods

- (void) dealloc {
    // Close the LUA state
    lua_close(state);
}

- (id) init {
    self = [super init];
    if (self) {
        // Create a new LUA state
        state = luaL_newstate();
        didRunOnce = NO;
        
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

#pragma mark - Running LUA code

- (BOOL) run {
    // Run the program at the top of the stack
    int ret = lua_pcall(state, 0, LUA_MULTRET, 0);
    
    // If the call did not succeed, display the error
    if (ret) {
        NSLog(@"LuaInterpreter: Error: %@", [NSString stringWithCString:lua_tostring(state, -1) encoding:NSUTF8StringEncoding]);
        return NO;
    }
    
    didRunOnce = YES;
    return YES;
}

- (id) call:(NSString *)fname withArguments:(id)args, ... {
    // If we did not run the script once, do it
    if (!didRunOnce) if (![self run]) return nil;
    
    // Try to get the function
    lua_getglobal(state, [fname cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!lua_isfunction(state, -1)) {
        NSLog(@"LuaInterpreter: Error: Tried to run non-existing function `%@`", fname);
        lua_pop(state, 1);
        return nil;
    }
    
    // Push arguments onto the stack
    id value; int argCount = 0;
    if (args) {
        // Push first argument
        argCount += lua_pushobject(state, args);
        
        // Add other arguments if necessary
        va_list arguments;
        va_start(arguments, args);
        while ((value = va_arg(arguments, id))) {
            argCount += lua_pushobject(state, value);
        }
        va_end(arguments);
    }
    
    // Call function
    if (lua_pcall(state, argCount, 0, 0) != 0) {
        NSLog(@"LuaInterpreter: Error: Function `%@`: %@", fname, [NSString stringWithCString:lua_tostring(state, -1) encoding:NSUTF8StringEncoding]);
    }
    return nil;
}

- (id) call:(NSString *)fname expectedReturnCount:(int)count withArguments:(id)args, ... {
    // If we did not run the script once, do it
    if (!didRunOnce) if (![self run]) return nil;
    
    // Try to get the function
    lua_getglobal(state, [fname cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!lua_isfunction(state, -1)) {
        NSLog(@"LuaInterpreter: Error: Tried to run non-existing function `%@`", fname);
        lua_pop(state, 1);
        return nil;
    }
    
    // Push arguments onto the stack
    id value; int argCount = 0;
    if (args) {
        // Push first argument
        argCount += lua_pushobject(state, args);
        
        // Add other arguments if necessary
        va_list arguments;
        va_start(arguments, args);
        while ((value = va_arg(arguments, id))) {
            argCount += lua_pushobject(state, value);
        }
        va_end(arguments);
    }
    
    // Call function
    if (lua_pcall(state, argCount, count, 0) != 0) {
        NSLog(@"LuaInterpreter: Error: Function `%@`: %@", fname, [NSString stringWithCString:lua_tostring(state, -1) encoding:NSUTF8StringEncoding]);
        return nil;
    }
    
    // Get return value
    if (count == 0) return nil;
    else if (count == 1) {
        id obj = lua_toobject(state, -1);
        lua_pop(state, 1);
        return obj;
    } else {
        NSMutableArray *ar = [NSMutableArray arrayWithCapacity:count];
        for (int i = 0; i < count; i++) {
            id obj = lua_toobject(state, -1);
            lua_pop(state, 1);
            if (obj) [ar insertObject:obj atIndex:0];
        }
        
        return ar;
    }
    
    lua_pop(state, lua_gettop(state));
    return nil;
}

#pragma mark - Registering Selectors

- (void) _registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(LuaArgumentType)returnType argumentTypesArray:(NSArray *)argumentTypesArray {
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

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name {
    [self _registerSelector:selector target:target name:name returnType:LuaArgumentTypeNone argumentTypesArray:nil];
}

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name argumentTypes:(int)count, ... {
    // Copy argument types into an array for use with _runSelector
    NSMutableArray *argumentTypesArray = [NSMutableArray array];
    va_list argumentTypes;
    va_start(argumentTypes, count);
    for (int i = 0; i < count; i++) {
        [argumentTypesArray addObject:[NSNumber numberWithInt:va_arg(argumentTypes, LuaArgumentType)]];
    }
    va_end(argumentTypes);
    
    [self _registerSelector:selector target:target name:name returnType:LuaArgumentTypeNone argumentTypesArray:argumentTypesArray];
}

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(LuaArgumentType)returnType {
    [self _registerSelector:selector target:target name:name returnType:returnType argumentTypesArray:nil];
}

- (void) registerSelector:(SEL)selector target:(id)target name:(NSString *)name returnType:(LuaArgumentType)returnType argumentTypes:(int)count, ... {
    // Copy argument types into an array for use with _runSelector
    NSMutableArray *argumentTypesArray = [NSMutableArray array];
    va_list argumentTypes;
    va_start(argumentTypes, count);
    for (int i = 0; i < count; i++) {
        [argumentTypesArray addObject:[NSNumber numberWithInt:va_arg(argumentTypes, LuaArgumentType)]];
    }
    
    [self _registerSelector:selector target:target name:name returnType:returnType argumentTypesArray:argumentTypesArray];
}

@end
