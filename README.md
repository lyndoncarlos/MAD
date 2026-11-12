# Mga Alamat ng Dilim: M1 Core Loop

Godot 4 project, milestone M1. Builds on M0 (data, seeded RNG, hero, logger) and adds the
core loop: **kill → Sinag drops → pick up → level up → choose an upgrade → repeat → die → retry**.

## Requirements
- Godot **4.3 or newer** (standard build, no .NET). Latest stable is fine.
- Git and [Git LFS](https://git-lfs.com) (`git lfs install` once per machine)

## Quick start
1. Open `project.godot` in Godot and let the first import finish.
2. Press **F5**. Output should show `[DataRegistry] loaded 9 data files, 0 problems`.
3. Move with **WASD / arrows / gamepad stick**. Tala (yellow) fires the Spirit Staff automatically.
4. Kill red Tiyanak, walk over the teal Sinag shards, and pick upgrades on level-up
   (**1 / 2 / 3**, click, or gamepad). Try taking **Asin** (orbiting salt) as a second weapon.
5. When you die: **R** retries the same seed, **N** starts a new run.

**Fixed seed:** `godot --path . -- --seed=12345` (in the editor: Project Settings → Run → Main Run Args → `-- --seed=12345`).
Run logs go to `user://run_logs/` (Editor: **Project → Open User Data Folder**).

## Run the tests
```
godot --headless --import                                 # once, registers class_name scripts
godot --headless --script res://tests/run_tests.gd
```
| Suite | What it checks |
|---|---|
| `test_rng_determinism` | same seed gives the same sequence; streams are independent; seed derivation is pinned |
| `test_data_validation` | shipped data is valid; the validator catches bad ids, missing references, duplicates |
| `test_conventions` | files and folders are lowercase snake_case |
| `test_run_state` | XP curve values, level-up rules, multi-level pickups, passive stacking |
| `test_level_up_pool` | 3 unique options, no maxed items, slot cap, reproducible from a seed, heal fallback |
| `test_spawn_planner` | spawn rate follows the curve, alive cap respected, quiet outside wave windows |
| `test_weapon_math` | damage and projectile-count scaling per level |
| `test_enemy_motion` | the Tiyanak burst starts fast, ends at normal speed, never speeds up again |
| `test_spawn_planner` | spawn rate, ramps, packs, alive caps, pressure scaling, wave windows |
| `test_spawn_pressure` | pressure rises with level and build strength, is clamped, handles bad inputs |
| `test_weapon_dps` | DPS estimates count damage upgrades and ignore movement/pickup passives |
| `test_spawn_curve_shape` | the shipped spawn curve has no gaps, jumps or cap blow-ups |

## M1 Jira stories mapped to files
| Story | Where |
|---|---|
| Weapon system | `scripts/weapons/*`, `scripts/data/weapon_data.gd`, `data/weapons/*` |
| Enemy and spawner v1 | `scripts/entities/enemy.gd`, `scripts/systems/spawn_planner.gd`, `scenes/main.gd` |
| Damage, HP and death | `scenes/heroes/hero.gd`, `scripts/entities/damage_number.gd`, `scripts/entities/projectile.gd` |
| Sinag and level-up | `scripts/entities/sinag_pickup.gd`, `scripts/systems/run_state.gd`, `level_up_pool.gd`, `scripts/ui/level_up_menu.gd`, `data/level_curves/*` |
| Game-over screen | `scripts/ui/game_over_screen.gd` |
| Playtest check #1 | `docs/FUN_CHECK_1.md` |

## Tiyanak behaviour (burrow, burst, chase)
A Tiyanak does not walk in from off-screen. It appears as a dirt mound 200-420 px from you and
**warns for 0.9 s** (harmless and untargetable while burrowed). It then **lunges in a locked direction**
at 3.5x speed, easing back to normal speed over 0.7 s, and chases from there.
Because the direction is locked when it emerges, a moving player can dodge the lunge.

All of it is data in `data/enemies/tiyanak.tres`, so other enemies can reuse it:
`spawn_style` (RING or BURROW), `burrow_min_distance`, `burrow_max_distance`, `burrow_telegraph_seconds`,
`emerge_speed_mult`, `emerge_burst_seconds`. Set `spawn_style = 0` for the old walk-in behaviour.

## Spawn scaling
Spawn rate, alive cap and pack size ramp over time, and pressure (level plus the estimated damage of your
upgrades) scales rate and cap. The HUD shows `Alive` and `Pressure`; run logs record peaks for tuning.
See `docs/SPAWN_TUNING.md` for the formula, tables and a tuning guide.

## What is deliberately simple (M2 fixes it)
- Enemies, projectiles and pickups are plain nodes found with `get_nodes_in_group`. This is fine for dozens, **not** hundreds.
  M2 adds pooling and spatial lookup. Do not judge performance yet.
- One enemy type, flat spawn rates, placeholder XP curve, no run end at 20:00, no sound, grey-box art.
- Enemies overlap each other (no separation yet).

## Known limits (honest status)
- Written without access to the Godot editor, so **not yet run**. Run the test suite first; expect to fix small things.
- Tuning numbers (HP, speeds, damage, XP, spawn rates) are placeholders to be set by playtesting.
- The editor may rewrite `.tres`/`.tscn` files and add `.uid` files on first save. Commit them.

## Next (M2)
20-minute spawn curve, elites and pickups, enemy pooling and separation, 500/800-enemy benchmarks, full HUD, Fun check #2.
