-- installed files live under /, so require needs a leading-slash search path
package.path = "/?.lua;/?/init.lua;" .. package.path

local log = require("ccs.log")
local util = require("ccs.util")
local version = require("ccs.version")

log.info(("cc-scripts %s, %d files"):format(version.version, version.files))

local monitor, name = util.find("monitor")
if monitor then
  log.info("monitor on " .. name)
  monitor.clear()
  monitor.setCursorPos(1, 1)
  monitor.write("cc-scripts " .. version.version)
else
  log.info("no monitor")
end

log.info("up " .. util.duration(os.clock()))
