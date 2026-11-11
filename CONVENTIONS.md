# Naming and structure conventions

These follow Godot 4's official style so the editor and community examples line up.
`tests/test_conventions.gd` enforces the file and folder rules; `DataValidator` enforces the data rules.

## Files and folders
- Lowercase `snake_case`, ASCII only, for every file and folder: `white_lady.tscn`, `chapter_01_balete.tscn`.
- Folklore names in ASCII: `sulo`, not `Sulô`. The proper spelling lives in `display_name` inside the data file.
- A scene and its script share a name and sit in the same folder: `hero.tscn` + `hero.gd`.
- Node names inside scenes use `PascalCase`: `HitBox`, `SpriteBody`.

## Folder layout
```
res://
  scenes/       one folder per kind: heroes/ enemies/ bosses/ weapons/ pickups/ ui/ maps/
                (each scene's script lives next to it)
  scripts/
    core/       RNG, run logger, input setup
    data/       data classes (HeroData...), loader, validator, registry
    systems/    pure rules and planners (RunState, LevelUpPool, SpawnPlanner, Targeting)
    entities/   code-built game objects (Enemy, Projectile, SinagPickup, DamageNumber)
    weapons/    weapon behaviours (WeaponBase and one class per pattern)
    ui/         code-built UI (Hud, LevelUpMenu, GameOverScreen) until real UI scenes exist in M6
    tools/      editor/dev helpers
  data/         .tres files only: heroes/ weapons/ enemies/ upgrades/ spawn_curves/ level_curves/
  art/          sprites/ ui/ vfx/
  audio/        music/ sfx/
  tests/        test_*.gd + run_tests.gd
```
Heroes are data-driven: one `hero.tscn`, and `data/heroes/tala.tres` supplies the identity. Do the same for enemies and weapons where possible, and make a dedicated scene only when behaviour truly differs (bosses).

## GDScript
| Thing | Style | Example |
|---|---|---|
| Class (`class_name`) | PascalCase | `WhiteLady`, `HeroData` |
| Autoload | PascalCase | `RngService`, `DataRegistry` |
| Functions, variables | snake_case | `apply_damage`, `current_hp` |
| Constants, enum values | CONSTANT_CASE | `MAX_ENEMIES`, `Lineage.HUNTER` |
| Signals | snake_case, past tense | `enemy_died`, `level_up_chosen` |
| Private members | leading underscore | `_cooldown_timer` |

- Use type hints everywhere: `var speed: float = 120.0`.
- Indent with tabs (see `.editorconfig`).
- **Never call `randf()`, `randi()` or `randomize()` in gameplay code.** Use `RngService` with a named stream (`RunRng.SPAWN`, `LOOT`, `LEVELUP`, `COMBAT`, `MISC`). That keeps runs reproducible from a seed.

## Data files (.tres)
- One entry per file, in the folder for its type.
- `id` equals the file name without extension, is snake_case, and **never changes once referenced** (saves, run logs, evolution recipes).
- Prefix to avoid clashes if needed: `passive_agimat`, `weapon_asin`.
- `display_name` holds the proper spelling and may use diacritics.
- `source` records which people/tradition it comes from (feeds the Aklat ng mga Nilalang and cultural review).
- `schema_version` starts at 1; bump it when a data class changes in a breaking way.
- Cross-references use ids (`starting_weapon_id = &"spirit_staff"`), never file paths.

## Assets
| Type | Pattern | Example |
|---|---|---|
| Sprite sheet | `{entity}_{state}.png` | `tiyanak_walk.png` |
| Animation frame | `{entity}_{state}_{nn}.png` | `tala_idle_01.png` |
| VFX | `vfx_{name}.png` | `vfx_smoke_puff.png` |
| UI icon | `icon_{name}.png` | `icon_insenso.png` |
| Music stem | `mus_{chapter}_{layer}.ogg` | `mus_ch1_drums.ogg` |
| Sound effect | `sfx_{action}.wav` | `sfx_kalampag_hit.wav` |

## Physics layers (named in project.godot)
1 hero, 2 enemies, 3 pickups, 4 walls, 5 hero_attacks, 6 enemy_attacks.

## Input actions
`move_left`, `move_right`, `move_up`, `move_down` (registered in `InputSetup`). Add new actions there, `snake_case`, verb first.

## Localization keys
`category.id.field`, e.g. `weapon.insenso.name`, `weapon.insenso.desc`. Set this up early so Tagalog/Ilocano translations don't force renames.

## Git and Jira
- Branches: `MAD-<number>-short-description`, e.g. `MAD-12-seeded-rng`.
- Start commit messages with the Jira key: `MAD-12 Add seed display to HUD`.
- Never commit `.godot/` (already in `.gitignore`).
