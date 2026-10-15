class_name StatusRegistry
extends ResourceRegistry
## Tra cứu StatusData theo id. Nạp từ thư mục .tres hoặc đăng ký thủ công (dùng cho test).


static func load_from_dir(dir_path: String) -> StatusRegistry:
	var registry := StatusRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_status(status_id: StringName) -> StatusData:
	return _find(status_id) as StatusData


func has_status(status_id: StringName) -> bool:
	return has_id(status_id)


func _id_of(resource: Resource) -> StringName:
	return (resource as StatusData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as StatusData
	if data == null:
		var wrong_type: Array[String] = ["không phải StatusData"]
		return wrong_type
	return data.validate()
