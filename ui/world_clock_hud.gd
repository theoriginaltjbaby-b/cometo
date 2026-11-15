class_name WorldClockHUD
extends HBoxContainer
## Compact clock: date and weekday over the 12-hour time with a small drawn weather
## glyph, right-aligned behind a hairline. Reads WorldTime and Weather through their
## signals; holds no state of its own. Hidden during dialogue and when
## WorldTime.hud_hidden is set (cinematics).

var _date: Label
var _time: Label
var _icon: WeatherGlyph


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 5)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	add_child(col)
	_date = Label.new()
	UiTheme.caps(_date, 6, UiTheme.DIM)
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_date)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	_icon = WeatherGlyph.new()
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	_time = Label.new()
	_time.add_theme_font_size_override("font_size", 11)
	_time.add_theme_color_override("font_color", UiTheme.BONE)
	row.add_child(_time)
	for l: Label in [_date, _time]:
		l.add_theme_color_override("font_shadow_color", UiTheme.SHADOW)
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = Color(UiTheme.ACCENT, 0.7)
	bar.custom_minimum_size = Vector2(1, 0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	WorldTime.minute_changed.connect(func(_h: int, _m: int) -> void: refresh())
	WorldTime.day_changed.connect(func(_c: WorldCalendar) -> void: refresh())
	WorldTime.time_jumped.connect(refresh)
	Weather.weather_changed.connect(func(_t: String, _p: String) -> void: refresh())
	refresh()


func refresh() -> void:
	_date.text = WorldTime.date_text().to_upper()
	_time.text = WorldTime.time_text()
	_icon.set_state(Weather.current, WorldTime.is_between(6, 19.5))


func text() -> String:
	return "%s\n%s" % [WorldTime.date_text(), WorldTime.time_text()]


func _process(_delta: float) -> void:
	visible = not Dialogue.active and not WorldTime.hud_hidden


## Small line-drawn weather symbol.
class WeatherGlyph:
	extends Control

	var weather := "clear"
	var day := true

	func _init() -> void:
		custom_minimum_size = Vector2(11, 11)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_state(w: String, is_day: bool) -> void:
		if w != weather or is_day != day:
			weather = w
			day = is_day
			queue_redraw()

	func _draw() -> void:
		var c := UiTheme.ACCENT
		var o := size * 0.5
		match weather:
			"clear":
				if day:
					draw_arc(o, 2.4, 0, TAU, 16, c, 1.0, true)
					for i in 8:
						var d := Vector2.from_angle(TAU * i / 8.0)
						draw_line(o + d * 3.9, o + d * 5.2, c, 1.0, true)
				else:
					draw_arc(o, 3.6, PI * 0.35, PI * 1.65, 16, c, 1.0, true)
					draw_arc(o + Vector2(2.2, 0), 3.0, PI * 0.62, PI * 1.38, 12, c, 1.0, true)
			"cloudy":
				_cloud(o + Vector2(0, 0.5), c)
			"rain", "heavy_rain":
				_cloud(o + Vector2(0, -1.5), c)
				var n := 4 if weather == "heavy_rain" else 2
				for i in n:
					var x := o.x - 3.0 + 6.0 * (float(i) + 0.5) / float(n)
					draw_line(Vector2(x + 0.6, o.y + 2.0), Vector2(x - 0.6, o.y + 4.8), c, 1.0, true)
			"fog":
				for i in 3:
					var y := o.y - 3.0 + i * 3.0
					draw_line(Vector2(o.x - 4.5 + i, y), Vector2(o.x + 4.5 - (2 - i), y), c, 1.0)
			"snow":
				for i in 3:
					var d := Vector2.from_angle(PI * i / 3.0 + PI * 0.5) * 4.2
					draw_line(o - d, o + d, c, 1.0, true)

	func _cloud(at: Vector2, c: Color) -> void:
		draw_arc(at + Vector2(-2.0, 0.6), 2.0, PI * 0.5, PI * 1.5, 10, c, 1.0, true)
		draw_arc(at + Vector2(0.4, -0.6), 2.6, PI, TAU, 12, c, 1.0, true)
		draw_arc(at + Vector2(2.6, 0.9), 1.7, -PI * 0.5, PI * 0.5, 10, c, 1.0, true)
		draw_line(at + Vector2(-2.0, 2.6), at + Vector2(2.6, 2.6), c, 1.0)
