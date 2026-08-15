local head = table.deepcopy(data.raw.car.car)

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

head.name = "trailer-head"
head.localised_name = {"entity-name.trailer-head"}
head.localised_description = {"entity-description.trailer-head"}
head.icon = "__base__/graphics/icons/car.png"
head.minable = {mining_time = 0.5, result = "trailer-head"}
head.collision_box = {{-0.96, -2.15}, {0.96, 2.15}}
head.selection_box = {{-1.15, -2.35}, {1.15, 2.35}}
head.weight = 1200
head.inventory_size = 40
head.guns = nil
head.render_layer = "object"
head.animation = {
  layers = {
    {
      priority = "low",
      width = 962,
      height = 962,
      frame_count = 1,
      direction_count = 384,
      scale = 0.24,
      shift = {0, 0},
      stripes = warrig_body_stripes()
    }
  }
}
head.light_animation = nil
head.turret_animation = nil
head.turret_rotation_speed = nil

data:extend({head})
