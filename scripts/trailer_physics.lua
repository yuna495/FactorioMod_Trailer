local physics = {}

physics.HEAD_TO_HITCH_DISTANCE = 2.05
physics.TRAILER_AXLE_TO_HITCH_DISTANCE = 7.45
physics.TRAILER_CENTER_TO_HITCH_DISTANCE = 4.6
physics.MAX_HITCH_ANGLE_TURNS = 0.25

local FULL_TURN = math.pi * 2

local function normalize_orientation(orientation)
  return orientation % 1
end

local function shortest_delta_turns(from_orientation, to_orientation)
  return (to_orientation - from_orientation + 0.5) % 1 - 0.5
end

local function vector_from_orientation(orientation)
  local radians = orientation * FULL_TURN
  return {
    x = math.sin(radians),
    y = -math.cos(radians)
  }
end

physics.normalize_orientation = normalize_orientation
physics.shortest_delta_turns = shortest_delta_turns
physics.vector_from_orientation = vector_from_orientation

local function perpendicular(vector)
  return {
    x = -vector.y,
    y = vector.x
  }
end

physics.perpendicular = perpendicular

function physics.position_behind(entity, distance)
  local forward = vector_from_orientation(entity.orientation)
  return {
    x = entity.position.x - forward.x * distance,
    y = entity.position.y - forward.y * distance
  }
end

function physics.initial_state(head)
  local hitch = physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  local forward = vector_from_orientation(head.orientation)
  local center = {
    x = hitch.x - forward.x * physics.TRAILER_CENTER_TO_HITCH_DISTANCE,
    y = hitch.y - forward.y * physics.TRAILER_CENTER_TO_HITCH_DISTANCE
  }

  return {
    hitch = hitch,
    trailer_orientation = normalize_orientation(head.orientation),
    trailer_center = center
  }
end

function physics.next_state(link)
  local head = link.head
  local previous_hitch = link.previous_hitch_position or physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  local hitch = physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  local trailer_orientation = normalize_orientation(link.trailer_orientation or link.trailer.orientation)

  local displacement = {
    x = hitch.x - previous_hitch.x,
    y = hitch.y - previous_hitch.y
  }

  local trailer_forward = vector_from_orientation(trailer_orientation)
  local trailer_perpendicular = perpendicular(trailer_forward)
  local lateral_displacement = displacement.x * trailer_perpendicular.x + displacement.y * trailer_perpendicular.y
  local angle_delta = lateral_displacement / physics.TRAILER_AXLE_TO_HITCH_DISTANCE / FULL_TURN
  local next_orientation = normalize_orientation(trailer_orientation + angle_delta)

  local hitch_delta_from_head = shortest_delta_turns(head.orientation, next_orientation)
  if math.abs(hitch_delta_from_head) > physics.MAX_HITCH_ANGLE_TURNS then
    if hitch_delta_from_head > 0 then
      next_orientation = normalize_orientation(head.orientation + physics.MAX_HITCH_ANGLE_TURNS)
    else
      next_orientation = normalize_orientation(head.orientation - physics.MAX_HITCH_ANGLE_TURNS)
    end
  end

  local next_forward = vector_from_orientation(next_orientation)
  local center = {
    x = hitch.x - next_forward.x * physics.TRAILER_CENTER_TO_HITCH_DISTANCE,
    y = hitch.y - next_forward.y * physics.TRAILER_CENTER_TO_HITCH_DISTANCE
  }
  local axle = {
    x = hitch.x - next_forward.x * physics.TRAILER_AXLE_TO_HITCH_DISTANCE,
    y = hitch.y - next_forward.y * physics.TRAILER_AXLE_TO_HITCH_DISTANCE
  }

  return {
    hitch = hitch,
    trailer_orientation = next_orientation,
    trailer_center = center,
    trailer_axle = axle
  }
end

return physics
