local function fmt(num)
    return (num > 9 and "" or "0") .. num
end
local function set_state(dev, state, value, msg)
    if not dev then
        return
    end
    new_state = value and "ON" or "OFF"
    old_state = value and "OFF" or "ON"
    if zigbee.value(dev, state) == old_state then
        zigbee.set(dev, state, new_state)
        if msg then
            telegram.send(fmt((math.modf(os.time() / 3600) + 10) % 24) .. ":" .. fmt(math.modf(os.time() / 60) % 60) .. ". " .. msg)
        end
    end
end

local heater = loadfile("/int/heater_config.lua")()

heater.cur_temp = 99
heater.force_full_power = zigbee.value(heater.switch.addr, heater.switch.force_full_power) == "ON"
heater.force_boiler_on = zigbee.value(heater.switch.addr, heater.switch.force_boiler_on) == "ON"
heater.force_switches_on = zigbee.value(heater.switch.addr, heater.switch.force_switches_on) == "ON"

function heater:set_full_power(val)
    set_state(self.switch.addr, self.switch.full_power, val)
end
function heater:set_boiler(val)
    if val then
        set_state(self.switch.addr, self.switch.boiler_on, true, "Отопление включено 🌡 " .. self.cur_temp .. "°C")
    elseif condition then
        set_state(self.switch.addr, self.switch.boiler_on, true, "Отопление выключено 🌡 " .. self.cur_temp .. "°C")
    end

end
function heater:adjust_heaters()
    local hour = (math.modf(os.time() / 3600) + 10) % 24
    local night_rate = hour >= 23 or hour < 7 -- ночной тариф
    local need_heating = night_rate
    local stop_heating = true
    for _, room in pairs(heater.rooms) do
        room.cur_temp = math.floor(zigbee.value(room.sensor, "temperature") * 10 + 0.5) / 10
        room.low_temp = room.cur_temp < (room.min_temp - 1)
        room.need_heating = room.cur_temp < room.min_temp
        room.stop_heating = room.cur_temp > room.max_temp
        if room.switch then
            -- запрос текущей мощности розетки
            if zigbee.value(room.switch, "state") == "ON" or zigbee.value(room.switch, "power") > 0 then
                zigbee.get(room.switch, "power")
            end
        end
        set_state(room.switch, "state", self.force_switches_on or (not room.stop_heating and (room.need_heating or night_rate))) -- включение розетки в комнате
        self.cur_temp = math.min(self.cur_temp, room.cur_temp)
        need_heating = need_heating or room.need_heating
        stop_heating = stop_heating and room.stop_heating
        self.force_full_power = self.force_full_power or room.low_temp
    end
    self:set_full_power(self.force_full_power or night_rate)
    self:set_boiler(self.force_boiler_on or (not stop_heating and need_heating))
end

return heater
