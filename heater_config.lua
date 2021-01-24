local heater = {
    switch = {
        addr = "0x00124B001EC79764",
        force_full_power = "state_l1",
        force_boiler_on = "state_l2",
        force_switches_on = "state_l3",
        full_power = "state_l7",
        boiler_on = "state_l8"
    },
    rooms = {
        living_room = {
            name = "Гостиная",
            sensor = "0x00158D0002D79850",
            switch = "0x842E14FFFE35A1E8", -- nil, если нет
            only_switch = false,
            set_temp = 15,
            hysteresis = 0.5,
            night_temp_offset = 5
        }
    },
    day_start = 7,
    night_start = 23
}
return heater
