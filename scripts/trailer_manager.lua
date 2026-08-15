local physics = require("scripts.trailer_physics")

local manager = {}

local HEAD_NAME = "trailer-head"
local TRAILER_NAME = "trailer-cargo"
local DEBUG_RENDERING = true

local DEBUG_TIME_TO_LIVE = 2
local DEBUG_LINE_WIDTH = 3
local DEBUG_TEXT_SCALE = 0.8

local HEAD_COLLISION_BOX = {{-0.9, -1.4}, {0.9, 1.4}}
local TRAILER_COLLISION_BOX = {{-0.9, -2.8}, {0.9, 2.8}}

local COLORS = {
  head_box = {1, 0.15, 0.1, 0.85},
  trailer_box = {0.1, 0.45, 1, 0.85},
  head_center = {1, 1, 1, 0.95},
  trailer_center = {1, 1, 1, 0.95},
  hitch = {1, 0.9, 0.05, 0.95},
  axle = {0.1, 1, 0.25, 0.95},
  text = {1, 1, 1, 0.95}
}

local function ensure_storage()
  storage.trailers = storage.trailers or {}
  storage.trailers_by_trailer_unit_number = storage.trailers_by_trailer_unit_number or {}
end

local function is_valid(entity)
  return entity and entity.valid
end

local function remove_link(head_unit_number)
  local link = storage.trailers[head_unit_number]
  if link and is_valid(link.trailer) and link.trailer.name == TRAILER_NAME then
    storage.trailers_by_trailer_unit_number[link.trailer.unit_number] = nil
  end
  storage.trailers[head_unit_number] = nil
end

local function rotate_local_point(center, orientation, local_point)
  local radians = orientation * math.pi * 2
  local sin_angle = math.sin(radians)
  local cos_angle = math.cos(radians)

  return {
    x = center.x + local_point.x * cos_angle - local_point.y * sin_angle,
    y = center.y + local_point.x * sin_angle + local_point.y * cos_angle
  }
end

local function collision_box_corners(center, orientation, box)
  local left_top = box[1]
  local right_bottom = box[2]
  local points = {
    {x = left_top[1], y = left_top[2]},
    {x = right_bottom[1], y = left_top[2]},
    {x = right_bottom[1], y = right_bottom[2]},
    {x = left_top[1], y = right_bottom[2]}
  }

  for index, point in ipairs(points) do
    points[index] = rotate_local_point(center, orientation, point)
  end

  return points
end

local function draw_rotated_box(surface, center, orientation, box, color)
  local corners = collision_box_corners(center, orientation, box)
  for index = 1, 4 do
    rendering.draw_line{
      color = color,
      width = DEBUG_LINE_WIDTH,
      from = corners[index],
      to = corners[index % 4 + 1],
      surface = surface,
      time_to_live = DEBUG_TIME_TO_LIVE
    }
  end
end

local function draw_marker(surface, position, color, radius)
  rendering.draw_circle{
    color = color,
    radius = radius or 0.12,
    filled = true,
    target = position,
    surface = surface,
    time_to_live = DEBUG_TIME_TO_LIVE
  }
end

local function hitch_angle_degrees(head_orientation, trailer_orientation)
  return math.abs(physics.shortest_delta_turns(head_orientation, trailer_orientation)) * 360
end

local function render_debug(link, state)
  if not DEBUG_RENDERING then
    return
  end

  local surface = link.head.surface
  draw_rotated_box(surface, link.head.position, link.head.orientation, HEAD_COLLISION_BOX, COLORS.head_box)
  draw_rotated_box(surface, state.trailer_center, state.trailer_orientation, TRAILER_COLLISION_BOX, COLORS.trailer_box)

  draw_marker(surface, link.head.position, COLORS.head_center, 0.10)
  draw_marker(surface, state.trailer_center, COLORS.trailer_center, 0.10)
  draw_marker(surface, state.hitch, COLORS.hitch, 0.13)
  draw_marker(surface, state.trailer_axle, COLORS.axle, 0.13)

  rendering.draw_text{
    text = string.format("Hitch angle: %.1f deg", hitch_angle_degrees(link.head.orientation, state.trailer_orientation)),
    surface = surface,
    target = {
      x = link.head.position.x,
      y = link.head.position.y - 2.2
    },
    color = COLORS.text,
    scale = DEBUG_TEXT_SCALE,
    alignment = "center",
    time_to_live = DEBUG_TIME_TO_LIVE
  }
