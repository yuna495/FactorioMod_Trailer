local physics = {}

physics.HEAD_TO_HITCH_DISTANCE = 2.46
physics.TRAILER_AXLE_TO_HITCH_DISTANCE = 8.94
physics.TRAILER_CENTER_TO_HITCH_DISTANCE = 5.52
physics.TRAILER_LATERAL_RESPONSE = 0.95
physics.MAX_HITCH_ANGLE_TURNS = 0.25

local FULL_TURN = math.pi * 2

local function normalize_orientation(orientation)
  return orientation % 1
end

local function shortest_delta_turns(from_orientation, to_orientation)
  return (to_orientation - from_orientation + 0.5) % 1 - 0.5
end

local function orientation_from_vector(vector)
  return normalize_orientation(math.atan2(vector.x, -vector.y) / FULL_TURN)
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

local function trailer_axle_position(center, orientation)
  local forward = vector_from_orientation(orientation)
  local center_to_axle_distance = physics.TRAILER_CENTER_TO_HITCH_DISTANCE - physics.TRAILER_AXLE_TO_HITCH_DISTANCE
  return {
    x = center.x + forward.x * center_to_axle_distance,
    y = center.y + forward.y * center_to_axle_distance
  }
end

physics.trailer_axle_position = trailer_axle_position

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
  local hitch = physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  local trailer_orientation = normalize_orientation(link.trailer_orientation or link.trailer.orientation)
  local accepted_trailer_position = link.accepted_trailer_position or link.trailer.position
  local previous_axle = trailer_axle_position(accepted_trailer_position, trailer_orientation)

  local axle_to_hitch = {
    x = hitch.x - previous_axle.x,
    y = hitch.y - previous_axle.y
  }

  local next_orientation = trailer_orientation
  if axle_to_hitch.x * axle_to_hitch.x + axle_to_hitch.y * axle_to_hitch.y > 0.000001 then
    local no_slip_orientation = orientation_from_vector(axle_to_hitch)
    local angle_delta = shortest_delta_turns(trailer_orientation, no_slip_orientation) * physics.TRAILER_LATERAL_RESPONSE
    next_orientation = normalize_orientation(trailer_orientation + angle_delta)
  end

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
