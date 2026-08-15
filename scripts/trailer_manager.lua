local physics = require("scripts.trailer_physics")
local geometry = require("scripts.trailer_geometry")

local manager = {}

local HEAD_NAME = "trailer-head"
local DOUBLE_HEAD_NAME = "double-trailer-head"
local TRIPLE_HEAD_NAME = "triple-trailer-head"
local TRAILER_NAME = "trailer-cargo"
local TRAILER_PROXY_NAME = "trailer-cargo-collision-proxy"
local TECHNOLOGY_UNLOCKS = {
  ["trailer-head"] = {"trailer-head"},
  ["double-trailer-head"] = {"double-trailer-head"},
  ["triple-trailer-head"] = {"triple-trailer-head"},
  ["trailer-rail-war-rig"] = {
    "trailer-rail-locomotive",
    "trailer-rail-cargo-wagon",
    "trailer-rail-fluid-wagon",
    "trailer-road-rails"
  }
}
local DEBUG_RENDERING = false

local DEBUG_TIME_TO_LIVE = 2
local DEBUG_LINE_WIDTH = 3
local DEBUG_TEXT_SCALE = 0.8
local MAX_PROXY_SUBSTEP_DISTANCE = 0.22
local MAX_PROXY_SUBSTEPS = 64
local PROXY_MAX_HEALTH = 1000000
local PROXY_BUILD_CHECK_TYPE = defines.build_check_type.ghost_revive
local PROXY_BUILD_CHECK_TYPE_NAME = "ghost_revive"
local LINKED_INVENTORIES = {
  defines.inventory.car_trunk,
  defines.inventory.car_ammo,
  defines.inventory.fuel,
  defines.inventory.burnt_result
}

local HEAD_COLLISION_BOX = geometry.HEAD_COLLISION_BOX
local TRAILER_COLLISION_BOX = geometry.TRAILER_COLLISION_BOX
local TRAILER_HALF_DIAGONAL = math.sqrt(
  math.max(math.abs(TRAILER_COLLISION_BOX[1][1]), math.abs(TRAILER_COLLISION_BOX[2][1])) ^ 2 +
  math.max(math.abs(TRAILER_COLLISION_BOX[1][2]), math.abs(TRAILER_COLLISION_BOX[2][2])) ^ 2
)

local COLORS = {
  head_box = {1, 0.15, 0.1, 0.85},
  trailer_box = {0.1, 0.45, 1, 0.85},
  target_box = {1, 0.55, 0.05, 0.85},
  head_center = {1, 1, 1, 0.95},
  trailer_center = {1, 1, 1, 0.95},
  hitch = {1, 0.9, 0.05, 0.95},
  axle = {0.1, 1, 0.25, 0.95},
  text = {1, 1, 1, 0.95}
}

local function ensure_storage()
  storage.trailers = storage.trailers or {}
  storage.trailers_by_trailer_unit_number = storage.trailers_by_trailer_unit_number or {}
  storage.trailers_by_proxy_unit_number = storage.trailers_by_proxy_unit_number or {}
  storage.debug_rendering_cleared = storage.debug_rendering_cleared or false
end

local function is_valid(entity)
  return entity and entity.valid
end

local function is_mined_event(event)
  return event.name == defines.events.on_player_mined_entity or event.name == defines.events.on_robot_mined_entity
end

local function copy_position(position)
  return {x = position.x, y = position.y}
end

local function segment_count_for_head(head_name)
  if head_name == TRIPLE_HEAD_NAME then
    return 3
  end
  if head_name == DOUBLE_HEAD_NAME then
    return 2
  end
  return 1
end

local function variant_for_head(head_name)
  if head_name == TRIPLE_HEAD_NAME then
    return "triple"
  end
  if head_name == DOUBLE_HEAD_NAME then
    return "double"
  end
  return "single"
end

local function is_head_name(name)
  return name == HEAD_NAME or name == DOUBLE_HEAD_NAME or name == TRIPLE_HEAD_NAME
end

