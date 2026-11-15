class_name Data
## JSON content loading. All narrative content lives under res://data.

static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Data: missing %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Data: could not parse %s" % path)
	return parsed


static func load_dict(path: String) -> Dictionary:
	var v: Variant = load_json(path)
	if v is Dictionary:
		return v
	return {}
