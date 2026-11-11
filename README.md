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

## M1 Jira stories mapped to files
| Story | Where |
|---|---|
| Weapon system | `scripts/weapons/*`, `scripts/data/weapon_data.gd`, `data/weapons/*` |
| Enemy and spawner v1 | `scripts/entities/enemy.gd`, `scripts/systems/spawn_planner.gd`, `scenes/main.gd` |
| Damage, HP and death | `scenes/heroes/hero.gd`, `scripts/entities/damage_number.gd`, `scripts/entities/projectile.gd` |
| Sinag and level-up | `scripts/entities/sinag_pickup.gd`, `scripts/systems/run_state.gd`, `level_up_pool.gd`, `scripts/ui/level_up_menu.gd`, `data/level_curves/*` |
| Game-over screen | `scripts/ui/game_over_screen.gd` |
| Playtest check #1 | `docs/FUN_CHECK_1.md` |

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
