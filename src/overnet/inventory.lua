-- One inventory, read-only.
--
-- Reading is cheap and sending is not: list() measured 39ms on a 12,672 slot
-- controller, but the result was ~35KB, which will not cross a modem on a
-- timer. So this hands out a summary (tiny, safe on a timer), a diff (as big
-- as what changed), and the item map only when something asks for it.
local inventory = {}

-- two enchanted books are different items; the nbt hash is all we get
local function key(entry)
  if entry.nbt then return entry.name .. "#" .. entry.nbt end
  return entry.name
end

function inventory.read(name)
  if not peripheral.isPresent(name) then return nil, "no peripheral named " .. name end

  local target = peripheral.wrap(name)
  if not target or not target.list then return nil, name .. " is not an inventory" end

  local started = os.epoch("utc")
  local ok, slots = pcall(target.list)
  if not ok then return nil, tostring(slots) end

  local items, used, total, distinct = {}, 0, 0, 0
  for _, entry in pairs(slots) do
    local k = key(entry)
    if not items[k] then distinct = distinct + 1 end
    items[k] = (items[k] or 0) + entry.count
    used = used + 1
    total = total + entry.count
  end

  local size = used
  local sized, got = pcall(target.size)
  if sized and got then size = got end

  return {
    name = name,
    size = size,
    used = used,
    free = size - used,
    distinct = distinct,
    total = total,
    items = items,
    ms = os.epoch("utc") - started,
  }
end

-- everything except the item map, so it stays under a couple hundred bytes
function inventory.summary(snapshot)
  return {
    name = snapshot.name,
    size = snapshot.size,
    used = snapshot.used,
    free = snapshot.free,
    distinct = snapshot.distinct,
    total = snapshot.total,
    ms = snapshot.ms,
  }
end

-- what moved between two snapshots, keyed the same way, signed
function inventory.diff(before, after)
  local changed, count = {}, 0

  for k, now in pairs(after.items) do
    local was = before.items[k] or 0
    if now ~= was then
      changed[k] = now - was
      count = count + 1
    end
  end

  for k, was in pairs(before.items) do
    if not after.items[k] then
      changed[k] = -was
      count = count + 1
    end
  end

  return changed, count
end

return inventory