local function migrate_link_shape(link)
  if link.trailers then
    link.variant = link.variant or variant_for_head(link.head and link.head.name)
    return
  end

  link.variant = link.variant or "single"
  link.trailers = {
    {
      trailer = link.trailer,
      collision_proxy = link.collision_proxy,
      previous_hitch_position = link.previous_hitch_position,
      trailer_orientation = link.trailer_orientation,
      accepted_hitch_position = link.accepted_hitch_position,
      accepted_trailer_position = link.accepted_trailer_position,
      accepted_trailer_orientation = link.accepted_trailer_orientation
    }
  }

  link.trailer = nil
  link.collision_proxy = nil
  link.previous_hitch_position = nil
  link.trailer_orientation = nil
  link.accepted_hitch_position = nil
  link.accepted_trailer_position = nil
  link.accepted_trailer_orientation = nil
end

local function remove_link(head_unit_number)
  local link = storage.trailers[head_unit_number]
  if link then
    migrate_link_shape(link)
    for _, segment in pairs(link.trailers) do
      if is_valid(segment.trailer) and segment.trailer.name == TRAILER_NAME then
        storage.trailers_by_trailer_unit_number[segment.trailer.unit_number] = nil
      end
      if is_valid(segment.collision_proxy) and segment.collision_proxy.name == TRAILER_PROXY_NAME then
        storage.trailers_by_proxy_unit_number[segment.collision_proxy.unit_number] = nil
      end
    end
  end
  storage.trailers[head_unit_number] = nil
end

local function transfer_inventory_to_buffer(entity, buffer)
  if not is_valid(entity) or not buffer then
    return
  end

  for _, inventory_index in ipairs(LINKED_INVENTORIES) do
    local ok, inventory = pcall(function()
      return entity.get_inventory(inventory_index)
    end)
    if ok and inventory and inventory.valid then
      for slot_index = 1, #inventory do
        local stack = inventory[slot_index]
        if stack and stack.valid_for_read then
          buffer.insert(stack)
          stack.clear()
        end
      end
    end
  end
end

local function remove_hidden_trailer_item_from_buffer(buffer)
  if buffer then
    buffer.remove{name = TRAILER_NAME, count = 1}
  end
end

local function return_head_item_to_buffer(link, mined_entity, buffer)
  if not buffer or not is_valid(link.head) then
    return
  end
  if mined_entity == link.head then
    return
  end
  buffer.insert{name = link.head.name, count = 1}
end

local function destroy_link_entities(link, except_entity, return_to_buffer)
  migrate_link_shape(link)
  local buffer = return_to_buffer

  if buffer and is_valid(link.head) and link.head ~= except_entity then
    transfer_inventory_to_buffer(link.head, buffer)
  end
  if is_valid(link.head) and link.head ~= except_entity then
    link.head.destroy{raise_destroy = false}
  end

  for _, segment in pairs(link.trailers) do
    if buffer and is_valid(segment.trailer) and segment.trailer ~= except_entity then
      transfer_inventory_to_buffer(segment.trailer, buffer)
    end
    if is_valid(segment.trailer) and segment.trailer ~= except_entity then
      segment.trailer.destroy{raise_destroy = false}
    end
    if is_valid(segment.collision_proxy) and segment.collision_proxy ~= except_entity then
      segment.collision_proxy.destroy{raise_destroy = false}
    end
  end
end

local function remove_whole_link_for_entity(entity, link, head_unit_number, buffer)
  remove_link(head_unit_number)

  if buffer then
    remove_hidden_trailer_item_from_buffer(buffer)
    return_head_item_to_buffer(link, entity, buffer)
  end

  destroy_link_entities(link, entity, buffer)
end

local function restore_proxy_health(proxy)
  if is_valid(proxy) then
    proxy.health = PROXY_MAX_HEALTH
  end
end

