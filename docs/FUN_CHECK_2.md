# Fun check #2: the full 20-minute run

Play at least two full runs (one seed twice is fine: `-- --seed=12345`). Use `-- --start-minute=N` only to inspect a moment, not to judge pacing.

## Questions to answer
1. **Pacing:** does each phase (Dusk, Night, Midnight, Pre-dawn) feel different? Is any stretch boring or unfair?
2. **Blood Moon:** is filling the meter (100 kills) satisfying? Does the 20 s event feel like a thrill or just noise?
3. **Elites:** do the four Tiyanak Alphas feel like events? Is the chest upgrade worth the detour?
4. **Pickups:** are herbs and the magnet frequent enough to notice but rare enough to feel good?
5. **Win:** can you reach 20:00 alive? Aim for roughly 30 to 50% of runs surviving with a reasonable build.
6. **Performance:** any hitching during Blood Moon or late game? (Benchmark: `docs/PERFORMANCE.md`.)

## Where to tune
| What | File |
|---|---|
| Spawn rates, caps, packs | `data/spawn_curves/chapter_01.tres` |
| Phases, elite minutes, Blood Moon, drop chances | constants at the top of `scripts/systems/run_director.gd` |
| Elite stats | `data/enemies/tiyanak_alpha.tres` |
| Herb heal amount | `HERB_HEAL` in `scenes/main.gd` |

Write the outcome in the Jira Decision ticket in two or three sentences, including what you will change.

## Result (first playtest)
Too easy and dull: everything maxed by about 15:00, 20:00 reached easily, pickups too frequent late, elites too soft.
Changes made: spawn rates about 2x with caps up to 230 alive and bigger packs; Blood Moon spawns 2.0x (was 1.4x);
burrow warnings shorten over the run (up to 2x at 20:00) and a further 1.8x in a Blood Moon; Tiyanak Alpha has 900 HP
(grows 60% per elite), winds up then sprints or leaps; herb and magnet drops about 2.5x rarer and fading to a third
by 20:00; rare big Sinag gem (0.4%); level curve steeper (`linear_per_level` 4, `quad_per_level` 0.45).
Needs a second playtest to check the new difficulty.

## Known placeholders
Grey-box shapes, no sound, one regular enemy, placeholder XP curve and drop rates.
