local item_sounds = require("__base__.prototypes.item_sounds")

data:extend({
  {
    type = "item",
    name = "trailer-head",
    localised_name = {"item-name.trailer-head"},
    localised_description = {"item-description.trailer-head"},
    icon = "__base__/graphics/icons/car.png",
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
    icon = "__base__/graphics/icons/steel-chest.png",
    subgroup = "transport",
    order = "b[personal-transport]-d[trailer-cargo]",
    inventory_move_sound = item_sounds.vehicle_inventory_move,
    pick_sound = item_sounds.vehicle_inventory_pickup,
    drop_sound = item_sounds.vehicle_inventory_move,
    place_result = "trailer-cargo",
    stack_size = 1,
    hidden = true
  }
})