local function apply_proxy_damage_to_trailer(proxy, damage_amount)
  if not is_valid(proxy) or proxy.name ~= TRAILER_PROXY_NAME or not proxy.unit_number then
    return
  end
  if not damage_amount or damage_amount <= 0 then
    restore_proxy_health(proxy)
    return
  end

  local head_unit_number = storage.trailers_by_proxy_unit_number[proxy.unit_number]
  if not head_unit_number then
    restore_proxy_health(proxy)
    return
  end

  local link = storage.trailers[head_unit_number]
  if not link then
    restore_proxy_health(proxy)
    remove_link(head_unit_number)
    return
  end

  migrate_link_shape(link)
  for _, segment in ipairs(link.trailers) do
    if segment.collision_proxy == proxy then
      local trailer = segment.trailer
      if not is_valid(trailer) then
        remove_whole_link_for_entity(proxy, link, head_unit_number, nil)
        return
      end

      local current_health = trailer.health or 1
      local remaining_health = current_health - damage_amount
      if remaining_health <= 0 then
        trailer.health = 0
        remove_whole_link_for_entity(nil, link, head_unit_number, nil)
      else
        trailer.health = remaining_health
        restore_proxy_health(proxy)
      end
      return
    end
  end

  restore_proxy_health(proxy)
end

local function clear_debug_rendering()
  if storage.debug_rendering_cleared then
    return
  end

  pcall(function()
    rendering.clear(script.mod_name)
  end)
  storage.debug_rendering_cleared = true
end

local function sync_debug_rendering_state()
  if DEBUG_RENDERING then
    storage.debug_rendering_cleared = false
  else
    clear_debug_rendering()
  end
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

local function hitch_angle_degrees(tow_orientation, trailer_orientation)
  return math.abs(physics.shortest_delta_turns(tow_orientation, trailer_orientation)) * 360
end

local function orientation_to_direction(orientation)
  return math.floor((orientation % 1) * 16 + 0.5) % 16
end

local function interpolate_orientation(from_orientation, to_orientation, ratio)
  return (from_orientation + physics.shortest_delta_turns(from_orientation, to_orientation) * ratio) % 1
end

local function substep_count(from_position, from_orientation, to_position, to_orientation)
  local dx = to_position.x - from_position.x
  local dy = to_position.y - from_position.y
  local distance = math.sqrt(dx * dx + dy * dy)
  local angular_distance = math.abs(physics.shortest_delta_turns(from_orientation, to_orientation)) * math.pi * 2 * TRAILER_HALF_DIAGONAL
  local steps = math.ceil(math.max(distance, angular_distance) / MAX_PROXY_SUBSTEP_DISTANCE)
  if steps < 1 then
    return 1
  end
  return math.min(steps, MAX_PROXY_SUBSTEPS)
end

local function render_debug(link, states, blocked)
  if not DEBUG_RENDERING then
    return
  end

  local surface = link.head.surface
  draw_rotated_box(surface, link.head.position, link.head.orientation, HEAD_COLLISION_BOX, COLORS.head_box)
  draw_marker(surface, link.head.position, COLORS.head_center, 0.10)

  local tow_orientation = link.head.orientation
  for index, segment in ipairs(link.trailers) do
    local state = states[index]
    local accepted_center = segment.trailer.position
    local accepted_orientation = segment.trailer.orientation
    if is_valid(segment.collision_proxy) then
      accepted_center = segment.collision_proxy.position
      accepted_orientation = segment.collision_proxy.orientation
    end

    draw_rotated_box(surface, accepted_center, accepted_orientation, TRAILER_COLLISION_BOX, COLORS.trailer_box)
    if blocked and state then
      draw_rotated_box(surface, state.trailer_center, state.trailer_orientation, TRAILER_COLLISION_BOX, COLORS.target_box)
    end

    draw_marker(surface, accepted_center, COLORS.trailer_center, 0.10)
    if state then
      draw_marker(surface, state.hitch, COLORS.hitch, 0.13)
      draw_marker(surface, state.trailer_axle, COLORS.axle, 0.13)
      rendering.draw_text{
        text = string.format("%s hitch: %.1f deg", index == 1 and "A" or "B", hitch_angle_degrees(tow_orientation, state.trailer_orientation)),
        surface = surface,
        target = {
          x = accepted_center.x,
          y = accepted_center.y - 2.2
        },
        color = COLORS.text,
        scale = DEBUG_TEXT_SCALE,
        alignment = "center",
        time_to_live = DEBUG_TIME_TO_LIVE
      }
      tow_orientation = state.trailer_orientation
    end
  end
end

