# War Rig Transport SPEC

This document describes the current implementation of **War Rig Transport** for Factorio 2.0.

The public-facing overview belongs in `README.md`. This file is for implementation details, prototype names, runtime state, tuning values, collision behavior, save compatibility, and regression testing.

---

## 1. Scope

War Rig Transport currently provides two independent transport systems.

### Road Trailers

Free-driving vehicle consists built from a normal Factorio `car` head plus scripted trailer entities:

- `Semi-Trailer`: one head + one cargo trailer
- `Double-Trailer`: one head + two cargo trailers
- `Triple-Trailer`: one head + three cargo trailers

The player drives only the head. Trailer positions and orientations are calculated at runtime.

### Rail War Rig

Standard Factorio rolling stock using War Rig visuals:

- locomotive
- cargo wagon
- fluid wagon
- road-styled rail planner and rail prototypes

Rail War Rig does not use the road-trailer runtime physics system.

### Explicitly out of scope

The current implementation does not provide:

- manual trailer coupling or uncoupling
- standalone road-trailer placement as a supported user feature
- road/rail mode conversion
- road fluid trailers
- tank trailers
- autonomous road driving
- custom train schedules or stations
- native physical joints between road vehicles
- perfect reproduction of native car impact/tree-destruction behavior for scripted trailers

---

## 2. Mod identity

`info.json`:

- Mod ID: `War_Rig_Transport`
- Display title: `War Rig Transport`
- Factorio version: `2.0`
- Dependency: `base >= 2.0`

All internal asset paths use the Factorio mod path prefix:

```text
__War_Rig_Transport__/
```

Existing prototype names still use the original `trailer-*` identifiers. These should not be renamed without a deliberate save-compatibility plan.

---

## 3. Source and asset references

The implementation references assets and behavior from:

- `Reference/kj_warrig_2.1.0`
- `Reference/kj_vehicles_2.1.11`
- `Reference/trailer_simu`

### Reused War Rig assets

War Rig body sprites:

- `graphics/entity/warrig/warrig_0.png` through `warrig_15.png`
- `graphics/entity/warrig/warrig_shadow_0.png`
- `graphics/entity/warrig/warrig_shadow_1.png`

Trailer sprites:

- `graphics/entity/trailer/warrig_trailer_0.png` through `warrig_trailer_7.png`
- `graphics/entity/trailer/warrig_trailer_shadow_0.png` through `warrig_trailer_shadow_7.png`

Icons / technology / minimap assets:

- `graphics/icon/icon.png`
- `graphics/icon/train.png`
- `graphics/icon/wagon.png`
- `graphics/icon/wagon_fluid.png`
- `graphics/technology/technology.png`
- `graphics/map_symbol/map_symbol.png`
- `graphics/map_symbol/map_symbol_selected.png`
- `graphics/map_symbol/wagon_map_symbol.png`
- `graphics/map_symbol/wagon_map_symbol_selected.png`

Sounds:

- `sounds/brakes.ogg`
- `sounds/door-close.ogg`
- `sounds/engine-fail.ogg`
- `sounds/engine-start.ogg`
- `sounds/engine-stop.ogg`
- `sounds/engine.ogg`

Road rail artwork from `kj_vehicles`:

- `graphics/entity/rail/road.png`
- `graphics/entity/rail/roads.png`

Licensing and upstream attribution are documented in `LICENSE` and `THIRD_PARTY_LICENSES.md`.

---

## 4. Road Trailer prototypes

### 4.1 `trailer-head`

Display name: `Semi-Trailer`

Type: `car`

Base prototype:

```lua
data.raw.car.car
```

Current tuning:

```text
effectivity          = 0.7
consumption          = 2500kW
braking_power        = 400kW
friction             = 0.0015
rotation_speed       = 0.01
rotation_snap_angle  = 0.015
weight               = 20000
inventory_size       = 20
```

Geometry:

```text
collision_box = {{-1.0, -3.2}, {1.0, 3.2}}
selection_box = {{-1.2, -3.6}, {1.2, 3.6}}
```

Other behavior:

- normal Factorio car driving
- normal base-car burner fuel behavior
- no guns
- War Rig graphics and sounds
- War Rig minimap representation
- black exhaust smoke from two rear positions

### 4.2 `double-trailer-head`

Display name: `Double-Trailer`

Deep copy of `trailer-head` with the same driving configuration except:

```text
weight = 32000
```

Automatically creates two trailer segments.

