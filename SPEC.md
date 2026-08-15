# Trailer SPEC

## Scope

This mod implements a Factorio 2.x Phase 1 free-driving semi-trailer prototype:

- A player-drivable trailer head based on the base game's `car` prototype.
- A separate visible cargo trailer entity based on the base game's `car` prototype.
- A hidden collision proxy entity based on the base game's `car` prototype.
- One fixed trailer per head.
- Automatic trailer creation behind the head when a trailer head is built.
- Runtime kinematic following driven by the head entity's Factorio-updated `position`, `orientation`, `speed`, `surface`, and validity.
- Persistent head/trailer linkage stored in `storage`.
- Trailer cargo inventory exposed through the visible cargo vehicle inventory so inserters and players can load and unload it.

Phase 1 does not implement GUI coupling, multiple trailers, or complete obstacle collision resolution.

## Reference Findings

`Reference/kj_warrig_2.1.0` contains graphics, sounds, `info.json`, `Credits.txt`, a changelog, and migrations. It does not contain the War Rig prototype definition files, so the War Rig car prototype name, collision box, selection box, animation definition, and weight cannot be verified from the provided reference source. The Factorio Mod Portal page for `kj_warrig` lists the owner/author as `TheKingJo`, homepage as `https://steamcommunity.com/id/thekingjo/`, and license as `CC BY-NC-SA 4.0`. Phase 1 copies only the War Rig and cargo trailer entity graphics needed for the head and trailer sprites.

War Rig graphics copied into this mod:

- `graphics/entity/warrig/warrig_0.png` through `warrig_15.png`
- `graphics/entity/warrig/warrig_shadow_0.png` and `warrig_shadow_1.png`

Cargo trailer graphics copied into this mod:

- `graphics/entity/trailer/warrig_trailer_0.png` through `warrig_trailer_7.png`
- `graphics/entity/trailer/warrig_trailer_shadow_0.png` through `warrig_trailer_shadow_7.png`

Copied graphics are unmodified.

War Rig sounds copied into this mod:

- `sounds/brakes.ogg`
- `sounds/door-close.ogg`
- `sounds/engine-fail.ogg`
- `sounds/engine-start.ogg`
- `sounds/engine-stop.ogg`
- `sounds/engine.ogg`

Copied sounds are unmodified.

`Reference/kj_vehicles_2.1.11` contains the active War Rig car prototype integration used by `kj_warrig`. The transferred head audiovisual behavior is based on `prototypes/entities/warrig.lua`, `prototypes/entities.lua`, `prototypes/items.lua`, and `utils.lua`:

- `working_sound` keeps the base car driving sound and replaces the idle engine layer with `engine.ogg`.
- engine start/stop/no-fuel sounds use the copied `engine-start.ogg`, `engine-stop.ogg`, and `engine-fail.ogg`.
- braking and door close sounds use the copied `brakes.ogg` and `door-close.ogg`.
- exhaust smoke uses a local `trailer-warrig-smoke` prototype with the same black trivial-smoke parameters as `kj_warrig_smoke`.
- exhaust emission positions match the War Rig source positions at `{-1.25, 2}` and `{1.25, 2}`.

`Reference/trailer_simu` contains a Python/Pygame kinematic model. The transferred behavior is based on:

- hitch/kingpin position behind the head,
- previous and current hitch displacement,
- trailer forward and perpendicular vectors,
- lateral displacement converted into trailer angle change,
- trailer center reconstruction from hitch and trailer orientation,
- maximum hitch angle clamping.

The Python simulation's `MAX_HITCH_ANGLE` is 90 degrees. This mod stores that value as `MAX_HITCH_ANGLE_TURNS = 0.25`.

## Factorio API Usage

Confirmed from Factorio 2.x local base data and official API docs:

- `car` prototypes support `inventory_size`, `energy_source`, `effectivity`, `consumption`, `rotation_speed`, `rotation_snap_angle`, `friction`, `weight`, `collision_box`, and `selection_box`.
- The base `car` collision mask in local Factorio 2.x core data is `{player=true, car=true, train=true, is_object=true}` with `consider_tile_transitions=true`.
- The linked vehicle collision mask matches the base `car` mask and only adds `not_colliding_with_itself=true`. It does not add `item`, `object`, `rail`, `water_tile`, `is_lower_object`, or `elevated_rail`; adding those layers makes the head collide with ground rails that vanilla cars can cross.
- `not_colliding_with_itself=true` prevents collision only when both masks have that flag and the masks have the same layers.
- `CarPrototype::energy_source` accepts burner or void energy sources.
- `LuaEntity.position`, `LuaEntity.orientation`, `LuaEntity.speed`, `LuaEntity.surface`, `LuaEntity.valid`, and `LuaEntity.unit_number` are used at runtime.
- `LuaEntity.teleport(position, surface, raise_teleported, snap_to_grid, build_check_type)` is used to move the trailer.
- `LuaSurface.can_place_entity{name=..., position=..., force=..., build_check_type=...}` can pre-check placement/collision.
- `defines.events.on_player_driving_changed_state` is used to prevent players from driving the trailer entity.
- `CollisionMask` is prototype-level data. The available documented options include `layers`, `not_colliding_with_itself`, and `colliding_with_tiles_only`; no entity-instance or specific two-entity-pair collision exclusion is used by this mod.

