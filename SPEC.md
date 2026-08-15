# Trailer SPEC

## Scope

This mod implements Factorio 2.x free-driving semi-trailer prototypes:

- A player-drivable trailer head based on the base game's `car` prototype.
- A separate visible cargo trailer entity based on the base game's `car` prototype.
- A hidden collision proxy entity based on the base game's `car` prototype.
- One fixed trailer behind a `trailer-head` Semi-Trailer.
- Two fixed trailers behind a `double-trailer-head` Double-Trailer.
- Three fixed trailers behind a `triple-trailer-head` Triple-Trailer.
- A rail-only War Rig locomotive, cargo wagon, and fluid wagon based on the base game's rolling stock prototypes.
- A dedicated road-rail planner and rail prototypes that use the `kj_vehicles` road-rail artwork while remaining compatible with normal rolling stock.
- Automatic trailer creation behind the head when a trailer head is built.
- Runtime kinematic following driven by the head entity's Factorio-updated `position`, `orientation`, `speed`, `surface`, and validity.
- Persistent head/trailer linkage stored in `storage`.
- Trailer cargo inventory exposed through the visible cargo vehicle inventory so inserters and players can load and unload it.

Phase 2 does not implement GUI coupling, road/rail conversion, coupling/uncoupling for road trailers, manual cargo-only road placement, road fluid trailers, tank trailers, automatic driving for road trailers, or complete native vehicle impact behavior.

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

Road-rail graphics copied into this mod from `Reference/kj_vehicles_2.1.11`:

- `graphics/entity/rail/road.png`
- `graphics/entity/rail/roads.png`

Copied road-rail graphics are unmodified and are recorded under the upstream `kj_vehicles` CC BY-NC-SA 4.0 license.

`Reference/kj_vehicles_2.1.11` contains the active War Rig car prototype integration used by `kj_warrig`. The transferred head audiovisual behavior is based on `prototypes/entities/warrig.lua`, `prototypes/entities.lua`, `prototypes/items.lua`, and `utils.lua`:

- `working_sound` keeps the base car driving sound and replaces the idle engine layer with `engine.ogg`.
- engine start/stop/no-fuel sounds use the copied `engine-start.ogg`, `engine-stop.ogg`, and `engine-fail.ogg`.
- braking and door close sounds use the copied `brakes.ogg` and `door-close.ogg`.
- exhaust smoke uses a local `trailer-warrig-smoke` prototype with the same black trivial-smoke parameters as `kj_warrig_smoke`.
- exhaust emission positions are set to `{-1, 1.4}` and `{1, 1.4}` with `height = 1.4`.

`Reference/kj_vehicles_2.1.11/prototypes/warrig.lua` contains the upstream Rail War Rig rolling stock prototypes:

- locomotive prototype: `kj_warrig_train`
- cargo wagon prototype: `kj_warrig_wagon`
- fluid wagon prototype: `kj_warrig_wagon_fluid`
- cargo wagon inventory size: `200`
- upstream wagon fluid capacity field: `capacity = 100000`
- upstream locomotive performance: `weight = 13000`, `max_speed = 0.6`, `max_power = "2000kW"`, `braking_force = 15`, `reversing_power_modifier = 1`, `friction_force = 0.50`, `air_resistance = 0.0075`, `connection_distance = 3`, `joint_distance = 8`
- upstream wagon performance: `weight = 23000`, `max_speed = 1.5`, `braking_force = 15`, `friction_force = 0.50`, `air_resistance = 0.01`, `connection_distance = 3`, `joint_distance = 8`
- upstream Rail War Rig uses the same `graphics/entity/warrig` and `graphics/entity/trailer` sprite files already copied into this mod.
- upstream rail minimap images are `graphics/map_symbol.png`, `graphics/map_symbol_selected.png`, `graphics/wagon_map_symbol.png`, and `graphics/wagon_map_symbol_selected.png`.
- upstream rail icons are `graphics/train.png`, `graphics/wagon.png`, and `graphics/wagon_fluid.png`.
- upstream Rail War Rig depends on a custom `kj_gas_barrel` fuel category. This mod does not add that fuel category for Rail War Rig.
- upstream dedicated road rails are defined in `Reference/kj_vehicles_2.1.11/prototypes/roads.lua` as `kj_road_rails`, `kj_road_rail_straight`, `kj_road_rail_half_diagonal`, `kj_road_rail_curved_rail_a`, and `kj_road_rail_curved_rail_b`.

