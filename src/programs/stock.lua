-- stock <peripheral> [--watch] [--items [FILE]]
--
-- What is in one inventory. Reads, never moves anything.
package.path = "/?.lua;/?/init.lua;" .. package.path

local util = require("ccs.util")
local inventory = require("overnet.inventory")

local raw = { ... }

local function usage(problem)
  if problem then print(problem) end
  print("usage: stock <peripheral> [--watch] [--items [FILE]]")
end

local name, watch, items, out
local skip = false

for i, value in ipairs(raw) do
  if skip then
    skip = false
  elseif value == "--watch" then
    watch = true
  elseif value == "--items" then
    items = true
    local after = raw[i + 1]
    if after and after:sub(1, 1) ~= "-" then
      out = after
      skip = true
    end
  elseif value:find("--", 1, true) then
    return usage("looks like a glued flag: " .. value)
  elseif name then
    return usage("unexpected argument: " .. value)
  else
    name = value
  end
end

if not name then return usage() end

local snapshot, err = inventory.read(name)
if not snapshot then
  print(err)
  return
end

local function line(snap)
  local s = inventory.summary(snap)
  return ("%s  %d/%d slots  %d keys  %d items  %dms"):format(
    s.name, s.used, s.size, s.distinct, s.total, s.ms)
end

print(line(snapshot))

if items then
  local keys = {}
  for k in pairs(snapshot.items) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return snapshot.items[a] > snapshot.items[b] end)

  if out then
    util.write(out, textutils.serialiseJSON({
      peripheral = name,
      summary = inventory.summary(snapshot),
      items = snapshot.items,
    }))
    print("wrote " .. out)
  else
    for _, k in ipairs(keys) do print(("%7d  %s"):format(snapshot.items[k], k)) end
  end
end

if not watch then return end

print("watching, ctrl+t to stop")

while true do
  sleep(1)

  local now, failed = inventory.read(name)
  if not now then
    print(failed)
    return
  end

  local changed, count = inventory.diff(snapshot, now)
  if count > 0 then
    local keys = {}
    for k in pairs(changed) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do print(("%+d  %s"):format(changed[k], k)) end
    print(line(now))
    snapshot = now
  end
end
