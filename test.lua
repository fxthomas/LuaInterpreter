-- test.lua
-- Sample test script, showcasing simple use of registered functions:
--   * showred()
--   * showalert(message, title)
--   * string helloString(string)
--   * number fdouble(number)
--   * boolean not(boolean)
--   * (multiple) fsplit(string)
-- 
-- François-Xavier Thomas <fx.thomas@gmail.com>

-- Test LUA library function
io.write("Crackpot tests running!\n");

-- Test functions using UIKit
showalert(helloString ("FX"), "LUA");
showred();
io.write (" -- Test: UIKit: Should display an alert and turn background red\n");

-- Test functions returning/using strings
if helloString("FX") == "Hello FX" then
  io.write (" -- Test: Strings: OK\n");
else
  io.write (" -- Test: Strings: FAIL (helloString(\"FX\") = " .. helloString("FX") .. ")\n");
end

-- Test functions returning numbers
if fdouble(2) ~= 4 then
  io.write (" -- Test: Numbers: FAIL (fdouble(2) = " .. fdouble(2) .. ")\n");
else
  io.write (" -- Test: Numbers: OK\n");
end

-- Test variable assignment and functions returning booleans
b = fnot(false);
if b and not fnot(true) then
  io.write (" -- Test: Booleans: OK\n");
else
  io.write (" -- Test: Booleans: FAIL\n");
end

-- Test multiple return values
a,b,c = fsplit ("42 is everything");
if a == "42" and b == "is" and c == "everything" then
  io.write (" -- Test: Multiple: OK\n");
else
  io.write (" -- Test: Multiple: FAIL (Values are: " .. a .. "," .. b .. "," .. c .. ")\n")
end

-- Test function
function testFunction (str)
  str1 = "Hello " .. str .. "!"
  str2 = str .. ", how are you today?"
  return str1, str2
end

-- Test table return values
function testArray ()
  ar = {1, 2, {3, 4, },}
  return ar
end