Base Factorio 2.x rolling stock values used as the Rail War Rig starting point:

- base locomotive performance: `weight = 2000`, `max_speed = 1.2`, `max_power = "600kW"`, `braking_force = 10`, `reversing_power_modifier = 0.6`, `friction_force = 0.50`, `air_resistance = 0.0075`, `connection_distance = 3`, `joint_distance = 4`
- base locomotive fuel: burner energy source with `fuel_categories = {"chemical"}` and `fuel_inventory_size = 3`
- base cargo wagon inventory size: `40`
- base fluid wagon capacity: `50000`
- base wagon geometry: `collision_box = {{-0.6, -2.4}, {0.6, 2.4}}`, `selection_box = {{-1, -2.703125}, {1, 3.296875}}`, `connection_distance = 3`, `joint_distance = 4`

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
- `defines.events.on_entity_damaged` is used to forward damage from a hidden trailer collision proxy to its matching visible cargo trailer.
- `defines.events.on_player_mined_entity` and `defines.events.on_robot_mined_entity` provide a mining buffer that this mod uses to return the linked head item and linked vehicle inventories when any visible road-trailer part is mined.
- Destroy events without a mining buffer, including death and `script_raised_destroy`, remove every linked road-trailer part without returning linked inventories.
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
- Uses `graphics/icon/icon.png` for its entity and item icons.
- Uses the War Rig minimap images `graphics/map_symbol/map_symbol.png` and `graphics/map_symbol/map_symbol_selected.png`.
- Has a moderate trunk inventory
- Uses the same War Rig visual size as `trailer-rail-locomotive` so road and rail heads have a matching size feel.

The in-game display name for `trailer-head` is `Semi-Trailer`. The prototype name remains `trailer-head` for save compatibility.

### Double Trailer Head

Prototype name: `double-trailer-head`

- Type: `car`
- Deep copy of the configured `trailer-head` prototype.
- Uses the same sprite, collision, engine, fuel, acceleration, braking, rotation, exhaust, and sound settings as `trailer-head`.
- Uses a heavier Double-specific head weight so the Double-Trailer handles differently from the Semi-Trailer.
- Uses `graphics/icon/icon.png` for its entity and item icons.
- Uses the War Rig minimap images `graphics/map_symbol/map_symbol.png` and `graphics/map_symbol/map_symbol_selected.png`.
- `name`, `localised_name`, `localised_description`, and `minable.result` are changed for the Double-Trailer item.
- Player-drivable.
- Automatically creates two visible cargo trailers and two hidden collision proxies when built.

The in-game display name for `double-trailer-head` is `Double-Trailer`.

### Triple Trailer Head

Prototype name: `triple-trailer-head`

- Type: `car`
- Deep copy of the configured `trailer-head` prototype.
- Uses the same sprite, collision, engine, fuel, acceleration, braking, rotation, exhaust, sound, icon, and minimap settings as `trailer-head`.
- Uses a heavier Triple-specific head weight so the Triple-Trailer scales from the Double-Trailer in the same way the Double-Trailer scales from the Semi-Trailer.
- `name`, `localised_name`, `localised_description`, and `minable.result` are changed for the Triple-Trailer item.
- Player-drivable.
- Automatically creates three visible cargo trailers and three hidden collision proxies when built.

The in-game display name for `triple-trailer-head` is `Triple-Trailer`.

### Trailer Cargo

Prototype name: `trailer-cargo`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Uses a void energy source and zero practical traction settings for cargo-only behavior
- Has an independent cargo inventory
- Keeps its own `weight = 4000`, but this does not add to the road head's native car mass because the trailer is a separate scripted entity.
- Players are ejected if they enter it as a driver
- Uses copied `kj_warrig` cargo trailer graphics in Phase 1
- Uses a longer selection footprint than the head, with the rear side shortened enough to keep the damage/health bar close to the visible trailer body.
- Has a full trailer-sized interaction collision box with an empty collision mask. It is the stable visual/inventory entity and is not responsible for obstacle blocking.
- Inserters interact with the visible cargo entity's inventory through that full interaction box.
- Uses the wagon minimap images `graphics/map_symbol/wagon_map_symbol.png` and `graphics/map_symbol/wagon_map_symbol_selected.png`.

