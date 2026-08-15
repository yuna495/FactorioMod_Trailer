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
- The linked vehicle collision mask intentionally adds common obstacle layers (`item`, `object`, and `is_lower_object`) so the hidden cargo collision proxy can collide with trees, rocks, buildings, blocking tiles, and vanilla vehicles while still avoiding same-mask Trailer MOD self-collision. It intentionally does not add `elevated_rail`, because that caused the drivable head to collide with rails in-game.
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
- Uses copied `kj_warrig` War Rig graphics in Phase 1
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
    last_head_position = {x = number, y = number},
    last_head_orientation = number
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
- linked vehicle collision mask: `{item=true, object=true, player=true, water_tile=true, car=true, train=true, is_lower_object=true, is_object=true}`, `consider_tile_transitions=true`, `not_colliding_with_itself=true`
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
9. Teleport the hidden collision proxy to the reconstructed center with script build checks.
10. If the collision proxy move succeeds, teleport the visible trailer to the accepted proxy position and assign both orientations.
11. If the collision proxy move fails, keep the visible trailer at the previous accepted proxy position, show blocked debug text, and advance hitch history enough to avoid accumulating an unstable displacement spike.
12. Store the current hitch and accepted trailer orientation for save/load continuity.

The head's acceleration, braking, steering, and speed are left to Factorio's native car physics.

## Collision

Phase 1 does not implement robust trailer obstacle rollback. The visible trailer cargo prototype uses `collision_mask = {layers = {}}` so its sprite/inventory entity can always stay visually stable and is not hidden by failed collision-checked teleports. Obstacle blocking is handled by `trailer-cargo-collision-proxy`, an invisible car prototype with the same explicit obstacle-aware collision mask as the head plus `not_colliding_with_itself=true`.

Factorio `collision_box` is a single bounding box and cannot contain a hole. The hidden collision proxy uses the full trailer footprint so the visual front/kingpin area is also covered. Self-collision with the linked head is avoided by giving both prototypes the same linked mask and `not_colliding_with_itself=true`.

The mod's existing forward vector makes local negative Y the forward direction. The collision proxy covers local Y from `-5.0` to `5.0` and includes the entity origin `{0, 0}`.

The values are defined once in `scripts/trailer_geometry.lua` and reused by data-stage prototypes and runtime debug rendering.

Reason: Factorio collision masks are prototype-level. `not_colliding_with_itself=true` applies when both entities have the option and the same collision layers, so this mod gives `trailer-head` and `trailer-cargo-collision-proxy` the same linked-vehicle mask. This cannot express "ignore only this exact linked pair" and may also prevent collision between multiple Trailer MOD vehicle parts that share the same mask. It should still collide with vanilla vehicles and ordinary obstacles that do not use this exact flagged mask.

Known limitations:

- Scripted trailer proxy movement may not behave like native car collision in every obstacle case.
- If proxy teleport fails for any remaining reason, the hitch history is advanced to the current hitch position so one failure does not accumulate a large displacement and destabilize later ticks.
- Debug rendering shows a short-lived `Trailer blocked` text when the proxy teleport fails.
- Head rollback and speed stopping are not implemented in Phase 1 because forcibly overriding Factorio car physics may create unsafe side effects without in-game validation.

Phase 2 should investigate `LuaSurface.can_place_entity` and `LuaEntity.teleport` build-check behavior in-game before adding rollback.

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

If debug rendering is turned off, the rendering code returns before doing geometry work.
