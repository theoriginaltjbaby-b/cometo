extends Node
## Autoload "Settings": player preferences that are not part of a save game. Stored in
## user://settings.cfg and applied at boot. Volumes are 0..1 and drive the audio buses
## Master, Music and SFX (the last two are created here, so no bus layout file is needed).

signal changed

const PATH := "user://settings.cfg"
const BUSES := {"master": "Master", "music": "Music", "sfx": "SFX"}

var volume := {"master": 0.8, "music": 0.7, "sfx": 0.8}
var fullscreen := false
var vsync := true
## Tests point this elsewhere so they never touch the player's file.
var path := PATH


func _ready() -> void:
	for b: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	load_settings()
	apply()


func set_volume(key: String, v: float) -> void:
	volume[key] = clampf(v, 0.0, 1.0)
	apply()
	changed.emit()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply()
	changed.emit()


func set_vsync(on: bool) -> void:
	vsync = on
	apply()
	changed.emit()


## Fullscreen and vsync are desktop preferences; phones and browsers manage their own.
func has_display_options() -> bool:
	return OS.has_feature("pc")


func apply() -> void:
	for k: String in BUSES:
		var i := AudioServer.get_bus_index(BUSES[k])
		if i >= 0:
			var v: float = volume[k]
			AudioServer.set_bus_mute(i, v <= 0.001)
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))
	if has_display_options() and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


func save_settings() -> void:
	var c := ConfigFile.new()
	for k: String in volume:
		c.set_value("audio", k, volume[k])
	c.set_value("display", "fullscreen", fullscreen)
	c.set_value("display", "vsync", vsync)
	c.save(path)


func load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(path) != OK:
		return
	for k: String in volume:
		volume[k] = clampf(float(c.get_value("audio", k, volume[k])), 0.0, 1.0)
	fullscreen = bool(c.get_value("display", "fullscreen", fullscreen))
	vsync = bool(c.get_value("display", "vsync", vsync))
