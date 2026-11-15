class_name CharacterCreation
extends Control
## Shown after NEW GAME: a name and the player's look, with a turning preview of the
## in-game figure. Only appearance exists so far (no stats, classes or backgrounds are
## in the game). Emits done(profile); the profile is the set of GameState flags a new
## game starts with: player_name and player_look (colours as HTML strings, so the save
## file can hold them).
## Each option is one focusable row: press or tap to step forward, left/right to step
## either way, so it works with touch, mouse, keys and gamepad alike.

signal done(profile: Dictionary)
signal cancelled

const OPTIONS := [
	{"key": "hair", "label": "HAIR", "values": [["Bun", "bun"], ["Short", "short"], ["Long", "long"], ["Shaved", "bald"]]},
	{"key": "hair_color", "label": "HAIR COLOUR", "values": [["Black", "#1a0f0d"], ["Brown", "#4a2e1c"], ["Auburn", "#7a3320"], ["Fair", "#c9a66b"], ["Grey", "#9a9a9a"]]},
	{"key": "skin", "label": "SKIN", "values": [["Tone 1", "#f0d2b8"], ["Tone 2", "#d9a981"], ["Tone 3", "#b5835a"], ["Tone 4", "#8a5a3c"], ["Tone 5", "#5a3a28"]]},
	{"key": "coat", "label": "COAT", "values": [["Burgundy", "#80211c"], ["Navy", "#1f3555"], ["Forest", "#27452f"], ["Slate", "#454b55"], ["Ochre", "#8a6a25"]]},
	{"key": "long_coat", "label": "COAT LENGTH", "values": [["Long", true], ["Short", false]]},
]

var _pick := {}
var _rows := {}
var _name: LineEdit
var _begin: Button
var _stage: Node3D
var _figure: Figure3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.06, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe := Control.new()
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var s := UiTheme.safe_insets(self)
	safe.offset_left = s.x
	safe.offset_top = s.y
	safe.offset_right = -s.z
	safe.offset_bottom = -s.w

	# preview: the real figure in its own small 3D world
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(420, 620)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_stage = Node3D.new()
	vp.add_child(_stage)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 3.6)
	cam.fov = 30.0
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_color = Color(1.0, 0.86, 0.72)
	key.light_energy = 1.3
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 150, 0)
	rim.light_color = Color(0.5, 0.62, 1.0)
	rim.light_energy = 0.8
	vp.add_child(rim)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.44, 0.6)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var view := TextureRect.new()
	view.texture = vp.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(view)
	view.anchor_left = 0.1
	view.anchor_right = 0.42
	view.anchor_top = 0.08
	view.anchor_bottom = 0.94

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	safe.add_child(panel)
	panel.anchor_left = 0.7
	panel.anchor_right = 0.7
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var h := Label.new()
	h.text = "NEW GAME  ·  CHARACTER"
	UiTheme.caps(h, 7, UiTheme.ACCENT)
	box.add_child(h)
	var rule := ColorRect.new()
	rule.color = Color(UiTheme.ACCENT, 0.3)
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	_name = LineEdit.new()
	_name.placeholder_text = "Name"
	_name.max_length = 16
	_name.add_theme_font_size_override("font_size", 9)
	_name.text_submitted.connect(func(_t: String) -> void: _begin.grab_focus())
	box.add_child(_name)
	for o: Dictionary in OPTIONS:
		_pick[o["key"]] = 0
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UiTheme.caps_font())
		b.add_theme_font_size_override("font_size", 7)
		b.pressed.connect(_step.bind(o, 1))
		b.gui_input.connect(func(e: InputEvent) -> void:
			if e.is_action_pressed(&"ui_right"):
				_step(o, 1)
				b.accept_event()
			elif e.is_action_pressed(&"ui_left"):
				_step(o, -1)
				b.accept_event())
		b.mouse_entered.connect(b.grab_focus)
		box.add_child(b)
		_rows[o["key"]] = b
		_label(o)
	_begin = Button.new()
	_begin.text = "BEGIN"
	_begin.add_theme_font_override("font", UiTheme.caps_font())
	_begin.add_theme_font_size_override("font_size", 8)
	_begin.add_theme_color_override("font_color", UiTheme.ACCENT)
	_begin.pressed.connect(func() -> void:
		Audio.ui("accept")
		done.emit(profile()))
	box.add_child(_begin)
	var back := Button.new()
	back.text = "BACK"
	back.add_theme_font_override("font", UiTheme.caps_font())
	back.add_theme_font_size_override("font_size", 8)
	back.pressed.connect(_cancel)
	box.add_child(back)
	for b: Button in [_begin, back]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_entered.connect(b.grab_focus)
	_rebuild()
	(_rows[OPTIONS[0]["key"]] as Button).grab_focus.call_deferred()


## The flags a new game starts with.
func profile() -> Dictionary:
	var look := {}
	for o: Dictionary in OPTIONS:
		look[o["key"]] = (o["values"] as Array)[_pick[o["key"]]][1]
	return {"player_name": _name.text.strip_edges(), "player_look": look}


func set_player_name(text: String) -> void:
	_name.text = text


## Step an option by key (tests and the rows themselves).
func step(key: String, by: int = 1) -> void:
	for o: Dictionary in OPTIONS:
		if o["key"] == key:
			_step(o, by)


func _step(o: Dictionary, by: int) -> void:
	_pick[o["key"]] = posmod(int(_pick[o["key"]]) + by, (o["values"] as Array).size())
	_label(o)
	_rebuild()
	Audio.ui("adjust")


func _label(o: Dictionary) -> void:
	(_rows[o["key"]] as Button).text = "%s    ‹  %s  ›" % [o["label"], (o["values"] as Array)[_pick[o["key"]]][0]]


func _rebuild() -> void:
	var yaw := _figure.rotation.y if _figure != null else PI + 0.5
	if _figure != null:
		_figure.queue_free()
	_figure = Figure3D.new()
	_figure.accent = Color(0.62, 0.42, 0.2)
	_figure.configure({"hair": "bun", "long_coat": true})
	Player3D.apply_look(_figure, profile()["player_look"])
	_figure.rotation.y = yaw
	_stage.add_child(_figure)


func _process(delta: float) -> void:
	if _figure != null:
		_figure.rotation.y += delta * 0.5


func _cancel() -> void:
	Audio.ui("back")
	cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