### 4.3 `triple-trailer-head`

Display name: `Triple-Trailer`

Deep copy of `trailer-head` with the same driving configuration except:

```text
weight = 44000
```

Automatically creates three trailer segments.

### 4.4 `trailer-cargo`

Type: `car`

Purpose:

- visible trailer body
- independent cargo inventory
- player/inserter interaction target
- visible health target

Current values:

```text
inventory_size = 100
weight         = 4000
collision_box  = {{-1.4, -6.0}, {1.4, 6.0}}
selection_box  = {{-1.62, -6.24}, {1.62, 2.4}}
```

Its collision mask is intentionally empty. The visible trailer is not responsible for obstacle blocking.

The entity uses a void energy source and negligible movement parameters because runtime code controls its position.

Players are not allowed to drive it.

### 4.5 `trailer-cargo-collision-proxy`

Type: `car`

Purpose:

- invisible obstacle collision body
- damage relay for the visible trailer

Properties:

- hidden
- not on map
- not blueprintable
- not deconstructable
- not selectable
- not minable
- invisible animation
- `max_health = 1000000`
- same full trailer collision box as `trailer-cargo`
- same linked-vehicle collision mask as the head

The proxy is deliberately separate from the visible cargo entity so the visible trailer can remain stable for inventory and player interaction while scripted movement uses the proxy for blocking.

---

## 5. Collision masks and geometry

Defined in `scripts/trailer_geometry.lua`.

### Empty visible-trailer mask

```lua
{layers = {}}
```

### Linked vehicle mask

```lua
{
  layers = {
    player = true,
    car = true,
    train = true,
    is_object = true
  },
  consider_tile_transitions = true,
  not_colliding_with_itself = true
}
```

This intentionally stays close to the base car mask.

`not_colliding_with_itself=true` is used so the scripted linked vehicle pieces do not block each other. Because collision masks are prototype-level, this is not an exact per-consist exclusion and may also affect interactions between multiple War Rig Transport consists that use the same mask.

Do not add arbitrary `rail`, `item`, `object`, `water_tile`, `is_lower_object`, or `elevated_rail` layers without verifying the resulting in-game behavior. The road head is expected to cross ordinary ground rails like a vanilla car.

---

## 6. Road Trailer kinematics

Defined in `scripts/trailer_physics.lua`.

Current constants:

```text
HEAD_TO_HITCH_DISTANCE                 = 3.08
TRAILER_AXLE_TO_HITCH_DISTANCE         = 8.94
TRAILER_CENTER_TO_HITCH_DISTANCE       = 5.52
TRAILER_CENTER_TO_REAR_HITCH_DISTANCE  = 5.52
TRAILER_LATERAL_RESPONSE               = 0.95
MAX_HITCH_ANGLE_TURNS                  = 0.25
STATIONARY_HEAD_SPEED_THRESHOLD        = 0.002
STATIONARY_HITCH_MOVEMENT_THRESHOLD    = 0.002
TRAILER_ANGLE_DEADZONE_TURNS           = 0.0002
```

Factorio orientation is expressed in turns:

```text
0.00 = north
0.25 = east
0.50 = south
0.75 = west
```

Forward vector:

```lua
{
  x = math.sin(orientation * math.pi * 2),
  y = -math.cos(orientation * math.pi * 2)
}
```

### Per-segment solver

Each trailer segment receives a tow state containing:

```text
hitch position
tow orientation
tow speed
```

The solver:

1. obtains the current towing hitch position;
2. reconstructs the previous trailer axle position;
3. computes the direction from axle to hitch;
4. converts that direction into a no-side-slip target orientation;
5. applies `TRAILER_LATERAL_RESPONSE`;
6. ignores very small angle changes through the deadzone;
7. clamps articulation to ±90 degrees relative to the immediate towing segment;
8. rebuilds the trailer center from the hitch and trailer orientation.

For Double and Triple variants, Trailer B follows Trailer A's rear hitch, and Trailer C follows Trailer B's rear hitch. They do not follow the head directly.

Conceptually:

```text
HEAD
  -> Trailer A
       -> Trailer B
            -> Trailer C
```

The same solver is reused for all segments.

---

## 7. Runtime storage

Persistent linkage is stored in `storage`.

Current top-level structures:

```lua
storage.trailers
storage.trailers_by_trailer_unit_number
storage.trailers_by_proxy_unit_number
storage.debug_rendering_cleared
```