### Trailer Cargo Collision Proxy

Prototype name: `trailer-cargo-collision-proxy`

- Type: `car`
- Based on a deep copy of base `data.raw.car.car`
- Hidden, non-minable, non-selectable, non-drivable, and invisible.
- Uses a void energy source and zero practical traction settings.
- Uses the same explicit collision mask as `trailer-head`, with `not_colliding_with_itself=true`, so the scripted linked vehicle parts do not collide with each other.
- Uses the full trailer collision footprint. Collision with the linked head is avoided through the shared linked-vehicle collision mask and `not_colliding_with_itself=true`.
- Is damageable only as a damage relay. Runtime damage received by the proxy is applied to the matching visible `trailer-cargo`, then the proxy health is restored so the player-visible trailer health is the authoritative health.

### Items and Recipes

- `trailer-head` places `trailer-head` and is displayed as `Semi-Trailer`.
- `double-trailer-head` places `double-trailer-head` and is displayed as `Double-Trailer`.
- `triple-trailer-head` places `triple-trailer-head` and is displayed as `Triple-Trailer`.
- Road Semi-Trailer, Double-Trailer, and Triple-Trailer items use `graphics/icon/icon.png`.
- `trailer-cargo` remains an internal hidden item and is created only by script; users should not see or craft it as a normal item.
- Road recipes are disabled by default and unlocked by technology.
- `trailer-head` is unlocked by `trailer-head`.
- `double-trailer-head` is unlocked by `double-trailer-head`.
- `triple-trailer-head` is unlocked by `triple-trailer-head`.
- `trailer-head` recipe costs 8 engine units, 20 iron gear wheels, and 20 steel plates.
- `double-trailer-head` recipe costs 12 engine units, 30 iron gear wheels, and 30 steel plates.
- `triple-trailer-head` recipe costs 16 engine units, 40 iron gear wheels, and 40 steel plates.

### Rail War Rig Locomotive

Prototype name: `trailer-rail-locomotive`

- Type: `locomotive`
- Based on a deep copy of base `data.raw.locomotive.locomotive`
- Displayed as `Rail War Rig`
- Uses the existing War Rig body sprite files under `graphics/entity/warrig`.
- Does not use upstream-only War Rig light sprite files that are not copied into this mod.
- Uses the existing copied War Rig engine, brake, start, stop, and door sounds.
- Uses base locomotive burner fuel categories and fuel inventory so vanilla locomotive fuels remain usable.
- Uses base locomotive performance values, except geometry is adjusted for the War Rig-sized sprite.
- Uses `graphics/icon/train.png` for entity, item, and recipe icons.

Rail locomotive adopted values:

- collision box: `{{-1.0, -3.2}, {1.0, 3.2}}`
- selection box: `{{-1.2, -3.6}, {1.2, 3.6}}`
- sprite scale: `0.384`
- sprite shift: `{0, 0.2}`
- connection distance: `3`
- joint distance: `5`
- weight: `2000`
- max speed: `1.2`
- max power: `"600kW"`
- braking force: `10`
- reversing power modifier: `0.6`
- friction force: `0.50`
- air resistance: `0.0075`
- fuel categories: base locomotive `{"chemical"}`
- fuel inventory size: base locomotive `3`
- exhaust smoke: same `trailer-warrig-smoke` emissions as the road heads, from positions `{-1.2, 1.6}` and `{1.2, 1.6}`
- sounds: War Rig engine, start, stop, brake, no-fuel, and door-close sounds match the road head assets as closely as the locomotive sound prototype supports.

### Rail Cargo Trailer

Prototype name: `trailer-rail-cargo-wagon`

- Type: `cargo-wagon`
- Based on a deep copy of base `data.raw["cargo-wagon"]["cargo-wagon"]`
- Displayed as `Rail Cargo Trailer`
- Uses the existing trailer body and shadow sprite files under `graphics/entity/trailer`.
- Uses base cargo wagon behavior for inserters, station loading, filters, schedules, and circuit/train integration.
- Uses `graphics/icon/wagon.png` for entity, item, and recipe icons.
- Does not use the road trailer collision proxy or runtime trailer storage.

