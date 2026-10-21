extends SceneTree
## Sinh các trạng thái mẫu. Chạy: godot --headless --path . -s res://tools/generate_starter_statuses.gd
## KHÔNG ghi đè file đã có (file .tres là nguồn dữ liệu chính, đã có thể được chỉnh tay/trong editor).

const OUT_DIR := "res://data/statuses/"
const S := StatusData.StackMode
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target


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
		_make(&"poison", "Poison", "At the start of its turn, lose 1 HP per stack, then decrease by 1.", true, S.DURATION,
				{"decay_after_turn_start": true,
				"triggers": _triggers([_trigger(E.TURN_START, EffectData.create(T.LOSE_HP, 1, G.SELF), {"scale_by_stacks": true})])}),
		_make(&"metallicize", "Metallicize", "At the end of your turn, gain 1 Block per stack.", false, S.INTENSITY,
				{"triggers": _triggers([_trigger(E.TURN_END, EffectData.create(T.BLOCK, 1, G.SELF), {"scale_by_stacks": true})])}),
		_make(&"thorns", "Thorns", "Whenever you are attacked, deal 1 damage to the attacker per stack.", false, S.INTENSITY,
				{"triggers": _triggers([_trigger(E.ATTACKED, EffectData.create(T.DAMAGE, 1, G.EVENT_SOURCE), {"scale_by_stacks": true})])}),
		_make(&"demon_form", "Demon Form", "At the start of your turn, gain 1 Strength per stack.", false, S.INTENSITY,
				{"triggers": _triggers([_trigger(E.TURN_START,
						EffectData.create(T.APPLY_STATUS, 1, G.SELF, 1, &"strength"), {"scale_by_stacks": true})])}),
		_make(&"artifact", "Artifact", "Negates the next debuff per stack.", false, S.INTENSITY,
				{"negates_debuff": true}),
		_make(&"barricade", "Barricade", "Block is not removed at the start of your turn.", false, S.INTENSITY,
				{"retains_block": true}),
	]
	var ok := true
	for status in all:
		ok = _save(status) and ok
	quit(0 if ok else 1)


func _trigger(event: TriggerData.Event, effect: EffectData, props: Dictionary = {}) -> TriggerData:
	var trigger := TriggerData.new()
	trigger.event = event
	var effects: Array[EffectData] = [effect]
	trigger.effects = effects
	for key: String in props:
		trigger.set(key, props[key])
	return trigger


func _triggers(list: Array[TriggerData]) -> Array[TriggerData]:
	return list


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
	var path := OUT_DIR + String(status.id) + ".tres"
	if FileAccess.file_exists(path):
		print("đã có, bỏ qua ", status.id)
		return true
	var err := ResourceSaver.save(status, path)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [status.id, err])
		return false
	print("đã tạo ", status.id)
	return true
