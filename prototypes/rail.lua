local item_sounds = require("__base__.prototypes.item_sounds")
local hit_effects = require("__base__/prototypes/entity/hit-effects.lua")
local tile_sounds = require("__base__.prototypes.tile.tile-sounds")

local RAIL_LOCOMOTIVE_NAME = "trailer-rail-locomotive"
local RAIL_CARGO_WAGON_NAME = "trailer-rail-cargo-wagon"
local RAIL_FLUID_WAGON_NAME = "trailer-rail-fluid-wagon"
local ROAD_RAIL_PLANNER_NAME = "trailer-road-rails"
local ROAD_RAIL_STRAIGHT_NAME = "trailer-road-rail-straight"
local ROAD_RAIL_HALF_DIAGONAL_NAME = "trailer-road-rail-half-diagonal"
local ROAD_RAIL_CURVED_A_NAME = "trailer-road-rail-curved-a"
local ROAD_RAIL_CURVED_B_NAME = "trailer-road-rail-curved-b"

local WARRIG_SOUND_PATH = "__Trailer__/sounds/"
local ICON_PATH = "__Trailer__/graphics/icon/"
local MAP_SYMBOL_PATH = "__Trailer__/graphics/map_symbol/"
local RAIL_PATH = "__Trailer__/graphics/entity/rail/"

local ROAD_RAIL_RESISTANCES = {
  {
    type = "fire",
    decrease = 100,
    percent = 100
  },
  {
    type = "acid",
    decrease = 100,
    percent = 100
  }
}

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

local function warrig_exhaust_smoke()
  return {
    {
      name = "trailer-warrig-smoke",
      deviation = {0.25, 0.25},
      frequency = 100,
      height = 1.6,
      position = {-1.2, 1.6},
      starting_frame = 0,
      starting_frame_deviation = 60
    },
    {
      name = "trailer-warrig-smoke",
      deviation = {0.25, 0.25},
      frequency = 100,
      height = 1.6,
      position = {1.2, 1.6},
      starting_frame = 0,
      starting_frame_deviation = 60
    }
  }
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

local function make_rail_sprite(filename, elem, key, variation_count)
  return {
    filename = filename,
    priority = elem.priority or "extra-high",
    flags = elem.mipmap and {"trilinear-filtering"} or {"low-object"},
    draw_as_shadow = elem.draw_as_shadow,
    allow_forced_downscale = elem.allow_forced_downscale,
    width = key[3][1],
    height = key[3][2],
    x = key[2][1],
    y = key[2][2],
    scale = 0.5,
    shift = util.by_pixel(key[4][1], key[4][2]),
    variation_count = variation_count,
    usage = "rail"
  }
end

local function make_road_rail_pictures(keys)
  local result = {}
  local elements = {{"metals", RAIL_PATH .. "roads.png"}}
  for _, key in ipairs(keys) do
    local part = {}
    local variation_count = key[5] or 1
    if variation_count > 0 then
      for _, elem in ipairs(elements) do
        part[elem[1]] = make_rail_sprite(elem[2], elem, key, variation_count)
      end
    end
    result[key[1]] = part
  end

  local empty = util.empty_sprite()
  result.rail_endings = {
    north = empty,
    north_east = empty,
    north_north_east = empty,
    north_north_west = empty,
    north_west = empty,
    east = empty,
    east_north_east = empty,
    east_south_east = empty,
    south = empty,
    south_east = empty,
    south_south_east = empty,
    south_south_west = empty,
    south_west = empty,
    west = empty,
    west_north_west = empty,
    west_south_west = empty
  }
  result.render_layers = {
    metal = "rail-stone-path-lower",
    screw = "rail-screw",
    stone_path = "rail-stone-path",
    stone_path_lower = "rail-stone-path-lower",
    tie = "rail-tie"
  }
  return result
end

