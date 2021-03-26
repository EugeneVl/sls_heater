local function toggle_all(dev)
  channels = {"state_l1", "state_l2", "state_l3", "state_l4", "state_l5", "state_l6", "state_l7", "state_l8"}
  for i = 1, 8 do
    zigbee.set(dev, channels[i], "TOGGLE")
  end
end
