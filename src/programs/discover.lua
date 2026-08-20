-- Enumerate every attached peripheral. Metadata only, never calls a method.
--   discover              print to terminal
--   discover out.json     also write JSON
package.path = "/?.lua;/?/init.lua;" .. package.path

local util = require("ccs.util")

local out = tostring(({ ... })[1])

local function scan(name)
  local ok, types = pcall(peripheral.getType, name)
  if not ok then return { name = name, error = tostring(types) } end

  local methods = {}
  local gotMethods, list = pcall(peripheral.getMethods, name)
  if gotMethods and list then
    for _, method in ipairs(list) do methods[#methods + 1] = method end
    table.sort(methods)
  end

  return { name = name, types = { types }, methods = methods }
end

local found = {}
for _, name in ipairs(peripheral.getNames()) do
  found[#found + 1] = scan(name)
end
table.sort(found, function(a, b) return a.name < b.name end)

for _, device in ipairs(found) do
  if device.error then
    print(device.name .. "  !! " .. device.error)
  else
    print(("%s  [%s]  %d methods"):format(device.name, table.concat(device.types, ","), #device.methods))
    for _, method in ipairs(device.methods) do print("    " .. method) end
  end
end

print(#found .. " peripherals")

if out ~= "nil" then
  util.write(out, textutils.serialiseJSON({ computer = os.getComputerID(), peripherals = found }))
  print("wrote " .. out)
end
