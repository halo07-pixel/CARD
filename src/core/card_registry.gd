class_name CardRegistry
extends ResourceRegistry
## Tra cứu CardData theo id và tạo CardInstance từ danh sách id (dạng RunState lưu).


static func load_from_dir(dir_path: String) -> CardRegistry:
	var registry := CardRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_card(card_id: StringName) -> CardData:
	return _find(card_id) as CardData


func has_card(card_id: StringName) -> bool:
	return has_id(card_id)


## Các id (không trùng lặp) không có trong registry.
func missing_ids(ids: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	for id in ids:
		if not has_card(id) and not missing.has(id):
			missing.append(id)
	return missing


## Mỗi id -> một CardInstance riêng. Có id lạ thì trả về mảng RỖNG (không tạo nửa chừng).
func create_instances(ids: Array[StringName]) -> Array[CardInstance]:
	var instances: Array[CardInstance] = []
	var missing := missing_ids(ids)
	if not missing.is_empty():
		push_error("CardRegistry: thiếu thẻ %s" % [missing])
		return instances
	for id in ids:
		instances.append(CardInstance.create(get_card(id)))
	return instances


## Lỗi liên kết giữa các thẻ: upgraded_id trỏ tới thẻ không tồn tại.
func link_errors() -> Array[String]:
	var errors: Array[String] = []
	for card: CardData in _by_id.values():
		if not card.upgraded_id.is_empty() and not has_card(card.upgraded_id):
			errors.append("%s -> upgraded_id '%s' không tồn tại" % [card.id, card.upgraded_id])
	return errors


func _id_of(resource: Resource) -> StringName:
	return (resource as CardData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as CardData
	if data == null:
		var wrong_type: Array[String] = ["không phải CardData"]
		return wrong_type
	return data.validate()