local function render_blocked_debug(link, state)
  if not DEBUG_RENDERING or not state then
    return
  end

  rendering.draw_text{
    text = {"message.trailer-blocked"},
    surface = link.head.surface,
    target = {
      x = state.trailer_center.x,
      y = state.trailer_center.y - 1.8
    },
    color = {1, 0.2, 0.1, 0.95},
    scale = DEBUG_TEXT_SCALE,
    alignment = "center",
    time_to_live = 60
  }
end

local function render_blocked_diagnostic(link, state, diagnostic)
  if not DEBUG_RENDERING or not diagnostic or not state then
    return
  end

  rendering.draw_text{
    text = string.format(
      "segment %d  substep %d/%d  check:%s  can_place:%s  teleport:%s",
      diagnostic.segment_index or 0,
      diagnostic.failed_step or 0,
      diagnostic.steps or 0,
      diagnostic.check_type or PROXY_BUILD_CHECK_TYPE_NAME,
      tostring(diagnostic.can_place),
      tostring(diagnostic.teleport)
    ),
    surface = link.head.surface,
    target = {
      x = state.trailer_center.x,
      y = state.trailer_center.y - 1.25
    },
    color = {1, 0.75, 0.15, 0.95},
    scale = 0.65,
    alignment = "center",
    time_to_live = 90
  }
end

local function create_collision_proxy(surface, force, position, orientation)
  local proxy = surface.create_entity{
    name = TRAILER_PROXY_NAME,
    position = position,
    force = force,
    create_build_effect_smoke = false,
    raise_built = false
  }
  if not proxy then
    return nil
  end

  proxy.orientation = orientation
  proxy.speed = 0
  return proxy
end

local function move_proxy_substepped(segment, target_position, target_orientation)
  local proxy = segment.collision_proxy
  local surface = proxy.surface
  local force = proxy.force
  local start_position = copy_position(segment.accepted_trailer_position or proxy.position)
  local start_orientation = segment.accepted_trailer_orientation or proxy.orientation
  local steps = substep_count(start_position, start_orientation, target_position, target_orientation)

  proxy.orientation = start_orientation
  proxy.teleport(start_position, nil, false, false)
  proxy.speed = 0

  for step = 1, steps do
    local ratio = step / steps
    local step_position = {
      x = start_position.x + (target_position.x - start_position.x) * ratio,
      y = start_position.y + (target_position.y - start_position.y) * ratio
    }
    local step_orientation = interpolate_orientation(start_orientation, target_orientation, ratio)
    local step_direction = orientation_to_direction(step_orientation)
    local can_place = surface.can_place_entity{
      name = TRAILER_PROXY_NAME,
      position = step_position,
      direction = step_direction,
      force = force,
      build_check_type = PROXY_BUILD_CHECK_TYPE
    }

    proxy.orientation = step_orientation
    local teleport_result = proxy.teleport(step_position, nil, false, false, PROXY_BUILD_CHECK_TYPE)

    if not teleport_result then
      proxy.orientation = start_orientation
      proxy.teleport(start_position, nil, false, false)
      proxy.speed = 0
      return false, {
        steps = steps,
        failed_step = step,
        check_type = PROXY_BUILD_CHECK_TYPE_NAME,
        can_place = can_place,
        teleport = teleport_result
      }
    end
    proxy.speed = 0
  end

  proxy.orientation = target_orientation
  proxy.speed = 0
  return true, {
    steps = steps,
    failed_step = steps,
    check_type = PROXY_BUILD_CHECK_TYPE_NAME,
    can_place = true,
    teleport = true
  }
end

local function can_place_collision_proxy(surface, force, position, orientation)
  return surface.can_place_entity{
    name = TRAILER_PROXY_NAME,
    position = position,
    direction = orientation_to_direction(orientation or 0),
    force = force,
    build_check_type = PROXY_BUILD_CHECK_TYPE
  }
end

local function segment_fallback_hitch(link, index)
  if index == 1 then
    return physics.position_behind(link.head, physics.HEAD_TO_HITCH_DISTANCE)
  end

  local previous = link.trailers[index - 1]
  if previous then
    local position = previous.accepted_trailer_position or previous.trailer.position
    local orientation = previous.accepted_trailer_orientation or previous.trailer_orientation or previous.trailer.orientation
    return physics.trailer_rear_hitch_position(position, orientation)
  end

  return physics.position_behind(link.head, physics.HEAD_TO_HITCH_DISTANCE)
