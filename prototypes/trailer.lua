local trailer = table.deepcopy(data.raw.car.car)
local proxy = table.deepcopy(data.raw.car.car)
local geometry = require("scripts.trailer_geometry")

local function trailer_body_stripes()
  local stripes = {}
  for index = 0, 7 do
    stripes[#stripes + 1] = {
      filename = "__Trailer__/graphics/entity/trailer/warrig_trailer_" .. index .. ".png",
      width_in_frames = 4,
      height_in_frames = 4
    }
  end
  return stripes
end

local function trailer_shadow_stripes()
  local stripes = {}
  for index = 0, 7 do
    stripes[#stripes + 1] = {
      filename = "__Trailer__/graphics/entity/trailer/warrig_trailer_shadow_" .. index .. ".png",
      width_in_frames = 4,
      height_in_frames = 4
    }
  end
  return stripes
end

trailer.name = "trailer-cargo"
trailer.localised_name = {"entity-name.trailer-cargo"}
trailer.localised_description = {"entity-description.trailer-cargo"}
trailer.icon = "__base__/graphics/icons/steel-chest.png"
trailer.minable = {mining_time = 0.7, result = "trailer-cargo"}
trailer.collision_box = geometry.TRAILER_COLLISION_BOX
trailer.selection_box = geometry.TRAILER_SELECTION_BOX
trailer.collision_mask = geometry.EMPTY_COLLISION_MASK
trailer.energy_source = {type = "void"}
trailer.effectivity = 0.01
trailer.consumption = "1W"
trailer.braking_power = "1W"
trailer.rotation_speed = 0.0001
trailer.rotation_snap_angle = 0
trailer.friction = 1
trailer.weight = 4000
trailer.inventory_size = 80
trailer.guns = nil
trailer.render_layer = "object"
trailer.light = nil
trailer.light_animation = nil
trailer.turret_animation = nil
trailer.turret_rotation_speed = nil
trailer.working_sound = nil
trailer.sound_no_fuel = nil
trailer.stop_trigger = nil
trailer.track_particle_triggers = nil
trailer.animation = {
  layers = {
    {
      priority = "low",
      width = 1258,
      height = 1258,
      frame_count = 1,
      direction_count = 128,
      scale = 0.384,
      shift = {0, 0},
      stripes = trailer_body_stripes()
    },
    {
      priority = "low",
      width = 1258,
      height = 1258,
      frame_count = 1,
      direction_count = 128,
      scale = 0.384,
      shift = {0, 0},
      draw_as_shadow = true,
      stripes = trailer_shadow_stripes()
    }
  }
}

proxy.name = "trailer-cargo-collision-proxy"
proxy.localised_name = {"entity-name.trailer-cargo"}
proxy.localised_description = {"entity-description.trailer-cargo"}
proxy.icon = "__base__/graphics/icons/steel-chest.png"
proxy.flags = {"not-on-map", "not-blueprintable", "not-deconstructable", "hide-alt-info"}
proxy.hidden = true
proxy.selectable_in_game = false
proxy.destructible = false
proxy.minable = nil
proxy.collision_box = geometry.TRAILER_COLLISION_BOX
proxy.selection_box = {{-0.01, -0.01}, {0.01, 0.01}}
proxy.collision_mask = geometry.LINKED_VEHICLE_COLLISION_MASK
proxy.energy_source = {type = "void"}
proxy.effectivity = 0.01
proxy.consumption = "1W"
proxy.braking_power = "1W"
proxy.rotation_speed = 0.0001
proxy.rotation_snap_angle = 0
proxy.friction = 1
proxy.weight = 4000
proxy.inventory_size = 0
proxy.guns = nil
proxy.render_layer = "object"
proxy.light = nil
proxy.light_animation = nil
proxy.turret_animation = nil
proxy.turret_rotation_speed = nil
proxy.working_sound = nil
proxy.sound_no_fuel = nil
proxy.stop_trigger = nil
proxy.track_particle_triggers = nil
proxy.animation = {
  filename = "__core__/graphics/empty.png",
  priority = "low",
  width = 1,
  height = 1,
  frame_count = 1,
  direction_count = 1
}

data:extend({trailer, proxy})
