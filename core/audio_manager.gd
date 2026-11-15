extends Node
## Autoload "Audio": the one place music and interface sounds are requested.
##
## PLACEHOLDERS: no audio assets exist yet (see audio/README.md).
##   Audio.play_music("title")   looks for res://audio/music/title.ogg (or .mp3/.wav);
##                               if the file is missing nothing plays and no error is raised.
##   Audio.ui("move")            looks for res://audio/ui/move.wav (or .ogg); if missing, a
##                               soft synthesised tone stands in so the interface is not silent.
## Dropping correctly named files into those folders is all that is needed to replace them.
## Music plays on the "Music" bus, interface sounds on "SFX" (volumes in Settings).

const MUSIC_DIR := "res://audio/music/"
const UI_DIR := "res://audio/ui/"
## Stand-in tones: [frequency Hz, second frequency (0 = none), seconds, level].
const UI_TONES := {
	"move": [880.0, 0.0, 0.07, 0.10],
	"accept": [660.0, 990.0, 0.16, 0.14],
	"back": [520.0, 390.0, 0.12, 0.11],
	"adjust": [740.0, 0.0, 0.04, 0.07],
}

## Id of the track asked for last ("" = none), whether or not a file exists for it.
var current_music := ""
## Id of the last interface sound asked for (for tests).
var last_ui := ""

var _music: AudioStreamPlayer
var _ui: AudioStreamPlayer
var _fade: Tween
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_ui = AudioStreamPlayer.new()
	_ui.bus = "SFX"
	_ui.max_polyphony = 4
	add_child(_ui)


## Cross-fades to a looping track. Unknown or missing ids fade to silence.
func play_music(id: String, fade: float = 1.5) -> void:
	if id == current_music:
		return
	current_music = id
	var stream := _find(MUSIC_DIR, id, ["ogg", "mp3", "wav"])
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	if _music.playing:
		_fade.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	_fade.tween_callback(func() -> void:
		_music.stop()
		if stream != null:
			_music.stream = stream
			_music.volume_db = -40.0
			_music.play())
	if stream != null:
		_fade.tween_property(_music, "volume_db", 0.0, fade)


func stop_music(fade: float = 1.0) -> void:
	play_music("", fade)


## A short interface sound: "move", "accept", "back", "adjust".
func ui(id: String) -> void:
	last_ui = id
	if not _cache.has(id):
		var s := _find(UI_DIR, id, ["wav", "ogg"])
		_cache[id] = s if s != null else _tone(UI_TONES.get(id, UI_TONES["move"]))
	_ui.stream = _cache[id]
	_ui.play()


func _find(dir: String, id: String, exts: Array) -> AudioStream:
	if id == "":
		return null
	for e: String in exts:
		var p := "%s%s.%s" % [dir, id, e]
		if ResourceLoader.exists(p):
			return load(p) as AudioStream
	return null


## A soft sine blip with a quick attack and an exponential tail; optionally glides to a
## second pitch. 16-bit mono.
static func _tone(spec: Array) -> AudioStreamWAV:
	var rate := 22050
	var n := int(float(spec[2]) * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f: float = spec[0] if float(spec[1]) <= 0.0 else lerpf(spec[0], spec[1], smoothstep(0.25, 0.6, t))
		phase += TAU * f / rate
		var env := minf(t * 30.0, 1.0) * exp(-t * 5.0) * (1.0 - t)
		var v := (sin(phase) + 0.25 * sin(phase * 2.0)) * env * float(spec[3])
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w
