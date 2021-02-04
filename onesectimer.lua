if (os.time() % 15) > 0 then
    return
end
local command = http.request("http://host/getcmd")
if command == nil or command == "none" then
    return
end
local heater = loadfile("/int/heater.lua")()
heater:init()
if command == "pwr_on" then
    heater:set_force_full_power(true)
elseif command == "pwr_off" then
    heater:set_force_full_power(false)
elseif command == "heat_on" then
    heater:set_force_boiler_on(true)
elseif command == "heat_off" then
    heater:set_force_boiler_on(false)
elseif command == "ws_on" then
    heater:set_force_switches_on(true)
elseif command == "ws_off" then
    heater:set_force_switches_on(false)
elseif command == "status" then
    local cur_temp = heater.rooms.living_room.cur_temp
    local cur_hum = heater.rooms.living_room.cur_hum
    local cur_pwr = heater.full_power and "ON" or "OFF"
    local cur_heat = heater.boiler_on and "ON" or "OFF"
    if heater.force_full_power then
        cur_pwr = "❗" .. cur_pwr .. "❗"
    end
    if heater.force_boiler_on then
        cur_heat = "❗" .. cur_heat .. "❗"
    end
    telegram.send("  🌡 " .. cur_temp .. "°C  💧 " .. cur_hum .. "%  ♨ " .. cur_heat .. "  💪 " .. cur_pwr)
end
