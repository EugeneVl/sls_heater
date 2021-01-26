local function fmt(num)
    return (num > 9 and "" or "0") .. num
end
local function set_state(dev, state, val, msg)
    local new_state = val and "ON" or "OFF"
    local old_state = val and "OFF" or "ON"
    if zigbee.value(dev, state) == old_state then
        zigbee.set(dev, state, new_state)
        if msg then
            telegram.send(fmt((math.modf(os.time() / 3600) + 10) % 24) .. ":" .. fmt(math.modf(os.time() / 60) % 60) .. ". " .. msg)
        end
    end
end

local heater = loadfile("/int/heater_config.lua")()

function heater:set_force_full_power(val)
    set_state(self.switch.addr, self.switch.states.force_full_power, val)
end
function heater:set_force_boiler_on(val)
    set_state(self.switch.addr, self.switch.states.force_boiler_on, val)
end
function heater:set_force_switches_on(val)
    set_state(self.switch.addr, self.switch.states.force_switches_on, val)
end
function heater:set_full_power(val)
    set_state(self.switch.addr, self.switch.states.full_power, val)
end
function heater:set_boiler_on(val, temp)
    local msg = "Отопление " .. (val and "включено" or "выключено") .. " 🌡 " .. temp .. "°C"
    set_state(self.switch.addr, self.switch.states.boiler_on, val, msg)
end
function heater:get_switch_state(state)
    return zigbee.value(self.switch.addr, state)
end

function heater:init()
    for name, state in pairs(self.switch.states) do
        self[name] = self:get_switch_state(state) == "ON"
    end
    local get_switch_power = true -- нужно ли запрашивать мощность у розеток
    for _, room in pairs(self.rooms) do
        room.cur_temp = math.floor(zigbee.value(room.sensor, "temperature") * 10 + 0.5) / 10
        room.cur_hum = math.floor(zigbee.value(room.sensor, "humidity"))
        if room.switch then
            room.switch_on = zigbee.value(room.switch, "state") == "ON"
            if get_switch_power and (room.switch_on or zigbee.value(room.switch, "power") > 0) then
                zigbee.get(room.switch, "power")
            end
        end
    end
end

function heater:adjust_heaters()
    local hour = (math.modf(os.time() / 3600) + 10) % 24
    local night_rate = hour >= 23 or hour < 7 -- ночной тариф
    for _, room in pairs(heater.rooms) do
        local min_temp = room.set_temp - room.hysteresis - 1 -- если упадет ниже этой t, включается полная мощность
        if hour >= self.night_starts_at or hour < self.day_starts_at then
            room.set_temp = room.set_temp + room.night_temp_offset
        end
        if night_rate and ((not room.switch_only and self.boiler_on) or room.switch_on) then
            -- ночью, если уже идет нагрев, греем до (set_temp + hysteresis)
            room.set_temp = room.set_temp + room.hysteresis
        else
            -- в остальных случаях греем если ниже (set_temp - hysteresis)
            room.set_temp = room.set_temp - room.hysteresis
        end
        local need_heating = room.cur_temp < room.set_temp
        if room.switch then
            set_state(room.switch, "state", self.force_switches_on or need_heating)
        end
        if not room.switch_only then
            self.force_boiler_on = self.force_boiler_on or need_heating
            self.force_full_power = self.force_full_power or room.cur_temp < min_temp
        end
    end
    self:set_full_power(self.force_full_power or night_rate)
    self:set_boiler_on(self.force_boiler_on, self.rooms.living_room.cur_temp)
end

return heater