Rail cargo wagon adopted values:

- inventory size: `100`, matching `trailer-cargo`
- collision box: `{{-0.8, -3.4}, {0.8, 3.4}}`
- selection box: `{{-1.1, -3.8}, {1.1, 3.8}}`
- sprite scale: `0.384`
- body sprite shift: `{0, 0}`
- shadow sprite shift: `{0.96, 0.38}`
- connection distance: `3`
- joint distance: `5`
- weight: base cargo wagon `1000`
- max speed: base cargo wagon `1.5`
- braking force: base cargo wagon `3`
- friction force: base cargo wagon `0.50`
- air resistance: base cargo wagon `0.01`

### Rail Fluid Trailer

Prototype name: `trailer-rail-fluid-wagon`

- Type: `fluid-wagon`
- Based on a deep copy of base `data.raw["fluid-wagon"]["fluid-wagon"]`
- Displayed as `Rail Fluid Trailer`
- Uses the same trailer body and shadow sprite files as the Rail Cargo Trailer.
- Uses base fluid wagon behavior for pumps, train stops, GUI, schedules, and circuit/train integration.
- Uses `graphics/icon/wagon_fluid.png` for entity, item, and recipe icons.
- Does not implement custom Lua fluid handling.

Rail fluid wagon adopted values:

- capacity: base fluid wagon `50000`
- collision box, selection box, sprite scale, sprite shift, connection distance, joint distance, weight, max speed, braking force, friction force, and air resistance match `trailer-rail-cargo-wagon`.

### Rail Items and Recipes

- Rail item prototypes are `item-with-entity-data` so locomotive/wagon entity data is preserved.
- Rail item stack size is `5`, matching vanilla locomotive and wagon items.
- Rail items use subgroup `train-transport` and orders after vanilla rolling stock.
- Rail recipes are disabled by default and unlocked by `trailer-rail-war-rig`.
- `trailer-rail-locomotive` recipe costs about 1.5x the base locomotive recipe: 30 engine units, 15 electronic circuits, and 45 steel plates.
- `trailer-rail-cargo-wagon` recipe costs about 1.5x the base cargo wagon recipe: 15 iron gear wheels, 30 iron plates, and 30 steel plates.
- `trailer-rail-fluid-wagon` recipe costs about 1.5x the base fluid wagon recipe: 15 iron gear wheels, 24 steel plates, 12 pipes, and 2 storage tanks.

### Dedicated Road Rails

Rail planner item name: `trailer-road-rails`

Rail prototypes:

- `trailer-road-rail-straight`
- `trailer-road-rail-half-diagonal`
- `trailer-road-rail-curved-a`
- `trailer-road-rail-curved-b`

Dedicated road rails:

- Are optional visual rails for the Rail War Rig theme.
- Use the `graphics/entity/rail/roads.png` rail sheet copied from `kj_vehicles`.
- Use `graphics/entity/rail/road.png` as the rail planner icon.
- Do not restrict the Rail War Rig to only those rails; standard Factorio rails remain usable.
- Do not add road/rail mode conversion or any runtime script handling.
- Use Factorio 2.x rail prototype types: `straight-rail`, `half-diagonal-rail`, `curved-rail-a`, and `curved-rail-b`.
- Are crafted from stone brick, concrete, and water.
- The road-rail planner recipe is disabled by default and unlocked by `trailer-rail-war-rig`.

### Technologies

Technology icon: `graphics/technology/technology.png`

Technology prototypes:

- `trailer-head`
- `double-trailer-head`
- `triple-trailer-head`
- `trailer-rail-war-rig`

Research:

