# Performance (M2 gate: hundreds of enemies at a stable frame rate)

**Gate:** 800 enemies on screen with an average of at least **55 FPS** and a 99th-percentile frame
time of at most **25 ms** (so there are no regular hitches). The benchmark prints PASS or FAIL against these.

## Run the benchmark
Open the project folder in a terminal (use your own path to the Godot executable):
```
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=500 --seconds=20 --auto-quit
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=800 --seconds=20 --auto-quit
godot --path . res://scenes/benchmark/benchmark.tscn -- --enemies=1200 --seconds=20 --auto-quit
```
Or open `scenes/benchmark/benchmark.tscn` in the editor and press **F6** (Run Current Scene) for a 500-enemy run.

- A god-mode hero with a maxed Spirit Staff and Asin fights a constant horde of N Tiyanak (they respawn as they die).
- The first 3 seconds are warm-up and are not measured. Then it records frame times for `--seconds`.
- Fixed seed (12345), so runs are comparable between code changes and between machines.
- **Vsync is off** by default so the result shows real headroom, not the monitor's refresh rate. Add `--vsync` to turn it on.
- Run it in a **window with rendering**. A headless run skips drawing and will look far better than reality.
- Close other heavy programs, plug in a laptop, and run each setting twice; use the worse result.

Results print to the Output panel and are saved to `user://benchmarks/` (Editor: Project, Open User Data Folder).

## What the numbers mean
| Metric | Meaning |
|---|---|
| `avg_fps` | average frames per second |
| `p95_frame_ms` / `p99_frame_ms` | 95% / 99% of frames were faster than this. High p99 means visible hitching even if the average looks fine |
| `max_frame_ms` | the single worst frame |
| `avg_process_ms` / `avg_physics_ms` | engine time spent in `_process` and `_physics_process`. If physics is large, enemy logic is the cost; if both are small but FPS is low, it is rendering |
| `enemy_nodes_created` | stays at about the target once the pool is warm. If it keeps growing, pooling is broken |

## Record your results
| Date | Machine / GPU | Godot | Renderer | Enemies | Avg FPS | p99 ms | Max ms | Physics ms | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| | | | | 500 | | | | | |
| | | | | 800 | | | | | |
| | | | | 1200 | | | | | |

Also test on your **lowest-spec target machine**, since that decides what the game can ask of players.

## What M2 changed for performance
1. **Spatial grid** (`SpatialGrid`): projectiles, orbit weapons and targeting check a few nearby cells instead of scanning every enemy.
   Before this, every shot compared itself with every enemy, so cost grew with shots times enemies.
2. **EnemyManager**: one update loop for all enemies (no per-node `_physics_process`), with a **node pool** so deaths and spawns
   recycle nodes instead of allocating them.
3. **Separation**: enemies push each other apart using the grid, so a horde stays a crowd rather than collapsing into one dot.
4. **Damage number cap**: at most 60 floating labels exist at once.

## If it fails, try in this order
1. Confirm vsync is off, the renderer is as expected, and no debugger or profiler is attached.
2. Check `avg_physics_ms`. If it dominates, run separation on half the enemies each frame (alternate frames).
3. If rendering dominates (low FPS but small process and physics ms): draw all enemies from one `_draw` call in the manager,
   or switch to `MultiMeshInstance2D`, instead of one node per enemy.
4. Stop calling `queue_redraw()` for burrow animation on every burrowed enemy every frame.
5. Pool projectiles and Sinag pickups (currently `queue_free`).
6. Lower the alive caps in the spawn curve.
7. Last resort: move the enemy loop to C# or a GDExtension.

## Jira
Story "Performance", tasks: Enemy pooling, Simple circle-based separation, Benchmark scene with 500 enemies,
Benchmark scene with 800 enemies, Record frame-time baseline (fill in the table above).