Logical link shape:

```lua
storage.trailers[head_unit_number] = {
  variant = "single" or "double" or "triple",
  head = LuaEntity,
  accepted_head_position = ...,
  accepted_head_orientation = ...,
  trailers = {
    {
      trailer = LuaEntity,
      collision_proxy = LuaEntity,
      previous_hitch_position = ...,
      trailer_orientation = ...,
      accepted_hitch_position = ...,
      accepted_trailer_position = ...,
      accepted_trailer_orientation = ...
    },
    ...
  }
}
```

Reverse lookup tables map visible trailer and proxy `unit_number` values back to the owning head.

### Save migration

`migrate_link_shape()` upgrades the earlier single-trailer storage shape into the current `trailers[]` segment array.

Existing prototype names are deliberately retained to avoid unnecessary save breakage.

---

## 8. Runtime lifecycle

### Creation

When a supported road head is built:

1. determine the segment count from the head prototype;
2. calculate the first hitch behind the head;
3. create Trailer A and its proxy;
4. derive the rear hitch of Trailer A;
5. repeat for B/C as required;
6. register the completed link in `storage`.

If any segment creation fails, already-created segments are destroyed and no partial link is registered.

### Tick update

For each valid link:

1. validate the head and segments;
2. ensure each trailer has a collision proxy;
3. ensure all linked entities remain on the same surface;
4. compute target states for all trailer segments;
5. move collision proxies toward target poses using substeps;
6. only if all required proxy movements succeed, move visible trailers and accept the new state;
7. if any proxy movement fails, restore the last accepted head/trailer state and stop the head.

### Atomic movement

Multi-trailer consists are treated atomically. A failure in Trailer B or C rejects the entire update.

No partial accepted pose is kept.

---

## 9. Collision proxy movement

Runtime constants:

```text
MAX_PROXY_SUBSTEP_DISTANCE = 0.22
MAX_PROXY_SUBSTEPS         = 64
build_check_type           = defines.build_check_type.ghost_revive
```

Proxy motion is interpolated in both position and orientation.

Each substep uses:

- `LuaSurface.can_place_entity(...)` for diagnostics/pre-check information;
- `LuaEntity.teleport(..., defines.build_check_type.ghost_revive)` as the authoritative movement result.

If teleport fails:

- proxy returns to its previous accepted pose;
- the whole consist restores its accepted state;
- head speed is set to zero.

This reduces teleport tunneling through obstacles while preserving the existing scripted-trailer architecture.

---

## 10. Damage handling

The visible trailer is the authoritative player-facing health entity.

The hidden proxy receives physical collision/damage interactions and relays damage to the corresponding `trailer-cargo`.

Runtime behavior:

1. `on_entity_damaged` receives damage on the proxy;
2. lookup resolves the owning trailer segment;
3. `event.final_damage_amount` is subtracted from the visible trailer health;
4. if the visible trailer survives, proxy health is restored to `PROXY_MAX_HEALTH`;
5. if the visible trailer reaches zero health, the whole linked road consist is removed.

This avoids exposing the invisible proxy as the meaningful health object.

---

## 11. Removal and destruction

Road trailers are one logical consist even though they are multiple Factorio entities.

Relevant events include:

- `on_player_mined_entity`
- `on_robot_mined_entity`
- `on_entity_died`
- `script_raised_destroy`

### Mining

Mining events provide an inventory buffer.

The runtime code uses that buffer to manage linked head/trailer inventory contents and suppress the internal hidden trailer item where appropriate.

The intended user-visible result is that mining a visible road-consist part removes the logical consist rather than leaving stale linked entities.

This area must be regression-tested after any lifecycle change because the game first processes the entity that generated the mining event while the script removes the remaining linked entities.

### Destruction

Destroy/death paths do not have a mining buffer. Linked entities are removed without returning linked inventories.

---

## 12. Debug rendering

Defined in `scripts/trailer_manager.lua`.

Default:

```lua
DEBUG_RENDERING = false
```

When enabled, debug rendering can show:

- head collision box
- trailer collision boxes
- target blocked pose
- head/trailer centers
- hitch positions
- trailer axle positions
- articulation angle
- blocked movement diagnostics

When disabled, previously created rendering for this mod is cleared once.

Debug rendering is a development tool and is not intended as a player-facing feature.

---

## 13. Rail War Rig prototypes

Rail implementation is defined in `prototypes/rail.lua` and uses normal Factorio rolling stock.