- `trailer-head` is displayed as `Semi-Trailer`, requires `automobilism`, costs 100 automation + logistic science packs, and unlocks the `trailer-head` recipe.
- `double-trailer-head` is displayed as `Double-Trailer`, requires `trailer-head`, costs 200 automation + logistic science packs, and unlocks the `double-trailer-head` recipe.
- `triple-trailer-head` is displayed as `Triple-Trailer`, requires `double-trailer-head`, costs 300 automation + logistic science packs, and unlocks the `triple-trailer-head` recipe.
- `trailer-rail-war-rig` is displayed as `Rail War Rig`, requires `automated-rail-transportation` and `fluid-wagon`, costs 250 automation + logistic science packs, and unlocks `trailer-rail-locomotive`, `trailer-rail-cargo-wagon`, `trailer-rail-fluid-wagon`, and `trailer-road-rails`.

The technology stage does not create persistent runtime state. Existing saves keep their entities and storage links. On init/configuration change, each force's Trailer recipes are synchronized to the researched state of these technologies so older saves do not keep the previous temporary always-enabled recipes unless the matching technology is researched.

## Runtime State

Runtime linkage is stored with an explicit variant and segment list. New links use:

```lua
storage.trailers = {
  [head_unit_number] = {
    variant = "single" or "double" or "triple",
    head = LuaEntity,
    trailers = {
      [1] = {
        trailer = LuaEntity,
        collision_proxy = LuaEntity,
        previous_hitch_position = {x = number, y = number},
        trailer_orientation = number,
        accepted_hitch_position = {x = number, y = number},
        accepted_trailer_position = {x = number, y = number},
        accepted_trailer_orientation = number
      },
      [2] = ...
    },
    accepted_head_position = {x = number, y = number},
    accepted_head_orientation = number
  }
}
```

Phase 1 saves may still contain the old single-trailer shape:

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

`script.on_init` and `script.on_configuration_changed` migrate the old shape to `variant = "single"` and `trailers = {[1] = ...}` without destroying valid Phase 1 entities.

`storage.trailers_by_trailer_unit_number` maps visible trailer unit numbers back to head unit numbers for cleanup and driver ejection.
`storage.trailers_by_proxy_unit_number` maps hidden collision proxy unit numbers back to head unit numbers for cleanup and driver ejection.

Invalid entities are removed from storage during tick processing and relevant destroy/mine events.

When any visible road-trailer part is mined, the entire linked road vehicle is removed:

- Mining a head removes all linked trailers and collision proxies.
- Mining a visible trailer removes the linked head, every linked visible trailer, and every linked collision proxy.
- The mined rig returns exactly one head item for the linked variant: `trailer-head`, `double-trailer-head`, or `triple-trailer-head`.
- Hidden/internal cargo trailer items are not returned to the player.
- Inventories from linked heads and linked visible cargo trailers are moved into the mining buffer so Factorio handles inventory overflow like normal mining.

When any linked road-trailer part is destroyed rather than mined, the entire linked road vehicle is destroyed:

- The linked head, all linked visible trailers, and all linked collision proxies are removed.
- Inventories and fuel in the linked head and linked trailers are lost, matching destruction rather than mining.
- Damage to a hidden collision proxy reduces the corresponding visible cargo trailer's health. If that visible trailer reaches zero health, the linked road vehicle is destroyed and inventories/fuel are lost.

## Kinematics

Current geometry constants:

- head center to hitch: `3.08` tiles
- trailer center to hitch: `5.52` tiles
- trailer center to rear hitch: `5.52` tiles
- trailer axle to hitch: `8.94` tiles
- trailer lateral response: `0.95`
- stationary head speed threshold: `0.002`
- stationary hitch movement threshold: `0.002` tiles
- trailer angle deadzone: `0.0002` turns

Current trailer head tuning values:

- Semi-Trailer effectivity: `0.7`
- Semi-Trailer consumption: `"2500kW"`
- Semi-Trailer braking power: `"400kW"`
- Semi-Trailer friction: `0.0015`
- Semi-Trailer rotation speed: `0.01`
- Semi-Trailer rotation snap angle: `0.015`
- Semi-Trailer weight: `20000`
- Double-Trailer uses the same values except weight: `32000`
- Triple-Trailer uses the same values except weight: `44000`

The Double-Trailer and Triple-Trailer use separate head weights instead of trying to sum trailer entity weights into the head. Factorio does not natively couple the scripted road trailer entities to the head as a single car mass, so setting `trailer-cargo.weight = 12000` would not make the driving head behave like an `8000 + 12000`, `8000 + 12000 + 12000`, or `8000 + 12000 + 12000 + 12000` vehicle.

