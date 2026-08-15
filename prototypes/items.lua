local item_sounds = require("__base__.prototypes.item_sounds")

local ROAD_ICON = "__War_Rig_Transport__/graphics/icon/icon.png"

data:extend({
  {
    type = "item",
    name = "trailer-head",
    localised_name = {"item-name.trailer-head"},
    localised_description = {"item-description.trailer-head"},
    icon = ROAD_ICON,
    icon_size = 128,
    subgroup = "transport",
    order = "b[personal-transport]-c[trailer-head]",
    inventory_move_sound = item_sounds.vehicle_inventory_move,
    pick_sound = item_sounds.vehicle_inventory_pickup,
    drop_sound = item_sounds.vehicle_inventory_move,
    place_result = "trailer-head",
    stack_size = 1
  },
  {
    type = "item",
    name = "trailer-cargo",
    localised_name = {"item-name.trailer-cargo"},
    localised_description = {"item-description.trailer-cargo"},
    icon = ROAD_ICON,
    icon_size = 128,
    subgroup = "transport",
    order = "b[personal-transport]-d[trailer-cargo]",
    inventory_move_sound = item_sounds.vehicle_inventory_move,
    pick_sound = item_sounds.vehicle_inventory_pickup,
    drop_sound = item_sounds.vehicle_inventory_move,
    place_result = "trailer-cargo",
    stack_size = 1,
    hidden = true
  },
  {
    type = "item",
    name = "double-trailer-head",
    localised_name = {"item-name.double-trailer-head"},
    localised_description = {"item-description.double-trailer-head"},
    icon = ROAD_ICON,
    icon_size = 128,
    subgroup = "transport",
    order = "b[personal-transport]-e[double-trailer-head]",
    inventory_move_sound = item_sounds.vehicle_inventory_move,
    pick_sound = item_sounds.vehicle_inventory_pickup,
    drop_sound = item_sounds.vehicle_inventory_move,
    place_result = "double-trailer-head",
    stack_size = 1
  },
  {
    type = "item",
    name = "triple-trailer-head",
    localised_name = {"item-name.triple-trailer-head"},
    localised_description = {"item-description.triple-trailer-head"},
    icon = ROAD_ICON,
    icon_size = 128,
    subgroup = "transport",
    order = "b[personal-transport]-f[triple-trailer-head]",
    inventory_move_sound = item_sounds.vehicle_inventory_move,
    pick_sound = item_sounds.vehicle_inventory_pickup,
    drop_sound = item_sounds.vehicle_inventory_move,
    place_result = "triple-trailer-head",
    stack_size = 1
  }
})
