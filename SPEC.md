# Trailer SPEC

## Scope

This mod implements a Factorio 2.x Phase 1 free-driving semi-trailer prototype:

- A player-drivable trailer head based on the base game's `car` prototype.
- A separate cargo trailer entity based on the base game's `car` prototype.
- One fixed trailer per head.
- Automatic trailer creation behind the head when a trailer head is built.
- Runtime kinematic following driven by the head entity's Factorio-updated `position`, `orientation`, `speed`, `surface`, and validity.
- Persistent head/trailer linkage stored in `storage`.
- Trailer cargo inventory exposed through the vehicle inventory so inserters and players can load and unload it.

Phase 1 does not implement GUI coupling, multiple trailers, or complete obstacle collision resolution.

## Reference Findings

`Reference/kj_warrig_2.1.0` contains graphics, sounds, `info.json`, `Credits.txt`, a changelog, and migrations. It does not contain the War Rig prototype definition files, so the War Rig car prototype name, collision box, selection box, animation definition, and weight cannot be verified from the provided reference source. Because no explicit license file is present and `Credits.txt` only lists source asset credits, this mod does not copy War Rig graphics or sounds in Phase 1.

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
- `CarPrototype::energy_source` accepts burner or void energy sources.
- `LuaEntity.position`, `LuaEntity.orientation`, `LuaEntity.speed`, `LuaEntity.surface`, `LuaEntity.valid`, and `LuaEntity.unit_number` are used at runtime.
- `LuaEntity.teleport(position, surface, raise_teleported, snap_to_grid, build_check_type)` is used to move the trailer.
- `LuaSurface.can_place_entity{name=..., position=..., force=..., build_check_type=...}` can pre-check placement/collision.
- `defines.events.on_player_driving_changed_state` is used to prevent players from driving the trailer entity.

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
- Uses base car graphics in Phase 1
- Has a moderate trunk inventory

### Trailer Cargo

Prototype name: `trailer-cargo`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Uses a void energy source and zero practical traction settings for cargo-only behavior
- Has an independent cargo inventory
- Players are ejected if they enter it as a driver
- Uses base car graphics in Phase 1
- Uses a longer collision/selection footprint than the head, but collision behavior is still Phase 1 quality

## Runtime State

Runtime linkage is stored as:

```lua
storage.trailers = {
  [head_unit_number] = {
    head = LuaEntity,
    trailer = LuaEntity,
    previous_hitch_position = {x = number, y = number},
    trailer_orientation = number,
    last_head_position = {x = number, y = number},
    last_head_orientation = number
  }
}
```

`storage.trailers_by_trailer_unit_number` maps trailer unit numbers back to head unit numbers for cleanup and driver ejection.

Invalid entities are removed from storage during tick processing and relevant destroy/mine events.

## Kinematics

Current Phase 1 geometry constants:

- head center to hitch: `1.6` tiles
- trailer center to hitch: `3.0` tiles
- trailer axle to hitch: `4.8` tiles

Each tick for registered linked pairs:

1. Validate head and trailer.
2. Compute current hitch position behind the head.
3. Compute hitch displacement from the previous hitch position.
4. Build trailer forward and perpendicular vectors from the stored trailer orientation.
5. Project hitch displacement onto the trailer perpendicular vector.
6. Convert lateral displacement into a trailer orientation delta using `delta / TRAILER_AXLE_TO_HITCH_DISTANCE`.
7. Clamp trailer/head angle difference to `MAX_HITCH_ANGLE_TURNS`.
8. Reconstruct trailer center from hitch and trailer orientation.
9. Teleport the trailer to the reconstructed center and assign its orientation.
10. Store the current hitch and trailer orientation for save/load continuity.

The head's acceleration, braking, steering, and speed are left to Factorio's native car physics.

## Collision

Phase 1 does not implement robust trailer obstacle rollback. The trailer is moved by script teleport after optional placement checking. Known limitations:

- Scripted trailer movement may not behave like native car collision in every obstacle case.
- If placement checking rejects a new trailer position, this implementation leaves the trailer at its previous position for that tick and keeps the linkage state conservative.
- Head rollback and speed stopping are not implemented in Phase 1 because forcibly overriding Factorio car physics may create unsafe side effects without in-game validation.

Phase 2 should investigate `LuaSurface.can_place_entity` and `LuaEntity.teleport` build-check behavior in-game before adding rollback.

## Save Compatibility

The mod uses `storage`, keeps LuaEntity references only for entities it owns, and rebuilds storage tables with `script.on_init` and `script.on_configuration_changed`. Existing invalid references are cleaned opportunistically.

## Debugging

Runtime debug rendering is disabled by default with a local constant in `scripts/trailer_manager.lua`. When enabled, it draws short-lived markers for hitch, trailer center, and trailer axle positions.