Factorio orientation is a real orientation in turns: `0` is north, `0.25` is east, `0.5` is south, and values increase clockwise. The forward vector used by this mod is:

```lua
{ x = math.sin(orientation * 2 * math.pi), y = -math.cos(orientation * 2 * math.pi) }
```

This matches the Python simulation's `sin(angle)` / `-cos(angle)` direction convention after converting degrees to turns.

## Prototypes

### Trailer Head

Prototype name: `trailer-head`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Player-drivable
- Burner-fueled like the base car
- Keeps the base car fuel categories and fuel inventory behavior so vanilla fuels such as coal and rocket fuel remain usable.
- Uses copied `kj_warrig` War Rig graphics in Phase 1
- Uses copied `kj_warrig` War Rig engine, brake, no-fuel, and door-close sounds in Phase 1
- Emits War Rig-style black exhaust smoke from two rear exhaust positions while burning fuel
- Has a moderate trunk inventory

### Trailer Cargo

Prototype name: `trailer-cargo`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Uses a void energy source and zero practical traction settings for cargo-only behavior
- Has an independent cargo inventory
- Players are ejected if they enter it as a driver
- Uses copied `kj_warrig` cargo trailer graphics in Phase 1
- Uses a longer selection footprint than the head.
- Has an empty collision mask. It is the stable visual/inventory entity and is not responsible for obstacle blocking.

### Trailer Cargo Collision Proxy

Prototype name: `trailer-cargo-collision-proxy`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Hidden, non-minable, non-selectable, non-drivable, and invisible.
- Uses a void energy source and zero practical traction settings.
- Uses the same explicit collision mask as `trailer-head`, with `not_colliding_with_itself=true`, so the scripted linked vehicle parts do not collide with each other.
- Uses the full trailer collision footprint. Collision with the linked head is avoided through the shared linked-vehicle collision mask and `not_colliding_with_itself=true`.

## Runtime State

Runtime linkage is stored as:

```lua
storage.trailers = {
  [head_unit_number] = {
    head = LuaEntity,
    trailer = LuaEntity,
    collision_proxy = LuaEntity,
    previous_hitch_position = {x = number, y = number},
    trailer_orientation = number,
    accepted_head_position = {x = number, y = number},
    accepted_head_orientation = number,
    accepted_hitch_position = {x = number, y = number},
    accepted_trailer_position = {x = number, y = number},
    accepted_trailer_orientation = number
  }
}
```

`storage.trailers_by_trailer_unit_number` maps visible trailer unit numbers back to head unit numbers for cleanup and driver ejection.
`storage.trailers_by_proxy_unit_number` maps hidden collision proxy unit numbers back to head unit numbers for cleanup and driver ejection.

Invalid entities are removed from storage during tick processing and relevant destroy/mine events.

## Kinematics

Current Phase 1 geometry constants:

- head center to hitch: `2.05` tiles
- trailer center to hitch: `4.25` tiles
- trailer axle to hitch: `7.1` tiles

Current prototype dimensions:

- head collision box: `{{-0.96, -2.15}, {0.96, 2.15}}`
- head selection box: `{{-1.15, -2.35}, {1.15, 2.35}}`
- linked vehicle collision mask: `{player=true, car=true, train=true, is_object=true}`, `consider_tile_transitions=true`, `not_colliding_with_itself=true`
- trailer proxy collision box: `{{-1.17, -5.0}, {1.17, 5.0}}`
- trailer selection box: `{{-1.35, -5.2}, {1.35, 5.2}}`

Current sprite setup:

- head render layer: `object`
- trailer render layer: `object`; raising the cargo trailer to `higher-object-above` caused horizontal-angle sprite disappearance/flicker in-game, so Phase 1 keeps the default vehicle render layer.
- head body: 16 stripe files, each `2886x7696`, cell `962x962`, 24 directions per file, 384 directions total, scale `0.24`, shift `{0, 0}`
- head shadow: not used in Phase 1 after the head body was corrected to 384 directions; the copied shadow files only provide 128 directions and cannot be mixed with the 384-direction body layer without a converted shadow sheet.
- trailer body: 8 stripe files, each `5032x5032`, cell `1258x1258`, 16 directions per file, 128 directions total, scale `0.32`, shift `{0, 0}`
- trailer shadow: 8 stripe files, each `5032x5032`, cell `1258x1258`, 16 directions per file, 128 directions total, scale `0.32`, shift `{0, 0}`

The first sprite direction faces north and follows Factorio's car orientation order; `orientation = 0`, `0.25`, `0.5`, and `0.75` are intended to correspond to north, east, south, and west.

Each tick for registered linked pairs:

