extends Node
## Autoload "WorldTime": the one authoritative world clock and calendar.
##
## A 24-hour clock that runs while the game runs (1 real second = 1 game minute by
## default), stops with the scene tree (menus, journal), during dialogue, and for any
## reason a system registers with pause(). Midnight advances the WorldCalendar.
##
## Other systems listen to signals or ask; nothing else keeps its own timer:
##   WorldTime.hour_changed.connect(...)          # shops, NPC routines
##   WorldTime.period_changed.connect(...)        # "dawn" "morning" "midday" ...
##   WorldTime.is_between(9, 17)                  # opening hours (wraps past midnight)
##   WorldTime.sleep_until(6)                     # bed
##   WorldTime.advance_minutes(90)                # waiting
##   WorldTime.pause("cutscene") / resume("cutscene")
##   WorldTime.set_time(12, 0)                    # testing
## Debug builds: ] advances an hour, [ advances a day.

signal minute_changed(hour: int, minute: int)
signal hour_changed(hour: int)
signal day_changed(calendar: WorldCalendar)
signal season_changed(season: int)
signal year_changed(year: int)
signal period_changed(period: String, previous: String)
## The clock was set, loaded or skipped ahead: listeners should snap to the new state
## instead of blending toward it.
signal time_jumped
## A calendar event (WorldCalendar.add_event) falls on the day that just began.
signal event_due(event: Dictionary)

const DAY_MINUTES := 1440

## Game minutes per real second. 0 stops the clock.
var minutes_per_second := 1.0
## Day periods, each from its start (minutes after midnight) to the next one's start.
## The last wraps past midnight to the first.
var periods: Array[Dictionary] = [
	{"name": "dawn", "start": 5 * 60},
	{"name": "morning", "start": 7 * 60},
	{"name": "midday", "start": 11 * 60},
	{"name": "afternoon", "start": 15 * 60},
	{"name": "evening", "start": 18 * 60},
	{"name": "night", "start": 20 * 60},
]
## Where a new game begins. season is a 0-based index (2 = Autumn).
var start := {"year": 1, "season": 2, "day": 12, "hour": 18, "minute": 40}
var pause_in_dialogue := true
## Lets cinematics hide the clock HUD without stopping time.
var hud_hidden := false

var calendar := WorldCalendar.new()
var hour := 0
var minute := 0

var _frac := 0.0
var _pauses := {}
var _period := ""


func _ready() -> void:
	# so that Autumn 12 of year 1 is a Thursday
	calendar.weekday_offset = 6
	reset()


func reset() -> void:
	calendar.set_date(int(start["year"]), int(start["season"]), int(start["day"]))
	hour = int(start["hour"])
	minute = int(start["minute"])
	_frac = 0.0
	_pauses.clear()
	_period = period()
	time_jumped.emit()


# --- running ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if is_paused():
		return
	_frac += delta * minutes_per_second
	while _frac >= 1.0:
		_frac -= 1.0
		_tick()


## Stop the clock for a named reason; it runs again when every reason is resumed.
func pause(reason: String) -> void:
	_pauses[reason] = true


func resume(reason: String) -> void:
	_pauses.erase(reason)


func is_paused() -> bool:
	return minutes_per_second <= 0.0 or not _pauses.is_empty() or (pause_in_dialogue and Dialogue.active)


func _tick() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
		if hour >= 24:
			hour = 0
			_next_day()
		hour_changed.emit(hour)
	minute_changed.emit(hour, minute)
	_check_period()


func _next_day() -> void:
	var rolled := calendar.advance_day()
	day_changed.emit(calendar)
	if rolled["season"]:
		season_changed.emit(calendar.season)
	if rolled["year"]:
		year_changed.emit(calendar.year)
	for e in calendar.events_today():
		event_due.emit(e)


func _check_period() -> void:
	var p := period()
	if p != _period:
		var prev := _period
		_period = p
		period_changed.emit(p, prev)


# --- moving the clock -------------------------------------------------------------

## Advance by a number of game minutes. Short waits tick minute by minute so every
## signal fires; long ones jump (one signal per day crossed, then time_jumped).
func advance_minutes(n: int) -> void:
	if n <= 0:
		return
	if n <= 180:
		for i in n:
			_tick()
		return
	var total := minute_of_day() + n
	for i in total / DAY_MINUTES:
		_next_day()
	var rem := total % DAY_MINUTES
	hour = rem / 60
	minute = rem % 60
	_frac = 0.0
	hour_changed.emit(hour)
	minute_changed.emit(hour, minute)
	_check_period()
	time_jumped.emit()


## Minutes from now until the next time the clock reads h:m.
func minutes_until(h: int, m: int = 0) -> int:
	var d := posmod(h * 60 + m - minute_of_day(), DAY_MINUTES)
	return d if d > 0 else DAY_MINUTES


## Skip ahead to the next h:m (sleeping, resting until morning).
func sleep_until(h: int, m: int = 0) -> void:
	var n := minutes_until(h, m)
	advance_minutes(n)
	if n <= 180:
		time_jumped.emit()


## Set the clock directly without advancing the calendar. For testing and scripted scenes.
func set_time(h: int, m: int = 0) -> void:
	hour = posmod(h, 24)
	minute = clampi(m, 0, 59)
	_frac = 0.0
	hour_changed.emit(hour)
	minute_changed.emit(hour, minute)
	_check_period()
	time_jumped.emit()


func set_date(year: int, season: int, day: int) -> void:
	calendar.set_date(year, season, day)
	day_changed.emit(calendar)
	time_jumped.emit()


# --- asking -----------------------------------------------------------------------

func minute_of_day() -> int:
	return hour * 60 + minute


## Minutes since midnight of day 1, year 1. Use for durations and schedules.
func total_minutes() -> int:
	return calendar.total_days() * DAY_MINUTES + minute_of_day()


## 0..1 through the day, continuous between minutes (drives the lighting).
func day_fraction() -> float:
	return (float(minute_of_day()) + _frac) / float(DAY_MINUTES)


func period() -> String:
	var now := minute_of_day()
	var name := str(periods[periods.size() - 1]["name"])
	for p in periods:
		if now >= int(p["start"]):
			name = str(p["name"])
	return name


func is_night() -> bool:
	return period() == "night"


## True from hour a up to hour b; wraps past midnight (is_between(22, 6)).
func is_between(a: float, b: float) -> bool:
	var h := float(minute_of_day()) / 60.0
	return (h >= a and h < b) if a <= b else (h >= a or h < b)


## "6:42 PM"
func time_text() -> String:
	var h := hour % 12
	return "%d:%02d %s" % [12 if h == 0 else h, minute, "AM" if hour < 12 else "PM"]


func date_text() -> String:
	return calendar.date_text()


# --- persistence ------------------------------------------------------------------

func to_dict() -> Dictionary:
	var d := calendar.to_dict()
	d["hour"] = hour
	d["minute"] = minute
	d["frac"] = _frac
	d["rate"] = minutes_per_second
	return d


func from_dict(d: Dictionary) -> void:
	if d.is_empty():
		reset()
		return
	calendar.from_dict(d)
	hour = clampi(int(d.get("hour", 0)), 0, 23)
	minute = clampi(int(d.get("minute", 0)), 0, 59)
	_frac = clampf(float(d.get("frac", 0.0)), 0.0, 0.999)
	minutes_per_second = float(d.get("rate", 1.0))
	_pauses.clear()
	_period = period()
	time_jumped.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed(&"debug_hour"):
		advance_minutes(60)
		time_jumped.emit()
	elif event.is_action_pressed(&"debug_day"):
		advance_minutes(DAY_MINUTES)
