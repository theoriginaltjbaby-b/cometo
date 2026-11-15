class_name UiTheme
## Interface look, built in code so nothing falls back to default Godot styling.
## Direction: calm, minimal, technical. Deep blue translucent fields, hairlines and
## corner brackets, pale cyan accents, small spaced capitals for labels.
## PROVISIONAL: system typeface. A licensed display/body face should replace it.

const INK := Color(0.02, 0.06, 0.1, 0.86)
const INK_SOFT := Color(0.02, 0.06, 0.1, 0.5)
## Primary accent: pale cyan.
const ACCENT := Color(0.56, 0.82, 0.94)
const ACCENT_DEEP := Color(0.24, 0.5, 0.68)
const BONE := Color(0.9, 0.95, 0.98)
const DIM := Color(0.5, 0.62, 0.7)
const SHADOW := Color(0.0, 0.03, 0.06, 0.75)

static var _caps: FontVariation


static func box(bg: Color, border: Color, border_w: int = 1, pad: float = 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	s.anti_aliasing = false
	return s


static func base_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["DIN Alternate", "Avenir Next", "Helvetica Neue", "Roboto", "sans-serif"])
	f.font_weight = 400
	return f


## Letter-spaced face for labels and headers set in capitals.
static func caps_font() -> FontVariation:
	if _caps == null:
		_caps = FontVariation.new()
		_caps.base_font = base_font()
		_caps.spacing_glyph = 1
	return _caps


## Style a label as a small spaced-capitals header.
static func caps(l: Control, size: int, col: Color) -> void:
	l.add_theme_font_override("font", caps_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = base_font()
	t.default_font_size = 10

	t.set_stylebox("panel", "PanelContainer", TechPanelStyle.new(8.0))

	# buttons: bare text, a left accent bar when focused, a faint wash on hover
	var flat := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3.0)
	flat.content_margin_left = 7.0
	var hover := box(Color(ACCENT, 0.1), Color(0, 0, 0, 0), 0, 3.0)
	hover.content_margin_left = 7.0
	var focus := box(Color(ACCENT, 0.08), ACCENT, 0, 3.0)
	focus.border_width_left = 2
	focus.content_margin_left = 7.0
	t.set_stylebox("normal", "Button", flat)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", flat)
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(DIM, 0.5))

	# sliders: a hairline track, accent fill, a small bar for the grabber
	var track := StyleBoxLine.new()
	track.color = Color(DIM, 0.5)
	track.thickness = 1
	var fill := StyleBoxLine.new()
	fill.color = ACCENT
	fill.thickness = 1
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _bar(BONE))
	t.set_icon("grabber_highlight", "HSlider", _bar(ACCENT))
	t.set_icon("grabber_disabled", "HSlider", _bar(DIM))
	# text entry: an underline, nothing else
	var edit := box(Color(ACCENT, 0.05), Color(ACCENT, 0.45), 0, 3.0)
	edit.border_width_bottom = 1
	var edit_focus := box(Color(ACCENT, 0.1), ACCENT, 0, 3.0)
	edit_focus.border_width_bottom = 1
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", edit_focus)
	t.set_color("font_color", "LineEdit", BONE)
	t.set_color("font_placeholder_color", "LineEdit", Color(DIM, 0.7))
	t.set_color("caret_color", "LineEdit", ACCENT)

	t.set_color("font_color", "Label", BONE)
	t.set_color("default_color", "RichTextLabel", BONE)
	t.set_font_size("normal_font_size", "RichTextLabel", 10)
	t.set_constant("line_separation", "RichTextLabel", 2)
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 6)
	return t


static func _bar(c: Color) -> ImageTexture:
	var img := Image.create(3, 9, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


## Insets (left, top, right, bottom) in the control's own units that keep content clear
## of the notch and home indicator. Zero off mobile. Untested on device.
static func safe_insets(c: Control) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var k := c.get_viewport_rect().size / win
	return Vector4(safe.position.x * k.x, safe.position.y * k.y, (win.x - safe.end.x) * k.x, (win.y - safe.end.y) * k.y)


## A small HUD chip: spaced capitals over a faint field with an underline.
static func chip(button: Button) -> void:
	var states := {"normal": [INK_SOFT, Color(ACCENT, 0.45)], "hover": [INK, ACCENT], "pressed": [Color(ACCENT_DEEP, 0.7), ACCENT],
		"focus": [INK_SOFT, Color(ACCENT, 0.45)]}
	for k: String in states:
		var s := box(states[k][0], states[k][1], 0, 4.0)
		s.border_width_bottom = 1
		s.content_margin_left = 6.0
		s.content_margin_right = 6.0
		button.add_theme_stylebox_override(k, s)
	button.add_theme_font_override("font", caps_font())
	button.focus_mode = Control.FOCUS_NONE
