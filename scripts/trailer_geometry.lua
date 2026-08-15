local geometry = {}

geometry.HEAD_COLLISION_BOX = {{-1.0, -3.2}, {1.0, 3.2}}
geometry.HEAD_SELECTION_BOX = {{-1.2, -3.6}, {1.2, 3.6}}

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

geometry.TRAILER_SELECTION_BOX = {{-1.62, -6.24}, {1.62, 6.24}}
geometry.TRAILER_FULL_COLLISION_BOX = {{-1.4, -6.0}, {1.4, 6.0}}
geometry.TRAILER_COLLISION_BOX = geometry.TRAILER_FULL_COLLISION_BOX

return geometry
