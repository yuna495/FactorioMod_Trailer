local head = table.deepcopy(data.raw.car.car)

head.name = "trailer-head"
head.localised_name = {"entity-name.trailer-head"}
head.localised_description = {"entity-description.trailer-head"}
head.icon = "__base__/graphics/icons/car.png"
head.minable = {mining_time = 0.5, result = "trailer-head"}
head.collision_box = {{-0.9, -1.4}, {0.9, 1.4}}
head.selection_box = {{-1.0, -1.5}, {1.0, 1.5}}
head.weight = 1200
head.inventory_size = 40
head.guns = nil

data:extend({head})