end

local function register_link(head, trailer, initial)
  ensure_storage()
  storage.trailers[head.unit_number] = {
    head = head,
    trailer = trailer,
    previous_hitch_position = initial.hitch,
    trailer_orientation = initial.trailer_orientation,
    last_head_position = {x = head.position.x, y = head.position.y},
    last_head_orientation = head.orientation
  }
  storage.trailers_by_trailer_unit_number[trailer.unit_number] = head.unit_number
end

local function create_trailer_for_head(head)
  if not is_valid(head) or not head.unit_number then
    return
  end
  if storage.trailers[head.unit_number] then
    return
  end

  local initial = physics.initial_state(head)
  local surface = head.surface
  local force = head.force
  local can_place = surface.can_place_entity{
    name = TRAILER_NAME,
    position = initial.trailer_center,
    force = force,
    build_check_type = defines.build_check_type.script
  }
  if not can_place then
    return
  end

  local trailer = surface.create_entity{
    name = TRAILER_NAME,
    position = initial.trailer_center,
    force = force,
    create_build_effect_smoke = false,
    raise_built = true
  }
  if not trailer then
    return
  end

  trailer.orientation = initial.trailer_orientation
  trailer.speed = 0
  register_link(head, trailer, initial)
end

function manager.init()
  ensure_storage()
  for head_unit_number, link in pairs(storage.trailers) do
    if not is_valid(link.head) or not is_valid(link.trailer) then
      remove_link(head_unit_number)
    elseif link.trailer.unit_number then
      storage.trailers_by_trailer_unit_number[link.trailer.unit_number] = head_unit_number
    end
  end
end

function manager.on_built_entity(event)
  ensure_storage()
  local entity = event.entity or event.created_entity
  if not is_valid(entity) then
    return
  end

  if entity.name == HEAD_NAME then
    create_trailer_for_head(entity)
  elseif entity.name == TRAILER_NAME then
    entity.speed = 0
  end
end

function manager.on_entity_removed(event)
  ensure_storage()
  local entity = event.entity
  if not entity then
    return
  end

  if entity.name == HEAD_NAME and entity.unit_number then
    local link = storage.trailers[entity.unit_number]
    if link and is_valid(link.trailer) then
      link.trailer.destroy{raise_destroy = true}
    end
    remove_link(entity.unit_number)
  elseif entity.name == TRAILER_NAME and entity.unit_number then
    local head_unit_number = storage.trailers_by_trailer_unit_number[entity.unit_number]
    if head_unit_number then
      remove_link(head_unit_number)
    end
  end
end

function manager.on_player_driving_changed_state(event)
  ensure_storage()
  local player = game.get_player(event.player_index)
  if not player or not player.vehicle then
    return
  end

  local vehicle = player.vehicle
  if vehicle.name == TRAILER_NAME then
    vehicle.set_driver(nil)
    vehicle.speed = 0
    player.print({"message.trailer-cargo-not-drivable"})
  end
end

function manager.on_tick()
  ensure_storage()
  for head_unit_number, link in pairs(storage.trailers) do
    if not is_valid(link.head) or not is_valid(link.trailer) then
      remove_link(head_unit_number)
    elseif link.head.surface ~= link.trailer.surface then
      remove_link(head_unit_number)
    else
      local state = physics.next_state(link)
      local surface = link.head.surface
      if link.trailer.teleport(state.trailer_center, nil, false, false, defines.build_check_type.script) then
        link.trailer.orientation = state.trailer_orientation
        link.trailer.speed = 0
        link.previous_hitch_position = state.hitch
        link.trailer_orientation = state.trailer_orientation
        link.last_head_position = {x = link.head.position.x, y = link.head.position.y}
        link.last_head_orientation = link.head.orientation
        render_debug(link, state)
      else
        link.previous_hitch_position = state.hitch
        link.trailer_orientation = link.trailer.orientation
        link.last_head_position = {x = link.head.position.x, y = link.head.position.y}
        link.last_head_orientation = link.head.orientation
        render_debug(link, state)
      end
    end
  end
end

return manager
