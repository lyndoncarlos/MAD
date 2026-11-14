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

## Known placeholders
Grey-box shapes, no sound, one regular enemy, placeholder XP curve and drop rates.
