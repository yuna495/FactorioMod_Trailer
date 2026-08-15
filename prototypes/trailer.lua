local trailer = table.deepcopy(data.raw.car.car)

trailer.name = "trailer-cargo"
trailer.localised_name = {"entity-name.trailer-cargo"}
trailer.localised_description = {"entity-description.trailer-cargo"}
trailer.icon = "__base__/graphics/icons/steel-chest.png"
trailer.minable = {mining_time = 0.7, result = "trailer-cargo"}
trailer.collision_box = {{-0.9, -2.8}, {0.9, 2.8}}
trailer.selection_box = {{-1.0, -2.9}, {1.0, 2.9}}
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
trailer.light = nil
trailer.light_animation = nil
trailer.turret_animation = nil
trailer.turret_rotation_speed = nil
trailer.working_sound = nil
trailer.sound_no_fuel = nil
trailer.stop_trigger = nil
trailer.track_particle_triggers = nil

data:extend({trailer})