local function road_rail_pictures(rail_type)
  local none_position = {0, 0}
  local none_size = {1, 1}
  local none_shift = {0, 0}
  if rail_type == "straight" then
    return make_road_rail_pictures({
      {"north", {0, 384}, {384, 384}, {0, 0}, 1},
      {"northeast", {1536, 384}, {384, 384}, {0, 0}, 1},
      {"east", {0, 0}, {384, 384}, {0, 0}, 1},
      {"southeast", {1536, 0}, {384, 384}, {0, 0}, 1},
      {"south", none_position, none_size, none_shift, 0},
      {"southwest", none_position, none_size, none_shift, 0},
      {"west", none_position, none_size, none_shift, 0},
      {"northwest", none_position, none_size, none_shift, 0}
    })
  elseif rail_type == "half-diagonal" then
    return make_road_rail_pictures({
      {"north", {2304, 0}, {384, 384}, {0, 0}, 1},
      {"northeast", {768, 384}, {384, 384}, {0, 0}, 1},
      {"east", {2304, 384}, {384, 384}, {0, 0}, 1},
      {"southeast", {768, 0}, {384, 384}, {0, 0}, 1},
      {"south", none_position, none_size, none_shift, 0},
      {"southwest", none_position, none_size, none_shift, 0},
      {"west", none_position, none_size, none_shift, 0},
      {"northwest", none_position, none_size, none_shift, 0}
    })
  elseif rail_type == "curved-a" then
    return make_road_rail_pictures({
      {"north", {2688, 0}, {384, 384}, {0, -16}, 1},
      {"northeast", {384, 1152}, {384, 384}, {0, -16}, 1},
      {"east", {2688, 384}, {384, 384}, {16, 0}, 1},
      {"southeast", {384, 0}, {384, 384}, {16, 0}, 1},
      {"south", {2688, 768}, {384, 384}, {0, 16}, 1},
      {"southwest", {384, 384}, {384, 384}, {0, 16}, 1},
      {"west", {2688, 1152}, {384, 384}, {-16, 0}, 1},
      {"northwest", {384, 768}, {384, 384}, {-16, 0}, 1}
    })
  elseif rail_type == "curved-b" then
    return make_road_rail_pictures({
      {"north", {1920, 0}, {384, 384}, {-16, 0}, 1},
      {"northeast", {1152, 1152}, {384, 384}, {16, 0}, 1},
      {"east", {1920, 384}, {384, 384}, {0, -16}, 1},
      {"southeast", {1152, 0}, {384, 384}, {0, 16}, 1},
      {"south", {1920, 768}, {384, 384}, {16, 0}, 1},
      {"southwest", {1152, 384}, {384, 384}, {-16, 0}, 1},
      {"west", {1920, 1152}, {384, 384}, {0, 16}, 1},
      {"northwest", {1152, 768}, {384, 384}, {0, -16}, 1}
    })
  end
end