Current prototype dimensions:

- head collision box: `{{-1.0, -3.2}, {1.0, 3.2}}`
- head selection box: `{{-1.2, -3.6}, {1.2, 3.6}}`
- linked vehicle collision mask: `{player=true, car=true, train=true, is_object=true}`, `consider_tile_transitions=true`, `not_colliding_with_itself=true`
- trailer proxy collision box: `{{-1.4, -6.0}, {1.4, 6.0}}`
- trailer selection box: `{{-1.62, -6.24}, {1.62, 6.24}}`

Current sprite setup:

- head render layer: `object`
- trailer render layer: `object`; raising the cargo trailer to `higher-object-above` caused horizontal-angle sprite disappearance/flicker in-game, so Phase 1 keeps the default vehicle render layer.
- head body: 16 stripe files, each `2886x7696`, cell `962x962`, 24 directions per file, 384 directions total, scale `0.384`, shift `{0, 0.2}`
- head shadow: not used in Phase 1 after the head body was corrected to 384 directions; the copied shadow files only provide 128 directions and cannot be mixed with the 384-direction body layer without a converted shadow sheet.
- trailer body: 8 stripe files, each `5032x5032`, cell `1258x1258`, 16 directions per file, 128 directions total, scale `0.384`, shift `{0, 0}`
- trailer shadow: 8 stripe files, each `5032x5032`, cell `1258x1258`, 16 directions per file, 128 directions total, scale `0.384`, shift `{0, 0}`

The first sprite direction faces north and follows Factorio's car orientation order; `orientation = 0`, `0.25`, `0.5`, and `0.75` are intended to correspond to north, east, south, and west.

Each tick for registered linked vehicles:

1. Validate head and all trailers in the variant.
2. Compute Trailer A from the head rear hitch using the same kinematics as Phase 1.
3. For Double-Trailer and Triple-Trailer, compute each following trailer from the previous trailer's rear hitch. Each following trailer's maximum articulation compares the previous segment orientation against the current segment orientation, not the head orientation against every segment.
4. Move all hidden collision proxies from their last accepted poses to the reconstructed target poses in substeps. Each substep compares `LuaSurface.can_place_entity` and `LuaEntity.teleport` for the proxy at the step position and rounded direction, using `defines.build_check_type.ghost_revive` for both calls.
5. Accept the tick only if every proxy movement succeeds.
6. If every proxy succeeds, teleport the visible trailers to the accepted proxy positions and assign all orientations.
7. If any proxy fails, restore the head, all proxies, all visible trailers, hitch histories, and trailer orientations to the last accepted pose; set head speed to `0`; show blocked debug text.
8. Store the accepted head, hitch, proxy/trailer positions, and trailer orientations for save/load continuity.

The per-segment trailer solver:

1. Receives a tow hitch position, tow orientation, tow speed, and the segment's previous accepted pose.
2. If the tow speed and hitch movement are both below the stationary thresholds, reuse the accepted trailer center and orientation without applying no-side-slip correction.
3. Otherwise, derive the previously accepted trailer axle position from the accepted trailer center and orientation.
4. Compute the ideal no-side-slip trailer orientation from the previous axle position toward the current hitch position.
5. Blend the stored trailer orientation toward that no-side-slip orientation by `TRAILER_LATERAL_RESPONSE`.
6. Ignore the blended angle delta if it is below `TRAILER_ANGLE_DEADZONE_TURNS`.
7. Clamp trailer/tow angle difference to `MAX_HITCH_ANGLE_TURNS`.
8. Reconstruct trailer center from hitch and trailer orientation.
9. Derive the debug axle position from hitch and trailer orientation.

`TRAILER_LATERAL_RESPONSE` is a tire-side-slip resistance approximation. `1.0` means the trailer tries to satisfy the axle no-side-slip constraint immediately. Lower values allow more side drag/slip and smooth the response. Higher values make the trailer rotate toward the axle constraint more aggressively.

The stationary thresholds prevent sub-tile Factorio vehicle settling and tiny floating-point orientation corrections from making the trailer visibly twitch around the hitch after stopping.

