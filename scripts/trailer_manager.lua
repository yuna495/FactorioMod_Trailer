local physics = require("scripts.trailer_physics")

local manager = {}

local HEAD_NAME = "trailer-head"
local TRAILER_NAME = "trailer-cargo"
local DEBUG_RENDERING = false

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

local function render_debug(surface, state)
  if not DEBUG_RENDERING then
    return
  end

  rendering.draw_circle{
    color = {1, 0, 0},
    radius = 0.12,
    filled = true,
    target = state.hitch,
    surface = surface,
    time_to_live = 2
  }
  rendering.draw_circle{
    color = {0, 1, 0},
    radius = 0.12,
    filled = true,
    target = state.trailer_center,
    surface = surface,
    time_to_live = 2
  }
  if state.trailer_axle then
    rendering.draw_circle{
      color = {0, 0.4, 1},
      radius = 0.12,
      filled = true,
      target = state.trailer_axle,
      surface = surface,
      time_to_live = 2
    }
  end
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
      if link.trailer.teleport(state.trailer_center, surface, false, false, defines.build_check_type.script) then
        link.trailer.orientation = state.trailer_orientation
        link.trailer.speed = 0
        link.previous_hitch_position = state.hitch
        link.trailer_orientation = state.trailer_orientation
        link.last_head_position = {x = link.head.position.x, y = link.head.position.y}
        link.last_head_orientation = link.head.orientation
        render_debug(surface, state)
      end
    end
  end
end

return manager
