@abstract
class_name ResourceRegistry
extends RefCounted
## Lớp gốc cho mọi "thư viện tra cứu theo id" (status, quái, thẻ...). Gom phần nạp thư mục,
## kiểm tra hợp lệ và chống trùng id vào MỘT chỗ. Lớp con chỉ khai báo cách lấy id và cách validate.

var _by_id: Dictionary = {}


@abstract func _id_of(resource: Resource) -> StringName

## Trả về danh sách lỗi (rỗng = hợp lệ). Phải tự kiểm tra đúng kiểu tài nguyên.
@abstract func _validate(resource: Resource) -> Array[String]


## Từ chối tài nguyên null, sai kiểu/không hợp lệ hoặc trùng id.
func register(resource: Resource) -> bool:
	if resource == null:
		return false
	var errors := _validate(resource)
	if not errors.is_empty():
		push_error("ResourceRegistry: '%s' không hợp lệ: %s" % [resource.resource_path, errors])
		return false
	var id := _id_of(resource)
	if _by_id.has(id):
		push_error("ResourceRegistry: trùng id '%s'" % id)
		return false
	_by_id[id] = resource
	return true


func has_id(id: StringName) -> bool:
	return _by_id.has(id)


func size() -> int:
	return _by_id.size()


func _find(id: StringName) -> Resource:
	return _by_id.get(id) as Resource


## Nạp mọi file .tres trong thư mục; file lỗi/trùng id bị loại và được ghi log.
func _load_dir(dir_path: String) -> void:
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() != "tres":
			continue
		var resource := load(dir_path.path_join(file_name)) as Resource
		if resource == null:
			push_error("ResourceRegistry: không nạp được %s" % file_name)
			continue
		register(resource)
