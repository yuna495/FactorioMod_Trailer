local trailer_manager = require("scripts.trailer_manager")

script.on_init(trailer_manager.init)
script.on_configuration_changed(trailer_manager.init)

script.on_event(defines.events.on_built_entity, trailer_manager.on_built_entity)
script.on_event(defines.events.on_robot_built_entity, trailer_manager.on_built_entity)
script.on_event(defines.events.script_raised_built, trailer_manager.on_built_entity)
script.on_event(defines.events.script_raised_revive, trailer_manager.on_built_entity)

script.on_event(defines.events.on_player_mined_entity, trailer_manager.on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, trailer_manager.on_entity_removed)
script.on_event(defines.events.on_entity_died, trailer_manager.on_entity_removed)
script.on_event(defines.events.script_raised_destroy, trailer_manager.on_entity_removed)

script.on_event(defines.events.on_player_driving_changed_state, trailer_manager.on_player_driving_changed_state)
script.on_event(defines.events.on_tick, trailer_manager.on_tick)
