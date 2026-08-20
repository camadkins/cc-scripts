-- cc-scripts installer. Must not require anything it installs.

local OWNER, REPO, BRANCH = "camadkins", "cc-scripts", "main"
local MANIFEST = "/ccs/manifest.json"
local SHIM = "/update.lua"

local unjson = textutils.unserialiseJSON or textutils.unserializeJSON
local bust = 0

local function say(colour, text)
  if term.isColour and term.isColour() then
    local prev = term.getTextColour()
    term.setTextColour(colour)
    print(text)
    term.setTextColour(prev)
  else
    print(text)
  end
end

-- ?cb= defeats the ~5min raw.githubusercontent CDN cache, which otherwise makes
-- a fresh push look like a no-op.
local function fetch(path)
  bust = bust + 1
  local url = ("https://raw.githubusercontent.com/%s/%s/%s/%s?cb=%d.%d")
    :format(OWNER, REPO, BRANCH, path, os.epoch("utc"), bust)

  local handle, err = http.get(url, { ["Cache-Control"] = "no-cache" })
  if not handle then return nil, path .. ": " .. tostring(err) end

  local body = handle.readAll()
  handle.close()
  if not body or #body == 0 then return nil, path .. ": empty" end
  return body
end

local function read(path)
  if not fs.exists(path) then return nil end
  local handle = fs.open(path, "r")
  if not handle then return nil end
  local body = handle.readAll()
  handle.close()
  return body
end

local function write(path, body)
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
  local handle = fs.open(path, "w")
  if not handle then error("cannot write " .. path) end
  handle.write(body)
  handle.close()
end

local function byPath(manifest)
  local out = {}
  if manifest and manifest.files then
    for _, file in ipairs(manifest.files) do out[file.path] = file end
  end
  return out
end

local function diff(remote, installed)
  local new, old = byPath(remote), byPath(installed)
  local add, up, same, gone = {}, {}, 0, {}

  for path, file in pairs(new) do
    local prev = old[path]
    if not prev then add[#add + 1] = file
    elseif prev.sha1 ~= file.sha1 then up[#up + 1] = file
    else same = same + 1 end
  end
  for path in pairs(old) do
    if not new[path] then gone[#gone + 1] = path end
  end

  table.sort(add, function(a, b) return a.path < b.path end)
  table.sort(up, function(a, b) return a.path < b.path end)
  table.sort(gone)
  return add, up, same, gone
end

local function apply(remote, add, up, gone, dry)
  if #add == 0 and #up == 0 and #gone == 0 then
    say(colours.lime, "up to date (" .. tostring(remote.version) .. ")")
    return true
  end

  for _, file in ipairs(add) do print("  + " .. file.path) end
  for _, file in ipairs(up) do print("  ~ " .. file.path) end
  for _, path in ipairs(gone) do print("  - " .. path) end
  if dry then return true end

  -- Download everything before writing anything, so a failed fetch leaves the
  -- old version intact instead of half a release.
  local staged = {}
  for _, file in ipairs(add) do staged[#staged + 1] = file end
  for _, file in ipairs(up) do staged[#staged + 1] = file end

  for i, file in ipairs(staged) do
    local body, err = fetch(file.src)
    if not body then
      say(colours.red, "failed, nothing written: " .. tostring(err))
      return false
    end
    staged[i] = { path = file.path, body = body }
  end

  for _, file in ipairs(staged) do write(file.path, file.body) end
  for _, path in ipairs(gone) do
    if fs.exists(path) then fs.delete(path) end
  end

  write(MANIFEST, textutils.serialiseJSON(remote))
  write(SHIM, 'local args = { ... }\nshell.run("/ccs/installer.lua", "update", table.unpack(args))\n')

  say(colours.lime, ("done: %d added, %d updated, %d removed -> %s")
    :format(#add, #up, #gone, tostring(remote.version)))
  return true
end

local function run(dry)
  local body, err = fetch("manifest.json")
  if not body then
    say(colours.red, "cannot reach manifest: " .. tostring(err))
    return false
  end

  local remote = unjson(body)
  if type(remote) ~= "table" or type(remote.files) ~= "table" then
    say(colours.red, "bad manifest")
    return false
  end

  local installed = unjson(read(MANIFEST) or "null")
  local add, up, same, gone = diff(remote, installed)
  if dry then
    print(("%s, %d files, %d unchanged"):format(tostring(remote.version), #remote.files, same))
  end
  return apply(remote, add, up, gone, dry)
end

local function uninstall()
  local installed = unjson(read(MANIFEST) or "null")
  if not installed then
    print("nothing installed")
    return
  end
  for _, file in ipairs(installed.files) do
    if fs.exists(file.path) then fs.delete(file.path) end
  end
  fs.delete(SHIM)
  fs.delete(MANIFEST)
  say(colours.lime, "uninstalled")
end

local args = { ... }
local mode = args[1] or "install"

for i = 2, #args do
  local flag, value = args[i]:match("^%-%-(%w+)=(.+)$")
  if flag == "branch" then BRANCH = value
  elseif flag == "owner" then OWNER = value
  elseif flag == "repo" then REPO = value end
end

print(("cc-scripts :: %s/%s@%s"):format(OWNER, REPO, BRANCH))

if mode == "install" or mode == "update" then
  if not run(false) then error("cc-scripts: " .. mode .. " failed", 0) end
elseif mode == "check" then
  run(true)
elseif mode == "uninstall" then
  uninstall()
elseif mode == "version" then
  local installed = unjson(read(MANIFEST) or "null")
  print(installed and tostring(installed.version) or "not installed")
else
  print("usage: installer.lua [install|update|check|uninstall|version] [--branch=NAME]")
end