The proxy substep target spacing is `0.22` tiles. The step count is based on the larger of center movement and angular sweep at the trailer collision-box half diagonal, capped at `64` substeps per linked trailer per tick to keep UPS cost bounded.

`defines.build_check_type.ghost_revive` is selected for Phase 1 proxy checks because the official runtime API documents `LuaSurface.can_place_entity` as defaulting to `ghost_revive`, while `LuaEntity.teleport` defaults to `script`. Using `ghost_revive` explicitly on both calls keeps the placement pre-check and the actual teleport check aligned.

The head's acceleration, braking, steering, and speed are left to Factorio's native car physics.

## Collision

Phase 1 does not implement full native vehicle impact behavior. The visible trailer cargo prototype uses `collision_mask = {layers = {}}` so its sprite/inventory entity can always stay visually stable and is not hidden by failed collision-checked teleports. Obstacle blocking and incoming damage hit detection are handled by `trailer-cargo-collision-proxy`, an invisible car prototype with the same base-car-equivalent collision mask as the head plus `not_colliding_with_itself=true`.

The visible trailer cargo entity uses the trailer-sized collision box even though its collision mask is empty. This keeps it non-blocking while giving inserters a normal-sized target area for loading and unloading the cargo inventory.

Factorio `collision_box` is a single bounding box and cannot contain a hole. The hidden collision proxy uses the full trailer footprint so the visual front/kingpin area is also covered. Self-collision with the linked head is avoided by giving both prototypes the same linked mask and `not_colliding_with_itself=true`.

The mod's existing forward vector makes local negative Y the forward direction. The collision proxy covers local Y from `-6.0` to `6.0` and includes the entity origin `{0, 0}`.

The values are defined once in `scripts/trailer_geometry.lua` and reused by data-stage prototypes and runtime debug rendering.

Reason: Factorio collision masks are prototype-level. `not_colliding_with_itself=true` applies when both entities have the option and the same collision layers, so this mod gives `trailer-head` and `trailer-cargo-collision-proxy` the same linked-vehicle mask. This cannot express "ignore only this exact linked pair" and may also prevent collision between multiple Trailer MOD vehicle parts that share the same mask. The mask stays otherwise equivalent to vanilla `car`, because vanilla car already collides with trees and buildings through shared `player` / `is_object` layers while still crossing ground rails.

Known limitations:

- Scripted trailer proxy movement may not produce native car impact damage, tree destruction, or vehicle damage.
- Proxy movement is substepped from the last accepted pose to reduce teleport tunneling. If a substep fails, the whole tick is rejected; partial substep progress is not accepted.
- `LuaEntity.teleport` is treated as authoritative for movement. `can_place_entity` is diagnostic only, because in-game testing showed `can_place=false` and `teleport=true` near nearby objects where the proxy could actually move. When debug rendering is enabled, blocked ticks show the failing substep plus both results.
- On proxy movement failure, head movement is rolled back to the last accepted head pose and `head.speed` is set to `0`. In multi-trailer links, proxy movement is atomic across all trailer segments: a failure for any proxy rejects the whole vehicle update and restores every trailer.
- Debug rendering shows a short-lived `Trailer blocked` text when the proxy teleport fails.

Phase 2 should investigate native impact damage and obstacle destruction behavior.

## Save Compatibility

The mod uses `storage`, keeps LuaEntity references only for entities it owns, and rebuilds storage tables with `script.on_init` and `script.on_configuration_changed`. Existing invalid references are cleaned opportunistically.

## Debugging

Runtime debug rendering is controlled with the single local constant `DEBUG_RENDERING` in `scripts/trailer_manager.lua`. When enabled, it draws short-lived rendering objects each tick:

- rotated head collision-box outline in red,
- rotated accepted trailer proxy collision-box outlines in blue,
- rotated rejected target trailer proxy outline in orange when proxy movement is blocked,
- head center in white,
- trailer centers in white,
- hitch positions in yellow,
- trailer axle positions in green,
- per-segment hitch angle text.
- blocked diagnostic text with the failing substep number, build check type, `can_place_entity` result, and `teleport` result.

If debug rendering is turned off, the rendering code does not draw new objects and clears existing rendering objects created by this mod during init/configuration change and the next tick. This keeps the switch available for future testing without leaving stale collision/debug overlays on screen.