1. Validate head and trailer.
2. Compute current hitch position behind the head.
3. Compute hitch displacement from the previous hitch position.
4. Build trailer forward and perpendicular vectors from the stored trailer orientation.
5. Project hitch displacement onto the trailer perpendicular vector.
6. Convert lateral displacement into a trailer orientation delta using `delta / TRAILER_AXLE_TO_HITCH_DISTANCE`.
7. Clamp trailer/head angle difference to `MAX_HITCH_ANGLE_TURNS`.
8. Reconstruct trailer center from hitch and trailer orientation.
9. Move the hidden collision proxy from the last accepted pose to the reconstructed target pose in substeps. Each substep compares `LuaSurface.can_place_entity` and `LuaEntity.teleport` for the proxy at the step position and rounded direction, using `defines.build_check_type.ghost_revive` for both calls.
10. If every substep succeeds, teleport the visible trailer to the accepted proxy position and assign both orientations.
11. If any substep fails, restore the head, proxy, visible trailer, hitch history, and trailer orientation to the last accepted pose; set head speed to `0`; show blocked debug text.
12. Store the accepted head, hitch, proxy/trailer position, and trailer orientation for save/load continuity.

The proxy substep target spacing is `0.22` tiles. The step count is based on the larger of center movement and angular sweep at the trailer collision-box half diagonal, capped at `64` substeps per linked trailer per tick to keep UPS cost bounded.

`defines.build_check_type.ghost_revive` is selected for Phase 1 proxy checks because the official runtime API documents `LuaSurface.can_place_entity` as defaulting to `ghost_revive`, while `LuaEntity.teleport` defaults to `script`. Using `ghost_revive` explicitly on both calls keeps the placement pre-check and the actual teleport check aligned.

The head's acceleration, braking, steering, and speed are left to Factorio's native car physics.

## Collision

Phase 1 does not implement full native vehicle impact behavior. The visible trailer cargo prototype uses `collision_mask = {layers = {}}` so its sprite/inventory entity can always stay visually stable and is not hidden by failed collision-checked teleports. Obstacle blocking is handled by `trailer-cargo-collision-proxy`, an invisible car prototype with the same base-car-equivalent collision mask as the head plus `not_colliding_with_itself=true`.

Factorio `collision_box` is a single bounding box and cannot contain a hole. The hidden collision proxy uses the full trailer footprint so the visual front/kingpin area is also covered. Self-collision with the linked head is avoided by giving both prototypes the same linked mask and `not_colliding_with_itself=true`.

The mod's existing forward vector makes local negative Y the forward direction. The collision proxy covers local Y from `-5.0` to `5.0` and includes the entity origin `{0, 0}`.

The values are defined once in `scripts/trailer_geometry.lua` and reused by data-stage prototypes and runtime debug rendering.

Reason: Factorio collision masks are prototype-level. `not_colliding_with_itself=true` applies when both entities have the option and the same collision layers, so this mod gives `trailer-head` and `trailer-cargo-collision-proxy` the same linked-vehicle mask. This cannot express "ignore only this exact linked pair" and may also prevent collision between multiple Trailer MOD vehicle parts that share the same mask. The mask stays otherwise equivalent to vanilla `car`, because vanilla car already collides with trees and buildings through shared `player` / `is_object` layers while still crossing ground rails.

Known limitations:

- Scripted trailer proxy movement may not produce native car impact damage, tree destruction, or vehicle damage.
- Proxy movement is substepped from the last accepted pose to reduce teleport tunneling. If a substep fails, the whole tick is rejected; partial substep progress is not accepted.
- `LuaEntity.teleport` is treated as authoritative for movement. `can_place_entity` is diagnostic only, because in-game testing showed `can_place=false` and `teleport=true` near nearby objects where the proxy could actually move. When debug rendering is enabled, blocked ticks show the failing substep plus both results.
- On proxy movement failure, head movement is rolled back to the last accepted head pose and `head.speed` is set to `0`.
- Debug rendering shows a short-lived `Trailer blocked` text when the proxy teleport fails.

Phase 2 should investigate native impact damage and obstacle destruction behavior.

## Save Compatibility

The mod uses `storage`, keeps LuaEntity references only for entities it owns, and rebuilds storage tables with `script.on_init` and `script.on_configuration_changed`. Existing invalid references are cleaned opportunistically.

## Debugging

Runtime debug rendering is enabled for Phase 1 with a single local constant in `scripts/trailer_manager.lua`. When enabled, it draws short-lived rendering objects each tick:

- rotated head collision-box outline in red,
- rotated accepted trailer proxy collision-box outline in blue,
- rotated rejected target trailer proxy outline in orange when proxy movement is blocked,
- head center in white,
- trailer center in white,
- hitch position in yellow,
- trailer axle position in green,
- hitch angle text near the head.
- blocked diagnostic text with the failing substep number, build check type, `can_place_entity` result, and `teleport` result.

If debug rendering is turned off, the rendering code returns before doing geometry work.
