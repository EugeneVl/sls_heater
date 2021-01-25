# sls_heater
local heater = loadfile("/int/heater.lua")()

heater:init()

heater:adjust_heaters()
