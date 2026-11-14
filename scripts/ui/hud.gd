class_name Hud
extends CanvasLayer
## In-run display: XP bar, level, timer, HP bar, kills, seed and FPS.
## Built in code so M1 needs no hand-edited UI scenes (real UI art comes in M6).

var _world: RunWorld
var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _level_label: Label
var _timer_label: Label
var _info_label: Label
var _phase_label: Label
var _moon_bar: ProgressBar
var _banner_label: Label
var _build_label: Label


func _init() -> void:
	layer = 10


func _ready() -> void:
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 1.0
	_xp_bar.custom_minimum_size = Vector2(0, 14)
	_xp_bar.modulate = Color(0.45, 0.85, 1.0)
	add_child(_xp_bar)
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 14.0

	_level_label = Label.new()
	_level_label.position = Vector2(12, 18)
	_level_label.add_theme_font_size_override(&"font_size", 20)
	add_child(_level_label)

	_timer_label = Label.new()
	_timer_label.custom_minimum_size = Vector2(160, 0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override(&"font_size", 28)
	add_child(_timer_label)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_top = 18.0

	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(220, 16)
	_hp_bar.position = Vector2(12, 48)
	_hp_bar.modulate = Color(1.0, 0.4, 0.4)
	add_child(_hp_bar)

	_info_label = Label.new()
	_info_label.position = Vector2(12, 70)
	add_child(_info_label)


	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.custom_minimum_size = Vector2(240, 0)
	add_child(_phase_label)
	_phase_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_phase_label.offset_top = 52.0

	_moon_bar = ProgressBar.new()
	_moon_bar.show_percentage = false
	_moon_bar.min_value = 0.0
	_moon_bar.max_value = 1.0
	_moon_bar.custom_minimum_size = Vector2(240, 10)
	add_child(_moon_bar)
	_moon_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_moon_bar.offset_top = 80.0
	_moon_bar.offset_bottom = 90.0

	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override(&"font_size", 26)
	_banner_label.custom_minimum_size = Vector2(700, 0)
	add_child(_banner_label)
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner_label.offset_top = 110.0

	_build_label = Label.new()
	_build_label.position = Vector2(12, 100)
	add_child(_build_label)


func setup(world: RunWorld) -> void:
	_world = world


func _process(_delta: float) -> void:
	if _world == null or _world.hero == null or _world.run_state == null:
		return
	var state: RunState = _world.run_state
	var hero: Hero = _world.hero

	_xp_bar.value = clampf(state.xp / state.xp_needed(), 0.0, 1.0)
	_level_label.text = "LV %d" % state.level
	var total_seconds: int = int(_world.run_time)
	_timer_label.text = "%02d:%02d" % [floori(total_seconds / 60.0), total_seconds % 60]
	_hp_bar.max_value = hero.data.max_hp
	_hp_bar.value = hero.current_hp
	_info_label.text = "Kills: %d   Alive: %d   Pressure: x%.2f   Seed: %d   FPS: %d" % [
		state.kills, _world.enemies.alive_count(), _world.pressure,
		RngService.current_seed, Engine.get_frames_per_second()
	]

	var director: RunDirector = _world.director
	_phase_label.text = "%s   (%s)" % [
		director.phase_name(_world.run_time),
		"BLOOD MOON %ds" % ceili(director.blood_moon_left) if director.is_blood_moon() else "Blood Moon meter",
	]
	_moon_bar.value = 1.0 if director.is_blood_moon() else director.meter
	_moon_bar.modulate = Color(1.0, 0.2, 0.2) if director.is_blood_moon() else Color(0.7, 0.3, 0.4)
	_banner_label.text = _world.banner()
	_build_label.text = state.build_summary()