end

local function ensure_accepted_state(link)
  link.accepted_head_position = link.accepted_head_position or copy_position(link.head.position)
  link.accepted_head_orientation = link.accepted_head_orientation or link.head.orientation

  for index, segment in ipairs(link.trailers) do
    segment.accepted_hitch_position = segment.accepted_hitch_position or segment.previous_hitch_position or segment_fallback_hitch(link, index)
    segment.accepted_trailer_position = segment.accepted_trailer_position or copy_position(segment.trailer.position)
    segment.accepted_trailer_orientation = segment.accepted_trailer_orientation or segment.trailer_orientation or segment.trailer.orientation

    segment.previous_hitch_position = segment.accepted_hitch_position
    segment.trailer_orientation = segment.accepted_trailer_orientation
  end
end

local function accept_state(link, states)
  link.accepted_head_position = copy_position(link.head.position)
  link.accepted_head_orientation = link.head.orientation

  for index, segment in ipairs(link.trailers) do
    local state = states[index]
    segment.accepted_hitch_position = copy_position(state.hitch)
    segment.accepted_trailer_position = copy_position(segment.collision_proxy.position)
    segment.accepted_trailer_orientation = state.trailer_orientation

    segment.previous_hitch_position = segment.accepted_hitch_position
    segment.trailer_orientation = segment.accepted_trailer_orientation
  end
end

local function restore_accepted_state(link)
  ensure_accepted_state(link)

  link.head.teleport(link.accepted_head_position, nil, false, false)
  link.head.orientation = link.accepted_head_orientation
  link.head.speed = 0

  for _, segment in ipairs(link.trailers) do
    if is_valid(segment.collision_proxy) then
      segment.collision_proxy.orientation = segment.accepted_trailer_orientation
      segment.collision_proxy.teleport(segment.accepted_trailer_position, nil, false, false)
      segment.collision_proxy.speed = 0
    end

    segment.trailer.teleport(segment.accepted_trailer_position, nil, false, false)
    segment.trailer.orientation = segment.accepted_trailer_orientation
    segment.trailer.speed = 0

    segment.previous_hitch_position = segment.accepted_hitch_position
    segment.trailer_orientation = segment.accepted_trailer_orientation
  end
end

local function register_link(head, segments, variant)
  ensure_storage()
  storage.trailers[head.unit_number] = {
    variant = variant,
    head = head,
    trailers = segments,
    accepted_head_position = copy_position(head.position),
    accepted_head_orientation = head.orientation
  }

  for _, segment in ipairs(segments) do
    storage.trailers_by_trailer_unit_number[segment.trailer.unit_number] = head.unit_number
    storage.trailers_by_proxy_unit_number[segment.collision_proxy.unit_number] = head.unit_number
  end
end

local function ensure_collision_proxy(head_unit_number, link, segment)
  if is_valid(segment.collision_proxy) then
    storage.trailers_by_proxy_unit_number[segment.collision_proxy.unit_number] = head_unit_number
    return true
  end

  if not can_place_collision_proxy(segment.trailer.surface, segment.trailer.force, segment.trailer.position, segment.trailer.orientation) then
    return false
  end

  local proxy = create_collision_proxy(segment.trailer.surface, segment.trailer.force, segment.trailer.position, segment.trailer.orientation)
  if not proxy then
    return false
  end

  segment.collision_proxy = proxy
  storage.trailers_by_proxy_unit_number[proxy.unit_number] = head_unit_number
  ensure_accepted_state(link)
  return true
end

local function create_visible_trailer(surface, force, position, orientation)
  local trailer = surface.create_entity{
    name = TRAILER_NAME,
    position = position,
    force = force,
    create_build_effect_smoke = false,
    raise_built = true
  }
  if not trailer then
    return nil
  end

  trailer.orientation = orientation
  trailer.speed = 0
  return trailer
end

