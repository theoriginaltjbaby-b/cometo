extends Node
## Autoload "Weather": a small weather state machine driven by WorldTime.
##
## Weather is planned ahead as a schedule of spells, each lasting min_duration to
## max_duration game minutes and chosen by weighted chance for the season it falls in.
## The schedule always covers the next day, which is the forecast. Nothing is rolled
## per frame: the schedule is only consulted when the clock's minute changes.
##
##   Weather.current                      # "clear" "cloudy" "rain" "heavy_rain" "fog" "snow"
##   Weather.weather_changed.connect(...) # encounters, dialogue, audio
##   Weather.forecast(24)                 # [{type, from, until}] in absolute minutes
##   Weather.set_weather("fog", 120)      # manual override for 120 minutes (-1 = until cleared)
##   Weather.clear_override()
##   Weather.is_wet()
## Debug builds: \ cycles through the weather types as an override.

signal weather_changed(type: String, previous: String)
## Fired at random intervals during heavy rain: hook thunder audio and flashes here.
signal lightning

const TYPES: PackedStringArray = ["clear", "cloudy", "rain", "heavy_rain", "fog", "snow"]

## What each weather does to the world, 0..1. EnvironmentController blends toward these.
## rain/snow: precipitation amount; cloud: how much sun is lost; fog: mist thickness.
var profiles := {
	"clear": {"rain": 0.0, "snow": 0.0, "cloud": 0.0, "fog": 0.0},
	"cloudy": {"rain": 0.0, "snow": 0.0, "cloud": 0.6, "fog": 0.05},
	"rain": {"rain": 0.5, "snow": 0.0, "cloud": 0.75, "fog": 0.15},
	"heavy_rain": {"rain": 1.0, "snow": 0.0, "cloud": 1.0, "fog": 0.3},
	"fog": {"rain": 0.0, "snow": 0.0, "cloud": 0.5, "fog": 1.0},
	"snow": {"rain": 0.0, "snow": 1.0, "cloud": 0.6, "fog": 0.2},
}
## Relative chances per season index (0 Spring .. 3 Winter).
var season_weights := {
	0: {"clear": 35, "cloudy": 20, "rain": 30, "heavy_rain": 8, "fog": 7, "snow": 0},
	1: {"clear": 60, "cloudy": 18, "rain": 8, "heavy_rain": 12, "fog": 2, "snow": 0},
	2: {"clear": 15, "cloudy": 30, "rain": 28, "heavy_rain": 7, "fog": 20, "snow": 0},
	3: {"clear": 14, "cloudy": 30, "rain": 3, "heavy_rain": 0, "fog": 8, "snow": 45},
}
## Length of one spell of weather, in game minutes.
var min_duration := 180
var max_duration := 540
## Weather a new game opens with.
var start_weather := "rain"

var current := "rain"
## Upcoming spells, soonest first: {type, until}; the first is the one in effect.
var schedule: Array[Dictionary] = []
var override := ""
## Absolute minute the override ends; -1 holds it until clear_override().
var override_until := -1

var _rng := RandomNumberGenerator.new()
var _bolt := 8.0


func _ready() -> void:
	WorldTime.minute_changed.connect(func(_h: int, _m: int) -> void: update())
	WorldTime.time_jumped.connect(update)
	reset()


## Start a fresh schedule. Pass a seed for a repeatable sequence.
func reset(rng_seed: int = -1) -> void:
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	override = ""
	override_until = -1
	schedule.clear()
	schedule.append({"type": start_weather, "until": WorldTime.total_minutes() + _rng.randi_range(min_duration, max_duration)})
	_fill()
	_apply(start_weather)


## Bring the weather up to date with the clock. Called on every game minute.
func update() -> void:
	var now := WorldTime.total_minutes()
	while not schedule.is_empty() and int(schedule[0]["until"]) <= now:
		schedule.pop_front()
	if schedule.is_empty():
		schedule.append({"type": _roll(now, current), "until": now + _rng.randi_range(min_duration, max_duration)})
	_fill()
	if override != "" and override_until >= 0 and now >= override_until:
		override = ""
		override_until = -1
	_apply(override if override != "" else str(schedule[0]["type"]))


## Force a weather type, for `minutes` game minutes or until cleared.
func set_weather(type: String, minutes: int = -1) -> void:
	if not profiles.has(type):
		push_warning("Weather: unknown type '%s'" % type)
		return
	override = type
	override_until = WorldTime.total_minutes() + minutes if minutes >= 0 else -1
	_apply(type)


func clear_override() -> void:
	override = ""
	override_until = -1
	update()


## The planned weather for the next `hours`: [{type, from, until}] in absolute minutes.
func forecast(hours: int = 24) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var from := WorldTime.total_minutes()
	var end := from + hours * 60
	for s in schedule:
		if from >= end:
			break
		out.append({"type": s["type"], "from": from, "until": mini(int(s["until"]), end)})
		from = int(s["until"])
	return out


func profile(type: String = "") -> Dictionary:
	return profiles.get(type if type != "" else current, profiles["clear"])


func is_wet() -> bool:
	return float(profile()["rain"]) > 0.0


func label(type: String = "") -> String:
	return (type if type != "" else current).replace("_", " ").capitalize()


func _apply(type: String) -> void:
	if type == current:
		return
	var prev := current
	current = type
	weather_changed.emit(current, prev)


func _fill() -> void:
	var horizon := WorldTime.total_minutes() + WorldTime.DAY_MINUTES
	while int(schedule[schedule.size() - 1]["until"]) < horizon:
		var last: Dictionary = schedule[schedule.size() - 1]
		var at := int(last["until"])
		schedule.append({"type": _roll(at, str(last["type"])), "until": at + _rng.randi_range(min_duration, max_duration)})


## Weighted pick for the season at absolute minute `at`; avoids repeating `previous`.
func _roll(at: int, previous: String) -> String:
	var season := WorldTime.calendar.season_of_day(at / WorldTime.DAY_MINUTES)
	var weights: Dictionary = season_weights.get(season, season_weights[0])
	var total := 0.0
	for t: String in weights:
		if t != previous:
			total += float(weights[t])
	if total <= 0.0:
		return previous
	var r := _rng.randf() * total
	for t: String in weights:
		if t == previous:
			continue
		r -= float(weights[t])
		if r <= 0.0:
			return t
	return previous


func _process(delta: float) -> void:
	if current != "heavy_rain" or WorldTime.is_paused():
		return
	_bolt -= delta
	if _bolt <= 0.0:
		_bolt = randf_range(7.0, 20.0)
		lightning.emit()


# --- persistence ------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"current": current,
		"schedule": schedule.duplicate(true),
		"override": override,
		"override_until": override_until,
		# 64-bit values do not survive JSON numbers
		"rng_seed": str(_rng.seed),
		"rng_state": str(_rng.state),
	}


func from_dict(d: Dictionary) -> void:
	if d.is_empty():
		reset()
		return
	schedule.clear()
	for s: Dictionary in d.get("schedule", []):
		schedule.append({"type": str(s["type"]), "until": int(s["until"])})
	override = str(d.get("override", ""))
	override_until = int(d.get("override_until", -1))
	if d.has("rng_seed"):
		_rng.seed = str(d["rng_seed"]).to_int()
		_rng.state = str(d["rng_state"]).to_int()
	if schedule.is_empty():
		schedule.append({"type": str(d.get("current", start_weather)), "until": WorldTime.total_minutes() + min_duration})
	current = str(d.get("current", start_weather))
	update()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed(&"debug_weather"):
		set_weather(TYPES[(TYPES.find(current) + 1) % TYPES.size()])
