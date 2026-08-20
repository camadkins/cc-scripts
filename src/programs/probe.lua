-- probe <peripheral> <method> [args...]
--
-- Calls ONE method you named and shows what comes back. This is the only tool
-- here that calls anything, so it never guesses: no allowlist, no scanning, no
-- "try everything". Typing the method name is the consent.
local args = { ... }
local name, method = args[1], args[2]

if not name or not method then
  print("usage: probe <peripheral> <method> [args...]")
  return
end

if not peripheral.isPresent(name) then
  print("no peripheral named " .. name)
  return
end

local methods = peripheral.getMethods(name) or {}
local known = false
for _, each in ipairs(methods) do
  if each == method then known = true end
end

if not known then
  print(method .. " is not a method of " .. name)
  print("run: inspect " .. name)
  return
end

-- "12" -> 12, "true" -> true, everything else stays a string
local call = {}
for i = 3, #args do
  local value = args[i]
  call[#call + 1] = tonumber(value)
    or (value == "true" and true)
    or (value == "false" and false)
    or value
end

print(("calling %s.%s(%s)"):format(name, method, table.concat(args, ", ", 3)))

local returned = { pcall(peripheral.call, name, method, table.unpack(call)) }
if not returned[1] then
  print("error: " .. tostring(returned[2]))
  return
end

if #returned < 2 then
  print("returned nothing")
  return
end

-- 2^53 is where a Lua double stops counting integers exactly. Mekanism energy
-- values are Java longs and get big enough to matter.
local EXACT = 2 ^ 53

for i = 2, #returned do
  local value = returned[i]
  print(("[%d] %s"):format(i - 1, type(value)))
  print(textutils.serialise(value))

  if type(value) == "number" and math.abs(value) > EXACT then
    print("  !! past 2^53, this number is no longer exact")
  end
end
