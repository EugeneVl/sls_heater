local function fmt(num)
    return (num > 9 and "" or "0") .. num
end
local function set_state(dev, state, value, msg)
    local new_state = value and "ON" or "OFF"
    local old_state = value and "OFF" or "ON"
    if zigbee.value(dev, state) == old_state then
        zigbee.set(dev, state, new_state)
        if msg then
            telegram.send(fmt((math.modf(os.time() / 3600) + 10) % 24) .. ":" .. fmt(math.modf(os.time() / 60) % 60) .. ". " .. msg)
        end
    end
end

local heater = loadfile("/int/heater_config.lua")()

function heater:set_force_full_power(val)
    set_state(self.switch.addr, self.switch.force_full_power, val)
end
function heater:set_force_boiler_on(val)
    set_state(self.switch.addr, self.switch.force_boiler_on, val)
end
function heater:force_switches_on(val)
    set_state(self.switch.addr, self.switch.force_switches_on, val)
end
function heater:set_full_power(val)
    set_state(self.switch.addr, self.switch.full_power, val)
end
function heater:set_boiler(val)
    local msg = "Отопление " .. (val and "включено" or "выключено") .. " 🌡 " .. self.cur_temp .. "°C"
    set_state(self.switch.addr, self.switch.boiler_on, val, msg)
end

function heater:init()
    self.force_full_power = zigbee.value(self.switch.addr, self.switch.force_full_power) == "ON"
    self.force_boiler_on = zigbee.value(self.switch.addr, self.switch.force_boiler_on) == "ON"
    self.force_switches_on = zigbee.value(self.switch.addr, self.switch.force_switches_on) == "ON"
    self.full_power = zigbee.value(self.switch.addr, self.switch.full_power) == "ON"
    self.boiler_on = zigbee.value(self.switch.addr, self.switch.boiler_on) == "ON"
    self.cur_temp = 99
    local get_switch_power = false -- нужно ли запрашивать мощность у розеток
    for _, room in pairs(self.rooms) do
        room.cur_temp = math.floor(zigbee.value(room.sensor, "temperature") * 10 + 0.5) / 10
        room.cur_hum = math.floor(zigbee.value(room.sensor, "humidity"))
        self.cur_temp = math.min(self.cur_temp, room.cur_temp)
        if room.switch then
            room.switch_on = zigbee.value(room.switch, "state") == "ON"
            if get_switch_power and (room.switch_on or zigbee.value(room.switch, "power") > 0) then
                zigbee.get(room.switch, "power") -- запрос текущей мощности
            end
        end
    end
end

function heater:adjust_heaters()
    local hour = (math.modf(os.time() / 3600) + 10) % 24
    local night_rate = hour >= 23 or hour < 7 -- ночной тариф
    local need_heating = false
    for _, room in pairs(heater.rooms) do
        if hour >= self.night_starts_at or hour < self.day_starts_at then
            room.set_temp = room.set_temp + room.night_temp_offset;
        end
        room.min_temp = room.set_temp - room.hysteresis
        room.max_temp = room.set_temp + room.hysteresis
        room.low_temp = room.cur_temp < (room.min_temp - 1)
        if night_rate and ((not room.switch_only and self.boiler_on) or room.switch_on) then
            -- временно это условие ограничено ночным тарифом
            -- если уже идет нагрев, греем до max_temp
            room.need_heating = room.cur_temp < room.max_temp
        else
            room.need_heating = room.cur_temp < room.min_temp
        end
        if room.switch then
            set_state(room.switch, "state", self.force_switches_on or room.need_heating)
        end
        if not room.switch_only then
            need_heating = need_heating or room.need_heating
            self.force_full_power = self.force_full_power or room.low_temp
        end
    end
    self:set_full_power(self.force_full_power or night_rate)
    self:set_boiler(self.force_boiler_on or need_heating)
end

return heater