local function create_segment(surface, force, initial)
  if not can_place_collision_proxy(surface, force, initial.trailer_center, initial.trailer_orientation) then
    return nil
  end

  local trailer = create_visible_trailer(surface, force, initial.trailer_center, initial.trailer_orientation)
  if not trailer then
    return nil
  end

  local collision_proxy = create_collision_proxy(surface, force, initial.trailer_center, initial.trailer_orientation)
  if not collision_proxy then
    trailer.destroy{raise_destroy = false}
    return nil
  end

  return {
    trailer = trailer,
    collision_proxy = collision_proxy,
    previous_hitch_position = copy_position(initial.hitch),
    trailer_orientation = initial.trailer_orientation,
    accepted_hitch_position = copy_position(initial.hitch),
    accepted_trailer_position = copy_position(initial.trailer_center),
    accepted_trailer_orientation = initial.trailer_orientation
  }
end

local function create_trailers_for_head(head)
  if not is_valid(head) or not head.unit_number then
    return
  end
  if storage.trailers[head.unit_number] then
    return
  end

  local surface = head.surface
  local force = head.force
  local segment_count = segment_count_for_head(head.name)
  local segments = {}
  local hitch = physics.position_behind(head, physics.HEAD_TO_HITCH_DISTANCE)
  local orientation = head.orientation

  for index = 1, segment_count do
    local initial = physics.initial_state_from_hitch(hitch, orientation)
    local segment = create_segment(surface, force, initial)
    if not segment then
      for _, created_segment in ipairs(segments) do
        if is_valid(created_segment.trailer) then
          created_segment.trailer.destroy{raise_destroy = false}
        end
        if is_valid(created_segment.collision_proxy) then
          created_segment.collision_proxy.destroy{raise_destroy = false}
        end
      end
      return
    end

    segments[index] = segment
    hitch = physics.trailer_rear_hitch_position(initial.trailer_center, initial.trailer_orientation)
    orientation = initial.trailer_orientation
  end

  register_link(head, segments, variant_for_head(head.name))
end

local function validate_link(head_unit_number, link)
  migrate_link_shape(link)
  if not is_valid(link.head) or not link.trailers then
    if link.trailers then
      destroy_link_entities(link)
    end
    remove_link(head_unit_number)
    return false
  end

  for _, segment in ipairs(link.trailers) do
    if not is_valid(segment.trailer) then
      destroy_link_entities(link, segment.trailer)
      remove_link(head_unit_number)
      return false
    end
  end

  return true
end

local function compute_states(link)
  local states = {}
  local tow = {
    hitch = physics.position_behind(link.head, physics.HEAD_TO_HITCH_DISTANCE),
    orientation = link.head.orientation,
    speed = link.head.speed
  }

  for index, segment in ipairs(link.trailers) do
    local state = physics.next_segment_state(segment, tow)
    states[index] = state
    tow = {
      hitch = physics.trailer_rear_hitch_position(state.trailer_center, state.trailer_orientation),
      orientation = state.trailer_orientation,
      speed = link.head.speed
    }
  end

  return states
end

local function link_surfaces_match(link)
  local surface = link.head.surface
  for _, segment in ipairs(link.trailers) do
    if segment.trailer.surface ~= surface or segment.collision_proxy.surface ~= surface then
      return false
    end
  end
  return true
end

local function sync_research_recipe_unlocks()
  for _, force in pairs(game.forces) do
    for technology_name, recipe_names in pairs(TECHNOLOGY_UNLOCKS) do
      local technology = force.technologies[technology_name]
      local researched = technology and technology.researched or false
      for _, recipe_name in ipairs(recipe_names) do
        local recipe = force.recipes[recipe_name]
        if recipe then
          recipe.enabled = researched
        end
      end
    end
  end
end

function manager.init()
  ensure_storage()
  sync_debug_rendering_state()
  sync_research_recipe_unlocks()
  for head_unit_number, link in pairs(storage.trailers) do
    if validate_link(head_unit_number, link) then
      for _, segment in ipairs(link.trailers) do
        storage.trailers_by_trailer_unit_number[segment.trailer.unit_number] = head_unit_number
        ensure_collision_proxy(head_unit_number, link, segment)
      end
      ensure_accepted_state(link)
    end
  end
