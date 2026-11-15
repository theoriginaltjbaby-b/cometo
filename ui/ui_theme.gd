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

	t.set_color("font_color", "Label", BONE)
	t.set_color("default_color", "RichTextLabel", BONE)
	t.set_font_size("normal_font_size", "RichTextLabel", 10)
	t.set_constant("line_separation", "RichTextLabel", 2)
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 6)
	return t


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
