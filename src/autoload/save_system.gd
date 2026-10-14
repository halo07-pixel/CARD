extends Node
## Lưu/đọc JSON cho run và settings. Ghi nguyên tử (tmp -> rename).
## Lưu ý: JSON biến mọi số thành float, nơi đọc phải ép kiểu lại.

const SAVE_VERSION := 1
const RUN_FILE := "run.json"
const SETTINGS_FILE := "settings.json"
const DEFAULT_SETTINGS := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"fullscreen": false,
}

## Có thể đổi trong test để không đụng save thật.
var save_dir: String = "user://"


func save_run(data: Dictionary) -> bool:
	return _write_json(RUN_FILE, data)


func load_run() -> Dictionary:
	return _read_json(RUN_FILE)


func has_run() -> bool:
	return FileAccess.file_exists(_path(RUN_FILE))


func delete_run() -> void:
	_delete(RUN_FILE)


func save_settings(settings: Dictionary) -> bool:
	return _write_json(SETTINGS_FILE, settings)


## Luôn trả về đủ khóa mặc định; khóa lạ trong file bị loại bỏ.
func load_settings() -> Dictionary:
	var result: Dictionary = DEFAULT_SETTINGS.duplicate()
	var loaded := _read_json(SETTINGS_FILE)
	for key: String in DEFAULT_SETTINGS:
		if not loaded.has(key):
			continue
		var default_value: Variant = DEFAULT_SETTINGS[key]
		var value: Variant = loaded[key]
		if typeof(value) == typeof(default_value):
			result[key] = value
		elif typeof(default_value) == TYPE_FLOAT and typeof(value) == TYPE_INT:
			result[key] = float(value)
	return result


func _path(file_name: String) -> String:
	return save_dir.path_join(file_name)


func _write_json(file_name: String, data: Dictionary) -> bool:
	var final_path := _path(file_name)
	var tmp_path := final_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: không mở được %s (lỗi %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "data": data}))
	file.close()
	var dir := DirAccess.open(save_dir)
	if dir == null:
		push_error("SaveSystem: không mở được thư mục %s" % save_dir)
		return false
	var err := dir.rename(tmp_path.get_file(), final_path.get_file())
	if err != OK:
		push_error("SaveSystem: rename thất bại (lỗi %d)" % err)
		return false
	return true


## Trả về {} nếu thiếu file, hỏng JSON, sai version hoặc sai cấu trúc.
func _read_json(file_name: String) -> Dictionary:
	var path := _path(file_name)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveSystem: %s hỏng hoặc không phải JSON object" % path)
		return {}
	var envelope: Dictionary = parsed
	if int(envelope.get("version", -1)) != SAVE_VERSION or typeof(envelope.get("data")) != TYPE_DICTIONARY:
		push_warning("SaveSystem: %s sai version/cấu trúc" % path)
		return {}
	return envelope["data"]


func _delete(file_name: String) -> void:
	var path := _path(file_name)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