end

function manager.on_built_entity(event)
  ensure_storage()
  local entity = event.entity or event.created_entity
  if not is_valid(entity) then
    return
  end

  if is_head_name(entity.name) then
    create_trailers_for_head(entity)
  elseif entity.name == TRAILER_NAME or entity.name == TRAILER_PROXY_NAME then
    entity.speed = 0
  end
end

function manager.on_entity_removed(event)
  ensure_storage()
  local entity = event.entity
  if not entity then
    return
  end

  local buffer = is_mined_event(event) and event.buffer or nil

  if is_head_name(entity.name) and entity.unit_number then
    local link = storage.trailers[entity.unit_number]
    if link then
      remove_whole_link_for_entity(entity, link, entity.unit_number, buffer)
    else
      remove_link(entity.unit_number)
    end
  elseif entity.name == TRAILER_NAME and entity.unit_number then
    local head_unit_number = storage.trailers_by_trailer_unit_number[entity.unit_number]
    if head_unit_number then
      local link = storage.trailers[head_unit_number]
      if link then
        remove_whole_link_for_entity(entity, link, head_unit_number, buffer)
      else
        remove_link(head_unit_number)
      end
    end
  elseif entity.name == TRAILER_PROXY_NAME and entity.unit_number then
    local head_unit_number = storage.trailers_by_proxy_unit_number[entity.unit_number]
    if head_unit_number then
      local link = storage.trailers[head_unit_number]
      if link then
        remove_whole_link_for_entity(entity, link, head_unit_number, buffer)
      else
        remove_link(head_unit_number)
      end
    end
  end
end

function manager.on_entity_damaged(event)
  ensure_storage()
  apply_proxy_damage_to_trailer(event.entity, event.final_damage_amount)
end

function manager.on_player_driving_changed_state(event)
  ensure_storage()
  local player = game.get_player(event.player_index)
  if not player or not player.vehicle then
    return
  end

  local vehicle = player.vehicle
  if vehicle.name == TRAILER_NAME or vehicle.name == TRAILER_PROXY_NAME then
    vehicle.set_driver(nil)
    vehicle.speed = 0
    player.print({"message.trailer-cargo-not-drivable"})
  end
end

function manager.on_tick()
  ensure_storage()
  sync_debug_rendering_state()
  for head_unit_number, link in pairs(storage.trailers) do
    if validate_link(head_unit_number, link) then
      local proxies_ok = true
      for _, segment in ipairs(link.trailers) do
        if not ensure_collision_proxy(head_unit_number, link, segment) then
          proxies_ok = false
          break
        end
      end

      if not proxies_ok then
        local states = compute_states(link)
        restore_accepted_state(link)
        render_debug(link, states, true)
        render_blocked_debug(link, states[1])
        render_blocked_diagnostic(link, states[1], {
          segment_index = 0,
          steps = 0,
          failed_step = 0,
          check_type = PROXY_BUILD_CHECK_TYPE_NAME,
          can_place = false,
          teleport = false
        })
      elseif not link_surfaces_match(link) then
        remove_link(head_unit_number)
      else
        ensure_accepted_state(link)
        local states = compute_states(link)
        local moved = true
        local failed_diagnostic = nil
        local failed_state = nil

        for index, segment in ipairs(link.trailers) do
          local state = states[index]
          local segment_moved, diagnostic = move_proxy_substepped(segment, state.trailer_center, state.trailer_orientation)
          if not segment_moved then
            moved = false
            failed_diagnostic = diagnostic
            failed_diagnostic.segment_index = index
            failed_state = state
            break
          end
        end

        if moved then
          for index, segment in ipairs(link.trailers) do
            local state = states[index]
            segment.trailer.teleport(segment.collision_proxy.position, nil, false, false)
            segment.trailer.orientation = state.trailer_orientation
            segment.trailer.speed = 0
          end
          accept_state(link, states)
          render_debug(link, states, false)
        else
          restore_accepted_state(link)
          render_debug(link, states, true)
          render_blocked_debug(link, failed_state)
          render_blocked_diagnostic(link, failed_state, failed_diagnostic)
        end
      end
    end
  end
end

return manager
