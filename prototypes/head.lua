local head = table.deepcopy(data.raw.car.car)
local geometry = require("scripts.trailer_geometry")

local WARRIG_SOUND_PATH = "__Trailer__/sounds/"
local ICON_PATH = "__Trailer__/graphics/icon/"
local MAP_SYMBOL_PATH = "__Trailer__/graphics/map_symbol/"
local SEMI_HEAD_TUNING = {
  effectivity = 0.7,
  consumption = "2500kW",
  braking_power = "400kW",
  friction = 0.0015,
  rotation_speed = 0.01,
  rotation_snap_angle = 0.015,
  weight = 20000
}
local DOUBLE_HEAD_TUNING = table.deepcopy(SEMI_HEAD_TUNING)
DOUBLE_HEAD_TUNING.weight = 32000
local TRIPLE_HEAD_TUNING = table.deepcopy(SEMI_HEAD_TUNING)
TRIPLE_HEAD_TUNING.weight = 44000

local function warrig_body_stripes()
  local stripes = {}
  for index = 0, 15 do
    stripes[#stripes + 1] = {
      filename = "__Trailer__/graphics/entity/warrig/warrig_" .. index .. ".png",
      width_in_frames = 3,
      height_in_frames = 8
    }
  end
  return stripes
end

local function warrig_working_sound()
  local main_sounds = table.deepcopy(data.raw.car.car.working_sound.main_sounds)
  main_sounds[2].sound = {filename = WARRIG_SOUND_PATH .. "engine.ogg", volume = 0.7}
  main_sounds[2].fade_in_ticks = 90
  main_sounds[2].activity_to_volume_modifiers.multiplier = 1.5
  main_sounds[2].activity_to_volume_modifiers.minimum = 0.5

  return {
    main_sounds = main_sounds,
    activate_sound = {filename = WARRIG_SOUND_PATH .. "engine-start.ogg", volume = 0.7},
    deactivate_sound = {filename = WARRIG_SOUND_PATH .. "engine-stop.ogg", volume = 0.7}
  }
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

local function warrig_minimap(prefix)
  return {
    filename = MAP_SYMBOL_PATH .. prefix .. ".png",
    flags = {"icon"},
    size = {128, 128},
    scale = 0.2
  }
end

local function apply_head_tuning(prototype, tuning)
  prototype.effectivity = tuning.effectivity
  prototype.consumption = tuning.consumption
  prototype.braking_power = tuning.braking_power
  prototype.friction = tuning.friction
  prototype.rotation_speed = tuning.rotation_speed
  prototype.rotation_snap_angle = tuning.rotation_snap_angle
  prototype.weight = tuning.weight
end

head.name = "trailer-head"
head.localised_name = {"entity-name.trailer-head"}
head.localised_description = {"entity-description.trailer-head"}
head.icon = ICON_PATH .. "icon.png"
head.icon_size = 128
head.minable = {mining_time = 0.5, result = "trailer-head"}
head.collision_box = geometry.HEAD_COLLISION_BOX
head.selection_box = geometry.HEAD_SELECTION_BOX
head.collision_mask = geometry.LINKED_VEHICLE_COLLISION_MASK
apply_head_tuning(head, SEMI_HEAD_TUNING)
head.inventory_size = 20
head.guns = nil
head.render_layer = "object"
head.energy_source.smoke = warrig_exhaust_smoke()
head.minimap_representation = warrig_minimap("map_symbol")
head.selected_minimap_representation = warrig_minimap("map_symbol_selected")
head.sound_no_fuel = {filename = WARRIG_SOUND_PATH .. "engine-fail.ogg", volume = 0.5}
head.stop_trigger = {
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
head.working_sound = warrig_working_sound()
head.close_sound = {filename = WARRIG_SOUND_PATH .. "door-close.ogg", volume = 0.43}
head.animation = {
  layers = {
    {
      priority = "low",
      width = 962,
      height = 962,
      frame_count = 1,
      direction_count = 384,
      scale = 0.384,
      shift = {0, 0.2},
      stripes = warrig_body_stripes()
    }
  }
}
head.light_animation = nil
head.turret_animation = nil
head.turret_rotation_speed = nil

local double_head = table.deepcopy(head)
double_head.name = "double-trailer-head"
double_head.localised_name = {"entity-name.double-trailer-head"}
double_head.localised_description = {"entity-description.double-trailer-head"}
double_head.minable = {mining_time = 0.5, result = "double-trailer-head"}
apply_head_tuning(double_head, DOUBLE_HEAD_TUNING)

local triple_head = table.deepcopy(head)
triple_head.name = "triple-trailer-head"
triple_head.localised_name = {"entity-name.triple-trailer-head"}
triple_head.localised_description = {"entity-description.triple-trailer-head"}
triple_head.minable = {mining_time = 0.5, result = "triple-trailer-head"}
apply_head_tuning(triple_head, TRIPLE_HEAD_TUNING)

data:extend({head, double_head, triple_head})
