# AGENTS.md

## Project

Factorio 2.0 mod written in Lua.

Before making changes, inspect `info.json`, the existing source files,
and relevant dependency mod source.

## Additional Rules

Read `SPEC.md` before implementing any feature.

Do not implement behavior that contradicts SPEC.md.

If SPEC.md is ambiguous,
stop and report the ambiguity instead of making assumptions.

When supporting another mod,
inspect the source code under `reference/` first.
Never guess prototype names.

Do not silently skip unsupported prototypes.
Report them in the implementation summary.

Before implementing a new feature or changing existing behavior,
update `SPEC.md` first so that it describes the intended behavior.

Treat `SPEC.md` as the source of truth for project behavior and architecture.

Implementation must follow the updated `SPEC.md`.

If a requested change conflicts with the current `SPEC.md`,
update `SPEC.md` as part of the change before modifying source code.

Do not introduce new user-visible behavior, architecture, entities,
technologies, recipes, logistics rules, or persistent state that are not
described in `SPEC.md`.

Bug fixes that only restore behavior already described in `SPEC.md`
do not require a specification change.

After implementation, verify that `SPEC.md` and the actual implementation
still agree. Report any remaining mismatch.

## Rules

- Use only Factorio 2.0 APIs.
- Keep data-stage and runtime-stage code separated.
- Never invent prototype names, event names, GUI names, signals,
  or remote interfaces. Verify them from source.
- Preserve save compatibility.
- Use `storage` for persistent runtime state.
- Keep GUI state per player.
- Prefer event-driven processing over `on_tick`.
- Do not modify unrelated files.
- Do not add dependencies without explanation.
- Preserve third-party licenses and attribution.
- Use locale keys for user-visible text.

## Verification

After changes:

- review the complete diff
- check Lua syntax
- check `require()` paths
- check exact Factorio API and prototype identifiers
- check multiplayer and save compatibility
- list required in-game tests

Do not claim in-game testing unless Factorio was actually launched.

## Response

Report:

- changed files
- implemented behavior
- verification performed
- unresolved risks
