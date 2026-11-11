extends RefCounted
## Same seed must give the same run. Streams must not disturb each other.


func run() -> Array:
	var failures: Array = []

	# 1. Same seed, same sequence.
	var a := RunRng.new()
	var b := RunRng.new()
	a.start(12345)
	b.start(12345)
	for i in 500:
		if a.next_float(RunRng.SPAWN) != b.next_float(RunRng.SPAWN):
			failures.append("same seed gave different spawn values at draw %d" % i)
			break

	# 2. Rolling the loot stream must not change the spawn stream.
	var c := RunRng.new()
	var d := RunRng.new()
	c.start(12345)
	d.start(12345)
	for i in 100:
		d.next_float(RunRng.LOOT)
	var seq_c: Array = []
	var seq_d: Array = []
	for i in 200:
		seq_c.append(c.int_range(0, 1000, RunRng.SPAWN))
		seq_d.append(d.int_range(0, 1000, RunRng.SPAWN))
	if seq_c != seq_d:
		failures.append("loot rolls changed the spawn sequence (streams are not independent)")

	# 3. Different seeds should differ.
	var e := RunRng.new()
	var f := RunRng.new()
	e.start(1)
	f.start(2)
	var differs := false
	for i in 50:
		if e.next_float(RunRng.SPAWN) != f.next_float(RunRng.SPAWN):
			differs = true
			break
	if not differs:
		failures.append("different seeds produced identical sequences")

	# 4. Pin the seed derivation. If this fails, saved seeds no longer reproduce runs.
	if RunRng.derive_seed(12345, RunRng.SPAWN) != 3501899109:
		failures.append("derive_seed(12345, spawn) changed (expected 3501899109)")
	if RunRng.derive_seed(12345, RunRng.LOOT) != 2707601328:
		failures.append("derive_seed(12345, loot) changed (expected 2707601328)")

	# 5. pick_unique returns the right count with no duplicates and leaves the input alone.
	var g := RunRng.new()
	g.start(99)
	var items: Array = [1, 2, 3, 4, 5, 6]
	var picked: Array = g.pick_unique(items, 3, RunRng.LEVELUP)
	if picked.size() != 3:
		failures.append("pick_unique returned %d items, expected 3" % picked.size())
	var seen: Dictionary = {}
	for item in picked:
		if seen.has(item):
			failures.append("pick_unique returned a duplicate: %s" % str(item))
		seen[item] = true
	if items != [1, 2, 3, 4, 5, 6]:
		failures.append("pick_unique modified its input array")
	if g.pick_unique(items, 99, RunRng.LEVELUP).size() != 6:
		failures.append("pick_unique should cap at the array size")
	if g.pick([], RunRng.MISC) != null:
		failures.append("pick on an empty array should return null")

	return failures