It does not register with `trailer_manager.lua`.

### 13.1 `trailer-rail-locomotive`

Display name: `Rail War Rig`

Type: `locomotive`

Base prototype:

```lua
data.raw.locomotive.locomotive
```

Current values:

```text
collision_box            = {{-1.0, -3.2}, {1.0, 3.2}}
selection_box            = {{-1.2, -3.6}, {1.2, 3.6}}
connection_distance      = 3
joint_distance           = 5
weight                   = 2000
max_speed                = 1.2
max_power                = 600kW
braking_force            = 10
reversing_power_modifier = 0.6
friction_force           = 0.50
air_resistance           = 0.0075
```

It keeps the base locomotive burner/fuel behavior and therefore uses ordinary locomotive fuel.

War Rig graphics, minimap assets, and engine/brake sounds are applied.

### 13.2 `trailer-rail-cargo-wagon`

Display name: `Rail Cargo Trailer`

Type: `cargo-wagon`

Current values:

```text
inventory_size       = 100
collision_box        = {{-0.8, -3.4}, {0.8, 3.4}}
selection_box        = {{-1.1, -3.8}, {1.1, 3.8}}
connection_distance  = 3
joint_distance       = 5
weight               = 1000
max_speed            = 1.5
braking_force        = 3
friction_force       = 0.50
air_resistance       = 0.01
```

Uses the same trailer artwork as the road cargo trailer.

### 13.3 `trailer-rail-fluid-wagon`

Display name: `Rail Fluid Trailer`

Type: `fluid-wagon`

Current values:

```text
capacity = 50000
```

Geometry and rolling-stock movement values are copied from `trailer-rail-cargo-wagon`.

Uses standard Factorio fluid-wagon mechanics and pumps.

---

## 14. Road rails

User-facing rail planner prototype:

```text
trailer-road-rails
```

Underlying rail prototypes:

```text
trailer-road-rail-straight
trailer-road-rail-half-diagonal
trailer-road-rail-curved-a
trailer-road-rail-curved-b
```

These use Factorio 2.x rail prototype types:

- `straight-rail`
- `half-diagonal-rail`
- `curved-rail-a`
- `curved-rail-b`

They use road artwork from `kj_vehicles` but remain standard rails from the train system's point of view.

Consequences:

- Rail War Rig can run on normal Factorio rails.
- Normal rolling stock can run on Road rails.
- Road rails do not create a separate rail network type.
- No runtime script is needed for train movement.

Road rail recipe:

```text
stone-brick ×5
concrete ×3
water ×100
```

---

## 15. Items and recipes

### Road items

```text
trailer-head         -> Semi-Trailer
double-trailer-head  -> Double-Trailer
triple-trailer-head  -> Triple-Trailer
```

Internal hidden item:

```text
trailer-cargo
```

Road recipes:

```text
Semi-Trailer:
  engine-unit ×8
  iron-gear-wheel ×20
  steel-plate ×20

Double-Trailer:
  engine-unit ×12
  iron-gear-wheel ×30
  steel-plate ×30

Triple-Trailer:
  engine-unit ×16
  iron-gear-wheel ×40
  steel-plate ×40
```

### Rail items

Rail rolling-stock items use `item-with-entity-data` and stack size 5.

Rail recipes:

```text
Rail War Rig:
  engine-unit ×30
  electronic-circuit ×15
  steel-plate ×45

Rail Cargo Trailer:
  iron-gear-wheel ×15
  iron-plate ×30
  steel-plate ×30

Rail Fluid Trailer:
  iron-gear-wheel ×15
  steel-plate ×24
  pipe ×12
  storage-tank ×2
```

---

## 16. Technologies

Technology icon:

```text
graphics/technology/technology.png
```

### `trailer-head`

Display name: `Semi-Trailer`

```text
prerequisite: automobilism
cost: 100 automation + logistic science packs
unlock: trailer-head
```

### `double-trailer-head`

Display name: `Double-Trailer`

```text
prerequisite: trailer-head
cost: 200 automation + logistic science packs
unlock: double-trailer-head
```

### `triple-trailer-head`

Display name: `Triple-Trailer`

```text
prerequisite: double-trailer-head
cost: 300 automation + logistic science packs
unlock: triple-trailer-head
```

### `trailer-rail-war-rig`

Display name: `Rail War Rig`

