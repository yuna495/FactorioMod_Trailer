local geometry = {}

geometry.HEAD_COLLISION_BOX = {{-0.96, -2.15}, {0.96, 2.15}}
geometry.HEAD_SELECTION_BOX = {{-1, -2.35}, {1, 2.35}}

geometry.EMPTY_COLLISION_MASK = {layers = {}}

geometry.LINKED_VEHICLE_COLLISION_MASK = {
  layers = {
    player = true,
    car = true,
    train = true,
    is_object = true
  },
  consider_tile_transitions = true,
  not_colliding_with_itself = true
}

geometry.TRAILER_SELECTION_BOX = {{-1.35, -5.2}, {1.35, 5.2}}
geometry.TRAILER_FULL_COLLISION_BOX = {{-1.17, -5.0}, {1.17, 5.0}}
geometry.TRAILER_COLLISION_BOX = geometry.TRAILER_FULL_COLLISION_BOX

return geometry
