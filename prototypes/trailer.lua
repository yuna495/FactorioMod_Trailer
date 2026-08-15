local trailer = table.deepcopy(data.raw.car.car)

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
trailer.collision_box = {{-1.17, -5.0}, {1.17, 5.0}}
trailer.selection_box = {{-1.35, -5.2}, {1.35, 5.2}}
trailer.collision_mask = {layers = {}}
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
trailer.render_layer = "higher-object-above"
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
      scale = 0.32,
      shift = {0, 0},
      stripes = trailer_body_stripes()
    },
    {
      priority = "low",
      width = 1258,
      height = 1258,
      frame_count = 1,
      direction_count = 128,
      scale = 0.32,
      shift = {0, 0},
      draw_as_shadow = true,
      stripes = trailer_shadow_stripes()
    }
  }
}

data:extend({trailer})