local function rail_8shifts_vector(dx, dy)
  return {
    {dx, dy},
    {-dx, dy},
    {-dy, dx},
    {-dy, -dx},
    {-dx, -dy},
    {dx, -dy},
    {dy, -dx},
    {dy, dx}
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
locomotive.energy_source.smoke = warrig_exhaust_smoke()
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
locomotive.sound_no_fuel = {filename = WARRIG_SOUND_PATH .. "engine-fail.ogg", volume = 0.5}
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
    enabled = false,
    energy_required = 6,
    ingredients = {
      {type = "item", name = "engine-unit", amount = 30},
      {type = "item", name = "electronic-circuit", amount = 15},
      {type = "item", name = "steel-plate", amount = 45}
    },
    results = {{type = "item", name = RAIL_LOCOMOTIVE_NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = RAIL_CARGO_WAGON_NAME,
    localised_name = {"recipe-name." .. RAIL_CARGO_WAGON_NAME},
    enabled = false,
    energy_required = 1.5,
    ingredients = {
      {type = "item", name = "iron-gear-wheel", amount = 15},
      {type = "item", name = "iron-plate", amount = 30},
      {type = "item", name = "steel-plate", amount = 30}
    },
    results = {{type = "item", name = RAIL_CARGO_WAGON_NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = RAIL_FLUID_WAGON_NAME,
    localised_name = {"recipe-name." .. RAIL_FLUID_WAGON_NAME},
    enabled = false,
    energy_required = 2.25,
    ingredients = {
      {type = "item", name = "iron-gear-wheel", amount = 15},
      {type = "item", name = "steel-plate", amount = 24},
      {type = "item", name = "pipe", amount = 12},
      {type = "item", name = "storage-tank", amount = 2}
    },
    results = {{type = "item", name = RAIL_FLUID_WAGON_NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = ROAD_RAIL_PLANNER_NAME,
    localised_name = {"recipe-name." .. ROAD_RAIL_PLANNER_NAME},
    enabled = false,
    energy_required = 0.5,
    category = "crafting-with-fluid",
    ingredients = {
      {type = "item", name = "stone-brick", amount = 5},
      {type = "item", name = "concrete", amount = 3},
      {type = "fluid", name = "water", amount = 100}
    },
    results = {{type = "item", name = ROAD_RAIL_PLANNER_NAME, amount = 1}}
  },
  {
    type = "rail-planner",
    name = ROAD_RAIL_PLANNER_NAME,
    localised_name = {"item-name." .. ROAD_RAIL_PLANNER_NAME},
    localised_description = {"item-description." .. ROAD_RAIL_PLANNER_NAME},
    icon = RAIL_PATH .. "road.png",
    icon_size = 128,
    subgroup = "train-transport",
    order = "b[rail]-z[trailer-road-rails]",
    place_result = ROAD_RAIL_STRAIGHT_NAME,
    stack_size = 100,
    weight = 10000,
    rails = {
      ROAD_RAIL_STRAIGHT_NAME,
      ROAD_RAIL_HALF_DIAGONAL_NAME,
      ROAD_RAIL_CURVED_A_NAME,
      ROAD_RAIL_CURVED_B_NAME
    }
  },
  {
    type = "straight-rail",
    name = ROAD_RAIL_STRAIGHT_NAME,
    order = "1[trailer-road-rail]-a[straight]",
    icon = RAIL_PATH .. "road.png",
    icon_size = 128,
    hidden = true,
    collision_box = {{-1, -1}, {1, 1}},
    selection_box = {{-1.7, -0.8}, {1.7, 0.8}},
    flags = {"placeable-neutral", "player-creation", "building-direction-8-way"},
    minable = {mining_time = 0.2, result = ROAD_RAIL_PLANNER_NAME, count = 1},
    max_health = 200,
    corpse = "medium-remnants",
    dying_explosion = {name = "rail-explosion"},
    resistances = ROAD_RAIL_RESISTANCES,
    damaged_trigger_effect = hit_effects.wall(),
    pictures = road_rail_pictures("straight"),
    placeable_by = {item = ROAD_RAIL_PLANNER_NAME, count = 1},
    walking_sound = tile_sounds.walking.rails,
    extra_planner_goal_penalty = -4,
    factoriopedia_alternative = ROAD_RAIL_STRAIGHT_NAME
  },
  {
    type = "half-diagonal-rail",
    name = ROAD_RAIL_HALF_DIAGONAL_NAME,
    order = "1[trailer-road-rail]-b[half-diagonal]",
    deconstruction_alternative = ROAD_RAIL_STRAIGHT_NAME,
    icon = RAIL_PATH .. "road.png",
    icon_size = 128,
    hidden = true,
    collision_box = {{-0.75, -2.236}, {0.75, 2.236}},
    selection_box = {{-1.7, -0.8}, {1.7, 0.8}},
    tile_height = 2,
    extra_planner_goal_penalty = -4,
    flags = {"placeable-neutral", "player-creation", "building-direction-8-way"},
    minable = {mining_time = 0.2, result = ROAD_RAIL_PLANNER_NAME, count = 2},
    max_health = 200,
    corpse = "medium-remnants",
    dying_explosion = {
      {name = "rail-explosion", offset = {0.9, 2.2}},
      {name = "rail-explosion"},
      {name = "rail-explosion", offset = {-1.2, -2}}
    },
    resistances = ROAD_RAIL_RESISTANCES,
    damaged_trigger_effect = hit_effects.wall(),
    pictures = road_rail_pictures("half-diagonal"),
    placeable_by = {item = ROAD_RAIL_PLANNER_NAME, count = 2},
    walking_sound = tile_sounds.walking.rails,
    extra_planner_penalty = 0,
    factoriopedia_alternative = ROAD_RAIL_STRAIGHT_NAME
  },
  {
    type = "curved-rail-a",
    name = ROAD_RAIL_CURVED_A_NAME,
    order = "1[trailer-road-rail]-c[curved-a]",
    deconstruction_alternative = ROAD_RAIL_STRAIGHT_NAME,
    icon = RAIL_PATH .. "road.png",
    icon_size = 128,
    hidden = true,
    collision_box = {{-0.75, -2.516}, {0.75, 2.516}},
    selection_box = {{-1.7, -0.8}, {1.7, 0.8}},
    flags = {"placeable-neutral", "player-creation", "building-direction-8-way"},
    minable = {mining_time = 0.2, result = ROAD_RAIL_PLANNER_NAME, count = 3},
    max_health = 200,
    corpse = "medium-remnants",
    dying_explosion = {
      {name = "rail-explosion", offset = {0.9, 2.2}},
      {name = "rail-explosion"},
      {name = "rail-explosion", offset = {-1.2, -2}}
    },
    resistances = ROAD_RAIL_RESISTANCES,
    damaged_trigger_effect = hit_effects.wall(),
    pictures = road_rail_pictures("curved-a"),
    placeable_by = {item = ROAD_RAIL_PLANNER_NAME, count = 3},
    walking_sound = tile_sounds.walking.rails,
    extra_planner_penalty = 0.5,
    deconstruction_marker_positions = rail_8shifts_vector(-0.248, -0.533),
    factoriopedia_alternative = ROAD_RAIL_STRAIGHT_NAME
  },
  {
    type = "curved-rail-b",
    name = ROAD_RAIL_CURVED_B_NAME,
    order = "1[trailer-road-rail]-d[curved-b]",
    deconstruction_alternative = ROAD_RAIL_STRAIGHT_NAME,
    icon = RAIL_PATH .. "road.png",
    icon_size = 128,
    hidden = true,
    collision_box = {{-0.75, -2.441}, {0.75, 2.441}},
    selection_box = {{-1.7, -0.8}, {1.7, 0.8}},
    flags = {"placeable-neutral", "player-creation", "building-direction-8-way"},
    minable = {mining_time = 0.2, result = ROAD_RAIL_PLANNER_NAME, count = 3},
    max_health = 200,
    corpse = "medium-remnants",
    dying_explosion = {
      {name = "rail-explosion", offset = {0.9, 2.2}},
      {name = "rail-explosion"},
      {name = "rail-explosion", offset = {-1.2, -2}}
    },
    resistances = ROAD_RAIL_RESISTANCES,
    damaged_trigger_effect = hit_effects.wall(),
    pictures = road_rail_pictures("curved-b"),
    placeable_by = {item = ROAD_RAIL_PLANNER_NAME, count = 3},
    walking_sound = tile_sounds.walking.rails,
    extra_planner_penalty = 0.5,
    deconstruction_marker_positions = rail_8shifts_vector(-0.309, -0.155),
    factoriopedia_alternative = ROAD_RAIL_STRAIGHT_NAME
  }
})
