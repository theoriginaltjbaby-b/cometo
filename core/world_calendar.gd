class_name WorldCalendar
extends RefCounted
## The in-game date: seven-day week, four seasons of 28 days, years. Pure data with
## no clock of its own; WorldTime (core/world_time_manager.gd) owns the one instance
## and advances it at midnight. Everything here is configurable before a game starts.
##
## Scheduled events are a hook for holidays, festivals and quests:
##   WorldTime.calendar.add_event("harvest_fair", 2, 20)        # every Autumn 20
##   WorldTime.calendar.events_today()                          # -> Array[Dictionary]

var season_names := PackedStringArray(["Spring", "Summer", "Autumn", "Winter"])
var weekday_names := PackedStringArray(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
var days_per_season := 28
## Shifts which weekday day 1 of year 1 falls on.
var weekday_offset := 0

var year := 1
## 0-based index into season_names.
var season := 0
## 1-based day of the season.
var day := 1

## {id, season, day, year (-1 = every year), data}
var events: Array[Dictionary] = []


func set_date(y: int, s: int, d: int) -> void:
	year = maxi(y, 1)
	season = posmod(s, season_names.size())
	day = clampi(d, 1, days_per_season)


## Moves to the next day. Returns which larger units rolled over.
func advance_day() -> Dictionary:
	var rolled := {"season": false, "year": false}
	day += 1
	if day > days_per_season:
		day = 1
		season += 1
		rolled["season"] = true
		if season >= season_names.size():
			season = 0
			year += 1
			rolled["year"] = true
	return rolled


func days_per_year() -> int:
	return days_per_season * season_names.size()


## Days since day 1 of year 1.
func total_days() -> int:
	return ((year - 1) * season_names.size() + season) * days_per_season + day - 1


## Season index for an absolute day count (used to plan weather ahead).
func season_of_day(total: int) -> int:
	return posmod(total / days_per_season, season_names.size())


func weekday() -> int:
	return posmod(total_days() + weekday_offset, weekday_names.size())


func weekday_name() -> String:
	return weekday_names[weekday()]


func season_name() -> String:
	return season_names[season]


## "Autumn 12 · Thursday"
func date_text() -> String:
	return "%s %d · %s" % [season_name(), day, weekday_name()]


func add_event(id: String, on_season: int, on_day: int, on_year: int = -1, data: Dictionary = {}) -> void:
	events.append({"id": id, "season": on_season, "day": on_day, "year": on_year, "data": data})


func events_on(on_season: int, on_day: int, on_year: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if int(e["season"]) == on_season and int(e["day"]) == on_day and (int(e["year"]) < 0 or int(e["year"]) == on_year):
			out.append(e)
	return out


func events_today() -> Array[Dictionary]:
	return events_on(season, day, year)


func to_dict() -> Dictionary:
	return {"year": year, "season": season, "day": day}


func from_dict(d: Dictionary) -> void:
	set_date(int(d.get("year", 1)), int(d.get("season", 0)), int(d.get("day", 1)))
