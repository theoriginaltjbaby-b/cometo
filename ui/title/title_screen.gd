class_name TitleScreen
extends Control
## The opening screen: the planet (TitleBackdrop), the title lettering with the ship
## drifting across it, and the main menu with its Load and Options panels.
## It owns no game state. game/app.gd listens to its signals and tells it whether a game
## is in progress (`session_live`) so it can offer CONTINUE.
## Works with mouse, touch and the built-in ui_* actions (keyboard and gamepad).

signal continue_requested
signal new_game_requested
signal load_requested(slot: String)
signal quit_requested
## PROTOTYPE: the 2D test area. Remove with the entry in show_menu().
signal prototype_requested

const TITLE := "COMETOGRAPHIA"
const SLOT_NAMES := {"auto": "Autosave", "manual": "Manual save"}

## The shelved 2D prototype (entry 15) stays in the code but is off the menu.
var show_prototype := false
## A game is loaded behind the title (returned from the pause menu).
var session_live := false
## False in tests: no fades or delays.
var animate := true

var backdrop: TitleBackdrop
var ship: TitleShip
var _wisps: ColorRect
var _title: Label
var _safe: Control
var _menu: VBoxContainer
var _panel: PanelContainer
var _panel_box: VBoxContainer
var _state := "menu"
var _quiet := true
var _confirm_new := false
var _new: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop = TitleBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# the lettering sits in the scene: the ship and near cloud pass in front of it
	_title = Label.new()
	_title.text = TITLE
	var thin := SystemFont.new()
	thin.font_names = PackedStringArray(["Helvetica Neue", "Avenir Next", "Roboto", "sans-serif"])
	thin.font_weight = 100
	var spaced := FontVariation.new()
	spaced.base_font = thin
	spaced.spacing_glyph = 9
	_title.add_theme_font_override("font", spaced)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.9, 0.94))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.anchor_top = 0.4
	_title.anchor_bottom = 0.4
	_title.offset_left = 9
	_title.grow_vertical = Control.GROW_DIRECTION_BOTH

	ship = TitleShip.new()
	add_child(ship)
	_wisps = backdrop.make_wisps()
	add_child(_wisps)
	_wisps.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_safe = Control.new()
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 1)
	_safe.add_child(_menu)
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.anchor_top = 0.62
	_menu.anchor_bottom = 0.62
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.custom_minimum_size = Vector2(190, 0)
	_safe.add_child(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.74
	_panel.anchor_bottom = 0.74
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", 3)
	_panel.add_child(_panel_box)

	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	show_menu()
	if animate:
		_title.modulate.a = 0.0
		_menu.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(_title, "modulate:a", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(_menu, "modulate:a", 1.0, 1.6).set_delay(1.2)


func _layout() -> void:
	ship.set_home(Vector2(size.x * 0.3, size.y * 0.31))
	ship.scale = Vector2.ONE * 1.5
	var s := UiTheme.safe_insets(self)
	_safe.offset_left = s.x
	_safe.offset_top = s.y
	_safe.offset_right = -s.z
	_safe.offset_bottom = -s.w


# --- main menu ----------------------------------------------------------------------

## Labels of the entries currently offered, top to bottom.
func items() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _menu.get_children():
		if not c.is_queued_for_deletion():
			out.append((c as Button).text)
	return out


func can_continue() -> bool:
	return session_live or not SaveManager.slot_info("auto").is_empty()


func show_menu() -> void:
	_state = "menu"
	_confirm_new = false
	_panel.visible = false
	_menu.visible = true
	_clear(_menu)
	if can_continue():
		_item(_menu, "CONTINUE", func() -> void: continue_requested.emit())
	_new = _item(_menu, "NEW GAME", _on_new)
	_item(_menu, "LOAD GAME", show_load)
	_item(_menu, "OPTIONS", show_options)
	if show_prototype:
		_item(_menu, "2D PROTOTYPE", func() -> void: prototype_requested.emit())
	if OS.has_feature("pc"):
		_item(_menu, "QUIT", func() -> void: quit_requested.emit())
	_focus_first(_menu)


## Hide the lettering and menu while another screen (character creation) is in front.
func set_covered(covered: bool) -> void:
	_title.visible = not covered
	_safe.visible = not covered


## Press the entry with this label (tests, and nothing else).
func choose(label: String) -> bool:
	for box: Control in [_menu, _panel_box]:
		if not box.is_visible_in_tree():
			continue
		for c in box.get_children():
			var b := c as Button
			if b != null and not b.is_queued_for_deletion() and b.text.begins_with(label) and not b.disabled:
				b.pressed.emit()
				return true
	return false


func state() -> String:
	return _state


func _on_new() -> void:
	# starting over discards the game in progress: ask once
	if session_live and not _confirm_new:
		_confirm_new = true
		_new.text = "NEW GAME  ·  CONFIRM"
		return
	new_game_requested.emit()


# --- load ---------------------------------------------------------------------------

func show_load() -> void:
	_open_panel("load", "LOAD GAME")
	var saves := SaveManager.list_saves()
	if saves.is_empty():
		_note("No saved games.")
	for s in saves:
		var slot := str(s["slot"])
		var text := "%s  ·  %s" % [str(SLOT_NAMES.get(slot, slot.capitalize())).to_upper(), _place(str(s["map"]))]
		if str(s["when"]) != "":
			text += "  ·  " + str(s["when"])
		var b := _item(_panel_box, text, func() -> void: load_requested.emit(slot))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = "Saved " + str(s["saved"]).replace("T", " ")
	_item(_panel_box, "BACK", _back)
	_focus_first(_panel_box)


## Slots listed in the load panel.
func listed_saves() -> PackedStringArray:
	var out := PackedStringArray()
	for s in SaveManager.list_saves():
		out.append(str(s["slot"]))
	return out


static func _place(map_id: String) -> String:
	return map_id.replace("_", " ").capitalize()


# --- options ------------------------------------------------------------------------

func show_options() -> void:
	_open_panel("options", "OPTIONS")
	for row: Array in [["master", "MASTER VOLUME"], ["music", "MUSIC"], ["sfx", "EFFECTS"]]:
		_slider(row[0], row[1])
	if Settings.has_display_options():
		_toggle("FULLSCREEN", func() -> bool: return Settings.fullscreen, Settings.set_fullscreen)
		_toggle("VSYNC", func() -> bool: return Settings.vsync, Settings.set_vsync)
	_item(_panel_box, "BACK", _back)
	_focus_first(_panel_box)


func _slider(key: String, text: String) -> void:
	var row := HBoxContainer.new()
	_panel_box.add_child(row)
	var l := Label.new()
	l.text = text
	UiTheme.caps(l, 6, UiTheme.DIM)
	l.custom_minimum_size = Vector2(74, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.name = key
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Settings.volume[key]
	s.custom_minimum_size = Vector2(90, 12)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var pct := Label.new()
	UiTheme.caps(pct, 6, UiTheme.BONE)
	pct.custom_minimum_size = Vector2(18, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.text = str(roundi(s.value * 100.0))
	row.add_child(pct)
	s.value_changed.connect(func(v: float) -> void:
		Settings.set_volume(key, v)
		pct.text = str(roundi(v * 100.0))
		_sound("adjust"))
	s.focus_entered.connect(func() -> void:
		l.add_theme_color_override("font_color", UiTheme.ACCENT)
		_sound("move"))
	s.focus_exited.connect(func() -> void: l.add_theme_color_override("font_color", UiTheme.DIM))


func _toggle(text: String, getter: Callable, setter: Callable) -> void:
	var label := func() -> String: return "%s  ·  %s" % [text, "ON" if getter.call() else "OFF"]
	var b := _item(_panel_box, label.call(), func() -> void: pass)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func() -> void:
		setter.call(not getter.call())
		b.text = label.call())


## The volume slider for "master", "music" or "sfx" while Options is open.
func slider(key: String) -> HSlider:
	return _panel_box.find_child(key, true, false) as HSlider


# --- shared -------------------------------------------------------------------------

func _open_panel(state_name: String, heading: String) -> void:
	_state = state_name
	_menu.visible = false
	_panel.visible = true
	_clear(_panel_box)
	var h := Label.new()
	h.text = heading
	UiTheme.caps(h, 7, UiTheme.ACCENT)
	_panel_box.add_child(h)
	var rule := ColorRect.new()
	rule.color = Color(UiTheme.ACCENT, 0.3)
	rule.custom_minimum_size = Vector2(0, 1)
	_panel_box.add_child(rule)


func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", UiTheme.DIM)
	_panel_box.add_child(l)


func _back() -> void:
	if _state == "options":
		Settings.save_settings()
	_sound("back")
	show_menu()


func _item(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", UiTheme.caps_font())
	b.add_theme_font_size_override("font_size", 8)
	b.add_theme_color_override("font_color", Color(UiTheme.BONE, 0.72))
	var plain := UiTheme.box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3.0)
	plain.content_margin_left = 14.0
	plain.content_margin_right = 14.0
	var lit := UiTheme.box(Color(UiTheme.ACCENT, 0.06), Color(UiTheme.ACCENT, 0.9), 0, 3.0)
	lit.border_width_bottom = 1
	lit.content_margin_left = 14.0
	lit.content_margin_right = 14.0
	for k: String in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(k, plain)
	b.add_theme_stylebox_override("focus", lit)
	b.pressed.connect(func() -> void:
		if on_press != _back:
			_sound("accept")
		on_press.call())
	# one highlight only: the pointer moves the focus
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func() -> void:
		_sound("move")
		if animate:
			b.modulate.a = 0.6
			create_tween().tween_property(b, "modulate:a", 1.0, 0.25))
	parent.add_child(b)
	return b


func _focus_first(box: Control) -> void:
	_quiet = true
	for c in box.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl.focus_mode != Control.FOCUS_NONE and not ctl.is_queued_for_deletion():
			(func() -> void:
				if is_instance_valid(ctl) and ctl.is_inside_tree():
					ctl.grab_focus()).call_deferred()
			break
	(func() -> void: _quiet = false).call_deferred()


func _sound(id: String) -> void:
	if not _quiet and is_visible_in_tree():
		Audio.ui(id)


static func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and _state != "menu" and event.is_action_pressed(&"ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
