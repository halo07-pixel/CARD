extends SceneTree
## Sinh 5 trạng thái ban đầu. Chạy: godot --headless --path . -s res://tools/generate_starter_statuses.gd
## Sau khi sinh, các file .tres là nguồn dữ liệu chính (sửa tay hoặc trong editor đều được).

const OUT_DIR := "res://data/statuses/"
const S := StatusData.StackMode


func _initialize() -> void:
	var all: Array[StatusData] = [
		_make(&"strength", "Strength", "Deals +1 damage per stack with attacks.", false, S.INTENSITY,
				{"can_be_negative": true, "damage_dealt_add_per_stack": 1.0}),
		_make(&"dexterity", "Dexterity", "Gain +1 Block per stack from cards.", false, S.INTENSITY,
				{"can_be_negative": true, "block_gain_add_per_stack": 1.0}),
		_make(&"vulnerable", "Vulnerable", "Takes 50% more damage. Decreases each turn.", true, S.DURATION,
				{"decays_at_turn_end": true, "damage_taken_mult": 1.5}),
		_make(&"weak", "Weak", "Deals 25% less damage. Decreases each turn.", true, S.DURATION,
				{"decays_at_turn_end": true, "damage_dealt_mult": 0.75}),
		_make(&"frail", "Frail", "Gain 25% less Block from cards. Decreases each turn.", true, S.DURATION,
				{"decays_at_turn_end": true, "block_gain_mult": 0.75}),
	]
	var ok := true
	for status in all:
		ok = _save(status) and ok
	quit(0 if ok else 1)


func _make(id: StringName, display_name: String, description: String, is_debuff: bool,
		stack_mode: StatusData.StackMode, props: Dictionary) -> StatusData:
	var status := StatusData.new()
	status.id = id
	status.display_name = display_name
	status.description = description
	status.is_debuff = is_debuff
	status.stack_mode = stack_mode
	status.icon_id = id
	for key: String in props:
		status.set(key, props[key])
	return status


func _save(status: StatusData) -> bool:
	var errors := status.validate()
	if not errors.is_empty():
		printerr("Status %s không hợp lệ: %s" % [status.id, errors])
		return false
	var err := ResourceSaver.save(status, OUT_DIR + String(status.id) + ".tres")
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [status.id, err])
		return false
	print("đã tạo ", status.id)
	return true
