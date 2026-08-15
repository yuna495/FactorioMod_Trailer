local physics = {}

physics.HEAD_TO_HITCH_DISTANCE = 2.46
physics.TRAILER_AXLE_TO_HITCH_DISTANCE = 8.94
physics.TRAILER_CENTER_TO_HITCH_DISTANCE = 5.52
physics.TRAILER_CENTER_TO_REAR_HITCH_DISTANCE = 5.52
physics.TRAILER_LATERAL_RESPONSE = 0.95
physics.MAX_HITCH_ANGLE_TURNS = 0.25
physics.STATIONARY_HEAD_SPEED_THRESHOLD = 0.002
physics.STATIONARY_HITCH_MOVEMENT_THRESHOLD = 0.002
physics.TRAILER_ANGLE_DEADZONE_TURNS = 0.0002

local FULL_TURN = math.pi * 2

local function normalize_orientation(orientation)
  return orientation % 1
end

local function shortest_delta_turns(from_orientation, to_orientation)
  return (to_orientation - from_orientation + 0.5) % 1 - 0.5
end

local function distance_squared(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return dx * dx + dy * dy
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

function physics.position_behind_pose(position, orientation, distance)
  local forward = vector_from_orientation(orientation)
  return {
    x = position.x - forward.x * distance,
    y = position.y - forward.y * distance
  }
end

function physics.trailer_rear_hitch_position(center, orientation)
  return physics.position_behind_pose(center, orientation, physics.TRAILER_CENTER_TO_REAR_HITCH_DISTANCE)
end

function physics.initial_state(head)
  local hitch = physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  return physics.initial_state_from_hitch(hitch, head.orientation)
end

function physics.initial_state_from_hitch(hitch, orientation)
  local forward = vector_from_orientation(orientation)
  local center = {
    x = hitch.x - forward.x * physics.TRAILER_CENTER_TO_HITCH_DISTANCE,
    y = hitch.y - forward.y * physics.TRAILER_CENTER_TO_HITCH_DISTANCE
  }

  return {
    hitch = hitch,
    trailer_orientation = normalize_orientation(orientation),
    trailer_center = center
  }
end

function physics.next_segment_state(segment, tow)
  local hitch = tow.hitch
  local tow_orientation = normalize_orientation(tow.orientation)
  local tow_speed = tow.speed or 0
  local trailer_orientation = normalize_orientation(segment.trailer_orientation or segment.trailer.orientation)
  local accepted_trailer_position = segment.accepted_trailer_position or segment.trailer.position
  local accepted_hitch_position = segment.accepted_hitch_position or segment.previous_hitch_position

  if accepted_hitch_position and math.abs(tow_speed) < physics.STATIONARY_HEAD_SPEED_THRESHOLD then
    local hitch_threshold_squared = physics.STATIONARY_HITCH_MOVEMENT_THRESHOLD * physics.STATIONARY_HITCH_MOVEMENT_THRESHOLD
    if distance_squared(hitch, accepted_hitch_position) < hitch_threshold_squared then
      return {
        hitch = hitch,
        trailer_orientation = trailer_orientation,
        trailer_center = {
          x = accepted_trailer_position.x,
          y = accepted_trailer_position.y
        },
        trailer_axle = trailer_axle_position(accepted_trailer_position, trailer_orientation)
      }
    end
  end

  local previous_axle = trailer_axle_position(accepted_trailer_position, trailer_orientation)

  local axle_to_hitch = {
    x = hitch.x - previous_axle.x,
    y = hitch.y - previous_axle.y
  }

  local next_orientation = trailer_orientation
  if axle_to_hitch.x * axle_to_hitch.x + axle_to_hitch.y * axle_to_hitch.y > 0.000001 then
    local no_slip_orientation = orientation_from_vector(axle_to_hitch)
    local angle_delta = shortest_delta_turns(trailer_orientation, no_slip_orientation) * physics.TRAILER_LATERAL_RESPONSE
    if math.abs(angle_delta) >= physics.TRAILER_ANGLE_DEADZONE_TURNS then
      next_orientation = normalize_orientation(trailer_orientation + angle_delta)
    end
  end

  local hitch_delta_from_tow = shortest_delta_turns(tow_orientation, next_orientation)
  if math.abs(hitch_delta_from_tow) > physics.MAX_HITCH_ANGLE_TURNS then
    if hitch_delta_from_tow > 0 then
      next_orientation = normalize_orientation(tow_orientation + physics.MAX_HITCH_ANGLE_TURNS)
    else
      next_orientation = normalize_orientation(tow_orientation - physics.MAX_HITCH_ANGLE_TURNS)
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

function physics.next_state(link)
  return physics.next_segment_state(link, {
    hitch = physics.position_behind(link.head, physics.HEAD_TO_HITCH_DISTANCE),
    orientation = link.head.orientation,
    speed = link.head.speed
  })
end

return physics