```text
prerequisites:
  automated-rail-transportation
  fluid-wagon

cost:
  250 automation + logistic science packs

unlocks:
  trailer-rail-locomotive
  trailer-rail-cargo-wagon
  trailer-rail-fluid-wagon
  trailer-road-rails
```

On init/configuration change, runtime code synchronizes these recipe unlocks with the researched technology state so older development saves do not retain previously always-enabled test recipes.

---

## 17. Event registration

`control.lua` registers road runtime handling for:

```text
on_init
on_configuration_changed
on_built_entity
on_robot_built_entity
script_raised_built
script_raised_revive
on_player_mined_entity
on_robot_mined_entity
on_entity_died
script_raised_destroy
on_entity_damaged
on_player_driving_changed_state
on_tick
```

Rail War Rig does not require custom runtime train movement events.

---

## 18. Known limitations

- Road trailers are scripted, not native articulated cars.
- Proxy movement may not reproduce native car impact damage or tree destruction exactly.
- Trailer entity mass does not physically add to the head entity. Different head weights approximate Semi/Double/Triple consist mass.
- `not_colliding_with_itself` is prototype-level, not per-consist.
- Visible trailers use an empty collision mask by design; obstacle blocking comes from the proxy.
- Every active road consist is updated on `on_tick`; performance should be re-evaluated if large numbers of road trailers are expected.
- Rail visual geometry is tuned around the War Rig/trailer sprites and standard rail mechanics; extreme modded rail geometry may expose visual gaps or overlap.

---

## 19. Required in-game regression tests

Do not claim these tests passed unless Factorio was actually launched and the behavior was observed.

### Semi-Trailer

- place head and verify one trailer/proxy pair is created
- drive straight
- left turn
- right turn
- sustained circle
- reverse straight
- reverse while articulated
- stop and verify no visible idle jitter
- reach maximum articulation
- collide Trailer A with tree/wall/building and verify rollback
- load/unload trailer inventory with inserters
- inspect trailer inventory manually
- damage trailer side/front/rear and verify visible trailer health changes
- destroy trailer and verify the logical consist does not leave orphan entities
- mine the head with cargo/fuel present and verify expected item return behavior
- mine the visible trailer with cargo present and verify expected whole-consist cleanup/return behavior

### Double-Trailer

- verify two independent trailer inventories
- verify Trailer B follows Trailer A rather than the head
- verify inner tracking through turns
- reverse with both joints articulated
- collide Trailer A and verify atomic rollback
- collide Trailer B and verify atomic rollback
- destroy/mine A or B and verify no orphan segment/proxy/storage remains

### Triple-Trailer

- verify three trailer segments and three proxies
- verify C follows B
- long forward turn
- reverse with multiple articulation angles
- collision failure on A/B/C must reject the whole consist update
- verify all three inventories remain independent
- mine/destroy each visible segment in separate tests and check cleanup

### Save compatibility

- load a save created with the earlier single-trailer storage shape
- trigger `on_configuration_changed`
- confirm old links migrate into `trailers[]`
- confirm existing Semi/Double/Triple consists remain usable
- confirm recipe enable state matches researched technologies

### Rail War Rig

- place locomotive/cargo/fluid wagon on normal rails
- place them on Road rails
- connect Rail War Rig to vanilla wagons
- connect vanilla locomotive to Rail Cargo/Fluid Trailer
- manual driving
- automatic train schedule
- forward and reverse
- curves and junctions
- train stops and signals
- coal / solid fuel / rocket fuel / nuclear fuel compatibility where supported by vanilla locomotive fuel rules
- inserter loading/unloading of Rail Cargo Trailer
- pump loading/unloading of Rail Fluid Trailer
- verify cargo capacity = 100 slots
- verify fluid capacity = 50000
- inspect sprite spacing on straight and curved rails

---

## 20. Change discipline

When modifying this project:

- use Factorio 2.0 APIs only;
- verify exact prototype/event names from source or official documentation;
- keep data-stage and runtime-stage responsibilities separate;
- preserve current prototype names unless a migration is explicitly planned;
- preserve persistent runtime state compatibility;
- keep GUI/player state per player if GUI features are ever added;
- prefer event-driven processing where practical;
- do not modify unrelated files;
- preserve third-party license and attribution information;
- use locale keys for user-visible strings;
- review the complete diff before reporting completion;
- check Lua syntax, require paths, prototype identifiers, multiplayer implications, and save compatibility;
- list required in-game tests;
- never claim in-game testing unless Factorio was actually launched.
