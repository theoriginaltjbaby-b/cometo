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


func slot_path(slot: String) -> String:
	return "user://save_%s.json" % slot


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save_game(slot: String = "manual") -> bool:
	if world == null:
		return false
	var data := {
		"version": VERSION,
		"time": Time.get_datetime_string_from_system(),
		"flags": GameState.to_dict(),
		"journal": Journal.to_dict(),
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
	world.call("restore_world", data.get("world", {}))
	loaded.emit(slot)
	return true


func delete_save(slot: String) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if autosave_enabled and world != null:
			save_game("auto")
