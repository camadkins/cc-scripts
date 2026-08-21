-- probe <peripheral> <method> [args...] [--out FILE]
--
-- Calls ONE method you named and shows what comes back. This is the only tool
-- here that calls anything, so it never guesses: no allowlist, no scanning, no
-- "try everything". Typing the method name is the consent.
package.path = "/?.lua;/?/init.lua;" .. package.path

local util = require("ccs.util")

local raw = { ... }
local args, out = {}, nil

local skip = false
for i, value in ipairs(raw) do
  if skip then
    skip = false
  elseif value == "--out" then
    out = raw[i + 1]
    skip = true
  else
    args[#args + 1] = value
  end
end

local name, method = args[1], args[2]

if not name or not method then
  print("usage: probe <peripheral> <method> [args...] [--out FILE]")
  return
end

if not peripheral.isPresent(name) then
  print("no peripheral named " .. name)
  return
end

local known = false
for _, each in ipairs(peripheral.getMethods(name) or {}) do
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

local started = os.epoch("utc")
local returned = { pcall(peripheral.call, name, method, table.unpack(call)) }
local elapsed = os.epoch("utc") - started

print(elapsed .. "ms")

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

local function describe(value, index)
  print(("[%d] %s"):format(index, type(value)))
  if type(value) == "table" then
    local count = 0
    for _ in pairs(value) do count = count + 1 end
    print("  " .. count .. " entries")
  else
    print("  " .. tostring(value))
  end
  if type(value) == "number" and math.abs(value) > EXACT then
    print("  !! past 2^53, this number is no longer exact")
  end
end

for i = 2, #returned do
  describe(returned[i], i - 1)
end

if not out then
  -- no file asked for: show the whole thing, however big it is
  for i = 2, #returned do print(textutils.serialise(returned[i])) end
  return
end

-- serialiseJSON needs string keys; a slot-indexed table has number keys
local function stringKeys(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, inner in pairs(value) do
    copy[tostring(key)] = stringKeys(inner)
  end
  return copy
end

local results = {}
for i = 2, #returned do
  results[#results + 1] = stringKeys(returned[i])
end

util.write(out, textutils.serialiseJSON({
  peripheral = name,
  method = method,
  args = call,
  elapsed_ms = elapsed,
  returns = results,
}))
print("wrote " .. out)
