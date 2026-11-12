# Spawn tuning (Tiyanak, Chapter 1)

All numbers are **placeholders for playtesting**. Change them in `data/spawn_curves/chapter_01.tres`
(or in the inspector) and re-run the tests; no code changes needed.

## How spawning scales

There are three layers, from the clock to the player:

1. **Time (the curve).** Four waves (Dusk, Night, Midnight, Pre-dawn). Within each wave the spawn rate,
   the alive cap and the pack size ramp smoothly from a start value to an end value.
2. **Player level.** Pressure rises by `level_bonus_per_level` (default +2%) for every level above 1.
3. **Player power (your upgrades).** Pressure rises with the estimated damage per second of your build:
   weapon levels, extra projectiles, new weapons and damage passives all count. Movement and pickup passives
   (Bakya, Sampaguita) do **not** count, because they do not make you kill faster.

```
pressure = 1 + level_bonus_per_level * (level - 1)
             + power_bonus * (sqrt(your_dps / starting_dps) - 1)
pressure is clamped to [min_pressure, max_pressure]   (defaults 1.0 to 2.0)
```
Pressure multiplies **both the spawn rate and the alive cap**. Pack size grows with time only.
The square root means doubling your damage raises pressure far less than double, so getting stronger still
feels good. Set `power_bonus = 0` to scale by level only, or `level_bonus_per_level = 0` to scale by build only.

## The authored curve (pressure 1.0)

| Minute | Events/s | Pack | Tiyanak/s | Alive cap |
|---|---|---|---|---|
| 0:00 | 0.50 | 1 | 0.50 | 10 |
| 3:00 | 0.80 | 1 | 0.80 | 25 |
| 5:00 | 0.92 | 1 | 0.92 | 35 |
| 8:00 | 1.10 | 2 | 2.20 | 50 |
| 10:00 | 1.20 | 2 | 2.40 | 60 |
| 12:00 | 1.30 | 3 | 3.90 | 70 |
| 14:00 | 1.40 | 3 | 4.20 | 80 |
| 17:00 | 1.55 | 4 | 6.20 | 95 |
| 20:00 | 1.70 | 4 | 6.80 | 110 |

An *event* spawns one pack: the Tiyanak in a pack burrow in together, scattered within about 70 px,
each with its own warning mound.

## What pressure looks like for real builds

Baseline is the starting Spirit Staff at about 11.1 dps.

| Build | Est. dps | Pressure |
|---|---|---|
| Level 1, Spirit Staff L1 | 11 | 1.00 |
| Level 5, Staff L3 + Agimat 1 | 16 | 1.11 |
| Level 10, Staff L5 + Asin L2 + Agimat 2 | 51 | 1.35 |
| Level 15, Staff L6 + Asin L4 + Agimat 3 | 64 | 1.49 |
| Level 25, Staff L8 + Asin L8 + Agimat 5 | 128 | 1.84 |
| Level 40, same build | 128 | 2.00 (capped) |

Example at 10:00 with pressure 1.49: about 1.8 events/s, packs of 2, so roughly 3.6 Tiyanak/s, and a cap of about 90.

## How to tune it with the HUD and run logs

The HUD line shows `Alive` (enemies on screen) and `Pressure`. Each run log in `user://run_logs/` records
`peak_alive`, `final_pressure`, `estimated_dps`, `baseline_dps`, time survived and the build.

| If you see | Try |
|---|---|
| Early game feels empty | raise the first wave's start rate or cap |
| You are overwhelmed before minute 8 | lower `end_spawns_per_second` or `end_max_alive` of the Dusk/Night waves |
| Strong builds feel bored | raise `power_bonus` (0.25 to 0.4) or `max_pressure` |
| Strong builds feel punished | lower `power_bonus` or set it to 0 |
| Pure survival time is the problem, not density | change enemy HP/speed instead of spawn rates |
| Packs feel unfair | shorten pack growth (`end_pack_size`) or increase `burrow_telegraph_seconds` |

## Limits of the M1 prototype

- Enemies are plain nodes found with group scans, so the caps are kept modest. The test
  `test_spawn_curve_shape` fails if a wave could exceed 300 alive at max pressure. **M2 raises this** after pooling
  and spatial lookup (target 500 to 800 enemies).
- Only one enemy type exists. When others are added, give each its own waves; the same pressure applies to all.
- The curve data is validated by `test_spawn_curve_shape`: it must start at minute 0, end at the curve duration,
  have no gaps or overlaps, and have no jumps in rate, cap or pack size between waves.
