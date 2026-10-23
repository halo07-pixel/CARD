class_name RelicRegistry
extends ResourceRegistry
## Tra cứu RelicData theo id và đổi danh sách id (dạng RunState lưu) thành danh sách RelicData.


static func load_from_dir(dir_path: String) -> RelicRegistry:
	var registry := RelicRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_relic(relic_id: StringName) -> RelicData:
	return _find(relic_id) as RelicData


func has_relic(relic_id: StringName) -> bool:
	return has_id(relic_id)


## Các id (không trùng lặp) không có trong registry.
func missing_ids(ids: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	for id in ids:
		if not has_relic(id) and not missing.has(id):
			missing.append(id)
	return missing


## Danh sách RelicData theo đúng thứ tự id. Có id lạ thì trả về mảng RỖNG (không trả nửa chừng).
func resolve(ids: Array[StringName]) -> Array[RelicData]:
	var relics: Array[RelicData] = []
	var missing := missing_ids(ids)
	if not missing.is_empty():
		push_error("RelicRegistry: thiếu relic %s" % [missing])
		return relics
	for id in ids:
		relics.append(get_relic(id))
	return relics


func _id_of(resource: Resource) -> StringName:
	return (resource as RelicData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as RelicData
	if data == null:
		var wrong_type: Array[String] = ["không phải RelicData"]
		return wrong_type
	return data.validate()
