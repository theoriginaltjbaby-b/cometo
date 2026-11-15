extends Node
## Save anywhere. One JSON file per slot under user://. "auto" is written whenever
## the app is backgrounded or closed and is resumed on boot, so a five-minute
## session never loses anything.
##
## The active world (game/main.gd) registers itself and provides
## capture_world() -> Dictionary and restore_world(Dictionary).

signal saved(slot: String)
signal loaded(slot: String)

const VERSION := 1

var world: Node = null
var autosave_enabled := true
var boot_from_autosave := true
## Folder the slots live in. Tests point this at a scratch folder.
var dir := "user://"


func slot_path(slot: String) -> String:
	return dir.path_join("save_%s.json" % slot)


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: String = "manual") -> bool:
	if world == null or not world.is_inside_tree():
		return false
	var data := {
		"version": VERSION,
		"time": Time.get_datetime_string_from_system(),
		"flags": GameState.to_dict(),
		"journal": Journal.to_dict(),
		"world_time": WorldTime.to_dict(),
		"weather": Weather.to_dict(),
		"world": world.call("capture_world"),
	}
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % tmp)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		push_error("SaveManager: cannot finalise %s" % path)
		return false
	saved.emit(slot)
	return true


func load_game(slot: String = "manual") -> bool:
	if world == null or not has_save(slot):
		return false
	var data: Dictionary = Data.load_dict(slot_path(slot))
	if data.is_empty() or int(data.get("version", 0)) != VERSION:
		push_warning("SaveManager: save '%s' is unreadable or from another version" % slot)
		return false
	GameState.from_dict(data.get("flags", {}))
	Journal.from_dict(data.get("journal", {}))
	# clock first: the weather schedule is read against it, and the map built by
	# restore_world() lights itself from both straight away
	WorldTime.from_dict(data.get("world_time", {}))
	Weather.from_dict(data.get("weather", {}))
	world.call("restore_world", data.get("world", {}))
	loaded.emit(slot)
	return true


## Slots that hold a readable save from this version, newest first:
## [{slot, saved, map, when}] where `when` is the in-game date and time.
func list_saves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.begins_with("save_") and f.ends_with(".json"):
			var info := slot_info(f.trim_prefix("save_").trim_suffix(".json"))
			if not info.is_empty():
				out.append(info)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["saved"]) > str(b["saved"]))
	return out


## Summary of one slot, or {} if it is missing, unreadable or from another version.
func slot_info(slot: String) -> Dictionary:
	if not has_save(slot):
		return {}
	# parsed quietly: a damaged file is simply not offered
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(slot_path(slot))) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	if int(data.get("version", 0)) != VERSION or not data.get("world") is Dictionary:
		return {}
	return {
		"slot": slot,
		"saved": str(data.get("time", "")),
		"map": str((data["world"] as Dictionary).get("map", "")),
		"when": WorldTime.describe(data.get("world_time", {})),
	}


func delete_save(slot: String) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if autosave_enabled and world != null and world.is_inside_tree():
			save_game("auto")
