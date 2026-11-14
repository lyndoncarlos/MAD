extends RefCounted
## Run shape: phases, 20:00 win, elites, Blood Moon meter and drop rolls.


func run() -> Array:
	var failures: Array = []
	var d := RunDirector.new()

	if d.phase_name(0.0) != "Dusk" or d.phase_name(179.0) != "Dusk":
		failures.append("first 3 minutes should be Dusk")
	if d.phase_name(180.0) != "Night" or d.phase_name(8.0 * 60.0) != "Midnight":
		failures.append("phase boundaries wrong")
	if d.phase_name(1199.0) != "Pre-dawn":
		failures.append("last minute should be Pre-dawn")
	if d.is_complete(1199.9) or not d.is_complete(1200.0):
		failures.append("run should complete exactly at 20:00")

	# Elites: none before minute 4, one at 4, all four by 16 and never repeated.
	if d.take_due_elites(239.0) != 0:
		failures.append("no elite before minute 4")
	if d.take_due_elites(240.0) != 1:
		failures.append("one elite due at minute 4")
	if d.take_due_elites(241.0) != 0:
		failures.append("elite must not be handed out twice")
	if d.take_due_elites(1000.0) != 3:
		failures.append("remaining three elites due by minute 16")

	# Blood Moon: 100 kills fill the meter, then it runs for its duration.
	var m := RunDirector.new()
	var started := false
	for i in 99:
		started = started or m.add_kills(1)
	if started or m.is_blood_moon():
		failures.append("99 kills should not trigger the Blood Moon")
	if not m.add_kills(1) or not m.is_blood_moon():
		failures.append("100th kill should trigger the Blood Moon")
	if m.spawn_mult() <= 1.0 or m.xp_mult() <= 1.0:
		failures.append("Blood Moon should raise spawns and Sinag")
	m.add_kills(50)
	if m.meter != 0.0:
		failures.append("meter must not fill during a Blood Moon")
	var set_tick := false
	for i in int(RunDirector.BLOOD_MOON_SECONDS * 60.0) + 2:
		set_tick = m.tick(1.0 / 60.0) or set_tick
	if not set_tick or m.is_blood_moon() or m.spawn_mult() != 1.0:
		failures.append("Blood Moon should end after its duration")

	# Drops.
	if RunDirector.drop_for(true, 0.99) != RunDirector.Drop.CHEST:
		failures.append("elites always drop a chest")
	if RunDirector.drop_for(false, 0.0) != RunDirector.Drop.MAGNET:
		failures.append("lowest roll should be a magnet")
	if RunDirector.drop_for(false, RunDirector.MAGNET_CHANCE + 0.001) != RunDirector.Drop.HERB:
		failures.append("next band should be a herb")
	if RunDirector.drop_for(false, 0.5) != RunDirector.Drop.NONE:
		failures.append("most kills drop nothing")

	# The elite data must exist and be flagged as an elite.
	var elite := load("res://data/enemies/tiyanak_alpha.tres") as EnemyData
	if elite == null or not elite.is_elite:
		failures.append("tiyanak_alpha must be an elite EnemyData")
	return failures
