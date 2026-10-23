extends SceneTree
## Sinh relic mẫu. Chạy: godot --headless --path . -s res://tools/generate_starter_relics.gd
## KHÔNG ghi đè file đã có (file .tres là nguồn dữ liệu chính, đã có thể được chỉnh tay/trong editor).

const OUT_DIR := "res://data/relics/"
const R := RelicData.Rarity
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target


func _initialize() -> void:
	var relics: Array[RelicData] = [
		_make(&"burning_blood", "Burning Blood", "At the end of combat, heal 6 HP.", R.STARTER, &"warrior",
				[_trigger(E.BATTLE_VICTORY, EffectData.create(T.HEAL, 6, G.SELF))], {}),
		_make(&"anchor", "Anchor", "Start each combat with 10 Block.", R.COMMON, &"",
				[_trigger(E.BATTLE_START, EffectData.create(T.BLOCK, 10, G.SELF))], {}),
		_make(&"vajra", "Vajra", "At the start of each combat, gain 1 Strength.", R.COMMON, &"",
				[_trigger(E.BATTLE_START, EffectData.create(T.APPLY_STATUS, 1, G.SELF, 1, &"strength"))], {}),
		_make(&"lantern", "Lantern", "Gain 1 Energy on the first turn of each combat.", R.COMMON, &"",
				[_trigger(E.TURN_START, EffectData.create(T.GAIN_ENERGY, 1, G.SELF), {"max_per_battle": 1})], {}),
		_make(&"bag_of_preparation", "Bag of Preparation", "At the start of each combat, draw 2 additional cards.",
				R.COMMON, &"", [_trigger(E.BATTLE_START, EffectData.create(T.DRAW, 2, G.SELF))], {}),
		_make(&"happy_flower", "Happy Flower", "Every 3 turns, gain 1 Energy.", R.COMMON, &"",
				[_trigger(E.TURN_START, EffectData.create(T.GAIN_ENERGY, 1, G.SELF), {"every_n": 3})], {}),
		_make(&"orichalcum", "Orichalcum", "If you end your turn without Block, gain 6 Block.", R.COMMON, &"",
				[_trigger(E.TURN_END, EffectData.create(T.BLOCK, 6, G.SELF), {"requires_zero_block": true})], {}),
		_make(&"bronze_scales", "Bronze Scales", "Start each combat with 3 Thorns.", R.COMMON, &"",
				[_trigger(E.BATTLE_START, EffectData.create(T.APPLY_STATUS, 3, G.SELF, 1, &"thorns"))], {}),
		_make(&"energy_crystal", "Energy Crystal", "Gain 1 additional Energy each turn.", R.BOSS, &"",
				[], {"max_energy_bonus": 1}),
		_make(&"wide_lens", "Wide Lens", "Draw 1 additional card each turn.", R.UNCOMMON, &"",
				[], {"draw_per_turn_bonus": 1}),
	]
	var ok := true
	for relic in relics:
		ok = _save(relic) and ok
	quit(0 if ok else 1)


func _trigger(event: TriggerData.Event, effect: EffectData, props: Dictionary = {}) -> TriggerData:
	var trigger := TriggerData.new()
	trigger.event = event
	var effects: Array[EffectData] = [effect]
	trigger.effects = effects
	for key: String in props:
		trigger.set(key, props[key])
	return trigger


func _make(id: StringName, display_name: String, description: String, rarity: RelicData.Rarity,
		character_id: StringName, triggers: Array[TriggerData], props: Dictionary) -> RelicData:
	var relic := RelicData.new()
	relic.id = id
	relic.display_name = display_name
	relic.description = description
	relic.rarity = rarity
	relic.character_id = character_id
	relic.triggers = triggers
	relic.icon_id = id
	for key: String in props:
		relic.set(key, props[key])
	return relic


func _save(relic: RelicData) -> bool:
	var errors := relic.validate()
	if not errors.is_empty():
		printerr("Relic %s không hợp lệ: %s" % [relic.id, errors])
		return false
	var path := OUT_DIR + String(relic.id) + ".tres"
	if FileAccess.file_exists(path):
		print("đã có, bỏ qua ", relic.id)
		return true
	var err := ResourceSaver.save(relic, path)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [relic.id, err])
		return false
	print("đã tạo ", relic.id)
	return true
