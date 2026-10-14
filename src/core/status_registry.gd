class_name StatusRegistry
extends RefCounted
## Tra cứu StatusData theo id. Nạp từ thư mục .tres hoặc đăng ký thủ công (dùng cho test).

var _by_id: Dictionary = {}


static func load_from_dir(dir_path: String) -> StatusRegistry:
	var registry := StatusRegistry.new()
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() != "tres":
			continue
		var data := load(dir_path.path_join(file_name)) as StatusData
		if data == null:
			push_error("StatusRegistry: không nạp được %s" % file_name)
			continue
		registry.register(data)
	return registry


## Từ chối status không hợp lệ hoặc trùng id.
func register(data: StatusData) -> bool:
	if data == null:
		return false
	var errors := data.validate()
	if not errors.is_empty():
		push_error("StatusRegistry: %s không hợp lệ: %s" % [data.id, errors])
		return false
	if _by_id.has(data.id):
		push_error("StatusRegistry: trùng id %s" % data.id)
		return false
	_by_id[data.id] = data
	return true


func get_status(status_id: StringName) -> StatusData:
	return _by_id.get(status_id) as StatusData


func has_status(status_id: StringName) -> bool:
	return _by_id.has(status_id)


func size() -> int:
	return _by_id.size()
