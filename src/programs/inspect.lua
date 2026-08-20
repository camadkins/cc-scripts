-- inspect <peripheral>  -- types and methods for one peripheral. Never calls them.
local name = ({ ... })[1]

if not name then
  print("usage: inspect <peripheral>")
  return
end

if not peripheral.isPresent(name) then
  print("no peripheral named " .. name)
  print("attached: " .. table.concat(peripheral.getNames(), ", "))
  return
end

print(name .. "  [" .. tostring(peripheral.getType(name)) .. "]")

local methods = peripheral.getMethods(name) or {}
table.sort(methods)
for _, method in ipairs(methods) do print("  " .. method) end
print(#methods .. " methods")
