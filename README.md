LuaInterpreter
==============

You probably noticed that there are not many ready-to-use solutions for application scripting in iOS.
So, I created a very light wrapper for iOS to allow quick LUA integration.

It's certainly not perfect and unfinished, so if there are any bugs or improvements to be made, feel free to leave me a message.

Quick setup for a new project :
-------------------------------

  * Create a new XCode project
  * Create a target called **Lua** for a **Cocoa Touch Static Library**
  * Download LUA source from http://www.lua.org/
  * Unzip the LUA source in the project directory, and add it to the **Lua** target (only this one!)
  * Add the `libLua.a` library to the **main** target, as well as the `LuaInterpreter.h` and `LuaInterpreter.mm` files from this test project
  * Look into `FXViewController.m` in my test project to see some code examples
