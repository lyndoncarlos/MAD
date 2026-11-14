# Performance (M2 gate: 800 enemies at a stable frame rate)

**Gate (all three must hold at 800 enemies):**
- average **55 FPS or better**
- 99th-percentile frame time of **25 ms or less** (no regular hitching)
- **simulation speed of 0.95 or more** (the game runs in real time, not slow motion)

The benchmark prints PASS or FAIL against these.

## Run the benchmark
From the project folder (use your own path to the Godot console executable):
```
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=500 --seconds=20 --auto-quit
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=800 --seconds=20 --auto-quit
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=1200 --seconds=20 --auto-quit
```
Or open `scenes/benchmark/benchmark.tscn` in the editor and press **F6** (500 enemies by default).

- A god-mode hero with a maxed Spirit Staff and Asin fights a constant horde of N Tiyanak (they respawn as they die).
- The first 3 seconds are warm-up and are not measured.
- Fixed seed (12345), so runs are comparable between code changes.
- **Vsync is off** by default so the result shows real headroom. Add `--vsync` to turn it on.
- Run it in a **window with rendering**. A headless run skips drawing and will look far better than reality.
- Close other heavy programs, plug in a laptop, and run each setting twice; use the worse result.

Results print to the Output panel and are saved to `user://benchmarks/` (Editor: Project, Open User Data Folder).

## Results so far
Machine: Windows, NVIDIA GTX 1660 SUPER, Godot 4.7.2, gl_compatibility, vsync off.

| Build | Enemies | Avg FPS | p99 ms | Max ms | Sim speed | Verdict |
|---|---|---|---|---|---|---|
| First M2 drop | 500 | 251.3 | 6.22 | 16.56 | not measured | PASS |
| First M2 drop | 800 | 35.0 | 68.18 | 80.47 | not measured | **FAIL** |
| Optimisation pass | 800 | 213.0 | 6.82 | 10.09 | 0.999 | **PASS** (manager 3.96 ms avg) |
| Optimisation pass | 1200 | 109.0 | 13.84 | 19.12 | 0.999 | PASS (manager 6.18 ms avg) |

### Why 800 failed so badly while 500 was fine
1.6x the enemies made frames about 7x slower. That is a cliff, not a gentle slope. Godot's physics runs in fixed
ticks (60 per second, 16.7 ms each). If a tick takes longer than 16.7 ms, the engine runs extra ticks to catch up,
each of which is also too slow, so frame time snowballs. The enemy update runs in the physics tick, so once it
crossed the budget, everything fell apart at once. The old frame-time counters in this benchmark were unreliable,
so the first drop could not show where the time went.

## What the numbers mean
| Metric | Meaning |
|---|---|
| `avg_fps` | average frames per second |
| `p95_frame_ms` / `p99_frame_ms` | 95% / 99% of frames were faster than this. High p99 means visible hitching even if the average looks fine |
| `max_frame_ms` | the single worst frame |
| `sim_speed_ratio` | physics ticks that ran divided by ticks that should have run. 1.0 is real time; 0.5 is half-speed slow motion |
| `avg_ms_manager_total` / `max_ms_manager_total` | time the whole enemy update takes per physics tick. **Must stay well under 16.7 ms**; aim for under 8 ms at 800 enemies, because weapons, the hero and the engine also need time |
| `avg_ms_enemy_update` | moving every enemy and checking contact |
| `avg_ms_separation` | pushing overlapping enemies apart |
| `avg_ms_release` | recycling dead enemies into the pool |
| `avg_ms_grid_rebuild` | rebuilding the spatial grid (runs every 2nd tick, so the average is about half the per-rebuild cost) |
| `enemy_nodes_created` | stays at about the target once the pool is warm. If it keeps growing, pooling is broken |

## What changed in the optimisation pass
1. **Flat grid.** The spatial grid no longer uses a Dictionary of Arrays. Cells are linked lists in packed arrays, so
   rebuilding and querying allocate nothing and do no Dictionary lookups.
2. **Separation on packed arrays.** It reads positions and radii from packed arrays rather than properties of each
   enemy object (much faster in GDScript), and handles half of the enemies per tick, with proportionally stronger pushes.
3. **Cheaper bookkeeping.** Alive counts are kept incrementally (they were recounted by looping every enemy several times
   per frame), the dead-enemy sweep only runs when something died, and the grid is rebuilt every 2nd tick.
4. **No snowball.** `max_physics_steps_per_frame` is capped at 3. A machine that cannot keep up now runs in slow motion
   (and the benchmark reports it through `sim_speed_ratio`) instead of freezing.
5. **Correct timing.** The benchmark now times each phase of the enemy update itself.

## Reading your next result
| If you see | It means | Try |
|---|---|---|
| `manager_total` under 8 ms, FPS good | the fix worked | go on to 1200 and test a weaker machine |
| `manager_total` high, `separation` the biggest part | separation still dominates | slice it 3 or 4 ways, or skip it for enemies far from the hero |
| `manager_total` high, `enemy_update` the biggest part | per-enemy logic dominates | move chase movement to packed arrays |
| `manager_total` small but FPS low | rendering dominates (one node per enemy) | draw all enemies from one `_draw`, or use `MultiMeshInstance2D` |
| `sim_speed_ratio` below 0.95 | physics can't keep up | the numbers above tell you which phase to cut |
| `grid_rebuild` large | rebuilding costs more than expected | rebuild every 3rd tick, or insert only enemies near the hero |

## If it still fails, in order
1. Confirm vsync is off, the renderer is as expected, and no debugger or profiler is attached.
2. Use the phase timings above to pick the fix.
3. Stop calling `queue_redraw()` for burrow animation on every burrowed enemy every frame.
4. Pool projectiles and Sinag pickups (currently `queue_free`).
5. Lower the alive caps in the spawn curve.
6. Last resort: move the enemy loop to C# or a GDExtension.

Also test on your **lowest-spec target machine**, since that decides what the game can ask of players.

## Jira
Story "Performance", tasks: Enemy pooling, Simple circle-based separation, Benchmark scene with 500 enemies,
Benchmark scene with 800 enemies, Record frame-time baseline (fill in the table above).
