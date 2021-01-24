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
            switch = "0x842E14FFFE35A1E8",
            switch_only = false,
            set_temp = 15,
            hysteresis = 1,
            night_temp_offset = 5
        },
        garage = {
            name = "Гараж",
            sensor = "0x00158D0001E04E71",
            switch = "0x588E81FFFEDBCFCE",
            switch_only = true,
            set_temp = 0,
            hysteresis = 1,
            night_temp_offset = 2
        },
        boiler_room = {
            name = "Котельная",
            sensor = "0x00158D00045C3041",
            switch = nil,
            switch_only = false,
            set_temp = 6,
            hysteresis = 1,
            night_temp_offset = 0
        }
    },
    day_start = 7,
    night_start = 23
}
return heater
