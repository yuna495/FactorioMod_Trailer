local item_sounds = require("__base__.prototypes.item_sounds")

local RAIL_LOCOMOTIVE_NAME = "trailer-rail-locomotive"
local RAIL_CARGO_WAGON_NAME = "trailer-rail-cargo-wagon"
local RAIL_FLUID_WAGON_NAME = "trailer-rail-fluid-wagon"

local WARRIG_SOUND_PATH = "__Trailer__/sounds/"
local ICON_PATH = "__Trailer__/graphics/icon/"
local MAP_SYMBOL_PATH = "__Trailer__/graphics/map_symbol/"

local function warrig_body_filenames()
  local filenames = {}
  for index = 0, 15 do
    filenames[#filenames + 1] = "__Trailer__/graphics/entity/warrig/warrig_" .. index .. ".png"
  end
  return filenames
end

local function warrig_shadow_filenames()
  local filenames = {}
  for index = 0, 1 do
    filenames[#filenames + 1] = "__Trailer__/graphics/entity/warrig/warrig_shadow_" .. index .. ".png"
  end
  return filenames
end

local function trailer_body_filenames()
  local filenames = {}
  for index = 0, 7 do
    filenames[#filenames + 1] = "__Trailer__/graphics/entity/trailer/warrig_trailer_" .. index .. ".png"
  end
  return filenames
end

local function trailer_shadow_filenames()
  local filenames = {}
  for index = 0, 7 do
    filenames[#filenames + 1] = "__Trailer__/graphics/entity/trailer/warrig_trailer_shadow_" .. index .. ".png"
  end
  return filenames
end

local function warrig_rail_pictures()
  return {
    rotated = {
      layers = {
        {
          width = 962,
          height = 962,
          direction_count = 128,
          allow_low_quality_rotation = false,
          line_length = 1,
          lines_per_file = 8,
          shift = {0, 0.2},
          scale = 0.384,
          filenames = warrig_body_filenames(),
          usage = "train"
        },
        {
          flags = {"shadow"},
          width = 962,
          height = 962,
          direction_count = 128,
          draw_as_shadow = true,
          allow_low_quality_rotation = false,
          line_length = 8,
          lines_per_file = 8,
          shift = {0, 0.2},
          scale = 0.384,
          filenames = warrig_shadow_filenames(),
          usage = "train"
        }
      }
    }
  }
end

local function trailer_rail_pictures()
  return {
    rotated = {
      layers = {
        {
          width = 1258,
          height = 1258,
          direction_count = 128,
          line_length = 4,
          lines_per_file = 4,
          shift = {0, 0},
          scale = 0.384,
          filenames = trailer_body_filenames(),
          usage = "train"
        },
        {
          flags = {"shadow"},
          width = 1258,
          height = 1258,
          direction_count = 128,
          draw_as_shadow = true,
          line_length = 4,
          lines_per_file = 4,
          shift = {0.96, 0.38},
          scale = 0.384,
          filenames = trailer_shadow_filenames(),
          usage = "train"
        }
      }
    }
  }
end

local function rail_minimap(prefix, size, scale)
  return {
    filename = MAP_SYMBOL_PATH .. prefix .. ".png",
    flags = {"icon"},
    size = size,
    scale = scale
  }
end

local function rail_item(name, localised_name, localised_description, icon, order, place_result, sounds)
  return {
    type = "item-with-entity-data",
    name = name,
    localised_name = localised_name,
    localised_description = localised_description,
    icon = icon,
    icon_size = 128,
    subgroup = "train-transport",
    order = order,
    inventory_move_sound = sounds.inventory_move_sound,
    pick_sound = sounds.pick_sound,
    drop_sound = sounds.drop_sound,
    place_result = place_result,
    stack_size = 5
  }
end

local locomotive = table.deepcopy(data.raw.locomotive.locomotive)
locomotive.name = RAIL_LOCOMOTIVE_NAME
locomotive.localised_name = {"entity-name." .. RAIL_LOCOMOTIVE_NAME}
locomotive.localised_description = {"entity-description." .. RAIL_LOCOMOTIVE_NAME}
locomotive.icon = ICON_PATH .. "train.png"
locomotive.icon_size = 128
locomotive.minable = {mining_time = 0.5, result = RAIL_LOCOMOTIVE_NAME}
locomotive.collision_box = {{-1.0, -3.2}, {1.0, 3.2}}
locomotive.selection_box = {{-1.2, -3.6}, {1.2, 3.6}}
locomotive.connection_distance = 3
locomotive.joint_distance = 5
locomotive.weight = 2000
locomotive.max_speed = 1.2
locomotive.max_power = "600kW"
locomotive.braking_force = 10
locomotive.reversing_power_modifier = 0.6
locomotive.friction_force = 0.50
locomotive.air_resistance = 0.0075
locomotive.pictures = warrig_rail_pictures()
locomotive.front_light_pictures = nil
locomotive.minimap_representation = rail_minimap("map_symbol", {128, 128}, 0.2)
locomotive.selected_minimap_representation = rail_minimap("map_symbol_selected", {128, 128}, 0.2)
locomotive.stop_trigger = {
  {
    type = "play-sound",
    sound = {
      {
        filename = WARRIG_SOUND_PATH .. "brakes.ogg",
        volume = 0.6
      }
    }
  }
}
locomotive.working_sound = {
  sound = {
    filename = WARRIG_SOUND_PATH .. "engine.ogg",
    volume = 0.7
  },
  activate_sound = {
    filename = WARRIG_SOUND_PATH .. "engine-start.ogg",
    volume = 0.7
  },
  deactivate_sound = {
    filename = WARRIG_SOUND_PATH .. "engine-stop.ogg",
    volume = 0.5
  },
  match_speed_to_activity = true
}
locomotive.close_sound = {filename = WARRIG_SOUND_PATH .. "door-close.ogg", volume = 0.43}

local cargo_wagon = table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
cargo_wagon.name = RAIL_CARGO_WAGON_NAME
cargo_wagon.localised_name = {"entity-name." .. RAIL_CARGO_WAGON_NAME}
cargo_wagon.localised_description = {"entity-description." .. RAIL_CARGO_WAGON_NAME}
cargo_wagon.icon = ICON_PATH .. "wagon.png"
cargo_wagon.icon_size = 128
cargo_wagon.inventory_size = 100
cargo_wagon.minable = {mining_time = 0.5, result = RAIL_CARGO_WAGON_NAME}
cargo_wagon.collision_box = {{-0.8, -3.4}, {0.8, 3.4}}
cargo_wagon.selection_box = {{-1.1, -3.8}, {1.1, 3.8}}
cargo_wagon.connection_distance = 3
cargo_wagon.joint_distance = 5
cargo_wagon.weight = 1000
cargo_wagon.max_speed = 1.5
cargo_wagon.braking_force = 3
cargo_wagon.friction_force = 0.50
cargo_wagon.air_resistance = 0.01
cargo_wagon.pictures = trailer_rail_pictures()
cargo_wagon.horizontal_doors = nil
cargo_wagon.vertical_doors = nil
cargo_wagon.door_opening_sound = nil
cargo_wagon.door_closing_sound = nil
cargo_wagon.minimap_representation = rail_minimap("wagon_map_symbol", {30, 50}, 0.5)
cargo_wagon.selected_minimap_representation = rail_minimap("wagon_map_symbol_selected", {30, 50}, 0.5)

local fluid_wagon = table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
fluid_wagon.name = RAIL_FLUID_WAGON_NAME
fluid_wagon.localised_name = {"entity-name." .. RAIL_FLUID_WAGON_NAME}
fluid_wagon.localised_description = {"entity-description." .. RAIL_FLUID_WAGON_NAME}
fluid_wagon.icon = ICON_PATH .. "wagon_fluid.png"
fluid_wagon.icon_size = 128
fluid_wagon.capacity = 50000
fluid_wagon.minable = {mining_time = 0.5, result = RAIL_FLUID_WAGON_NAME}
fluid_wagon.collision_box = table.deepcopy(cargo_wagon.collision_box)
fluid_wagon.selection_box = table.deepcopy(cargo_wagon.selection_box)
fluid_wagon.connection_distance = cargo_wagon.connection_distance
fluid_wagon.joint_distance = cargo_wagon.joint_distance
fluid_wagon.weight = cargo_wagon.weight
fluid_wagon.max_speed = cargo_wagon.max_speed
fluid_wagon.braking_force = cargo_wagon.braking_force
fluid_wagon.friction_force = cargo_wagon.friction_force
fluid_wagon.air_resistance = cargo_wagon.air_resistance
fluid_wagon.pictures = trailer_rail_pictures()
fluid_wagon.minimap_representation = table.deepcopy(cargo_wagon.minimap_representation)
fluid_wagon.selected_minimap_representation = table.deepcopy(cargo_wagon.selected_minimap_representation)

data:extend({
  locomotive,
  cargo_wagon,
  fluid_wagon,
  rail_item(
    RAIL_LOCOMOTIVE_NAME,
    {"item-name." .. RAIL_LOCOMOTIVE_NAME},
    {"item-description." .. RAIL_LOCOMOTIVE_NAME},
    ICON_PATH .. "train.png",
    "c[rolling-stock]-d[trailer-rail-locomotive]",
    RAIL_LOCOMOTIVE_NAME,
    {
      inventory_move_sound = item_sounds.locomotive_inventory_move,
      pick_sound = item_sounds.locomotive_inventory_pickup,
      drop_sound = item_sounds.locomotive_inventory_move
    }
  ),
  rail_item(
    RAIL_CARGO_WAGON_NAME,
    {"item-name." .. RAIL_CARGO_WAGON_NAME},
    {"item-description." .. RAIL_CARGO_WAGON_NAME},
    ICON_PATH .. "wagon.png",
    "c[rolling-stock]-e[trailer-rail-cargo-wagon]",
    RAIL_CARGO_WAGON_NAME,
    {
      inventory_move_sound = item_sounds.metal_large_inventory_move,
      pick_sound = item_sounds.locomotive_inventory_pickup,
      drop_sound = item_sounds.metal_large_inventory_move
    }
  ),
  rail_item(
    RAIL_FLUID_WAGON_NAME,
    {"item-name." .. RAIL_FLUID_WAGON_NAME},
    {"item-description." .. RAIL_FLUID_WAGON_NAME},
    ICON_PATH .. "wagon_fluid.png",
    "c[rolling-stock]-f[trailer-rail-fluid-wagon]",
    RAIL_FLUID_WAGON_NAME,
    {
      inventory_move_sound = item_sounds.fluid_inventory_move,
      pick_sound = item_sounds.fluid_inventory_pickup,
      drop_sound = item_sounds.fluid_inventory_move
    }
  ),
  {
    type = "recipe",
    name = RAIL_LOCOMOTIVE_NAME,
    localised_name = {"recipe-name." .. RAIL_LOCOMOTIVE_NAME},
    enabled = true,
    energy_required = 4,
    ingredients = {
      {type = "item", name = "engine-unit", amount = 20},
      {type = "item", name = "electronic-circuit", amount = 10},
      {type = "item", name = "steel-plate", amount = 30}
    },
    results = {{type = "item", name = RAIL_LOCOMOTIVE_NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = RAIL_CARGO_WAGON_NAME,
    localised_name = {"recipe-name." .. RAIL_CARGO_WAGON_NAME},
    enabled = true,
    energy_required = 1,
    ingredients = {
      {type = "item", name = "iron-gear-wheel", amount = 10},
      {type = "item", name = "iron-plate", amount = 20},
      {type = "item", name = "steel-plate", amount = 20}
    },
    results = {{type = "item", name = RAIL_CARGO_WAGON_NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = RAIL_FLUID_WAGON_NAME,
    localised_name = {"recipe-name." .. RAIL_FLUID_WAGON_NAME},
    enabled = true,
    energy_required = 1.5,
    ingredients = {
      {type = "item", name = "iron-gear-wheel", amount = 10},
      {type = "item", name = "steel-plate", amount = 16},
      {type = "item", name = "pipe", amount = 8},
      {type = "item", name = "storage-tank", amount = 1}
    },
    results = {{type = "item", name = RAIL_FLUID_WAGON_NAME, amount = 1}}
  }
})
