extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const RELIC_DIR := "res://data/relics"
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target


func _relic(id: StringName = &"r", triggers: Array = [], props: Dictionary = {}) -> RelicData:
	var data := RelicData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	var typed: Array[TriggerData] = []
	typed.assign(triggers)
	data.triggers = typed
	for key: String in props:
		data.set(key, props[key])
	return data


func _block_trigger() -> TriggerData:
	return Factory.trigger1(E.BATTLE_START, EffectData.create(T.BLOCK, 5, G.SELF))


func test_valid_relics() -> void:
	assert_eq(_relic(&"a", [_block_trigger()]).validate(), [] as Array[String])
	assert_eq(_relic(&"b", [], {"max_energy_bonus": 1}).validate(), [] as Array[String], "chỉ có bonus tĩnh")
	assert_eq(_relic(&"c", [], {"draw_per_turn_bonus": 2}).validate(), [] as Array[String])


func test_relic_must_do_something() -> void:
	assert_false(_relic(&"empty").validate().is_empty())


func test_basic_field_rules() -> void:
	assert_false(_relic(&"", [_block_trigger()]).validate().is_empty(), "id trống")
	var nameless := _relic(&"x", [_block_trigger()])
	nameless.display_name = "  "
	assert_false(nameless.validate().is_empty())
	assert_false(_relic(&"n", [], {"max_energy_bonus": -1}).validate().is_empty(), "bonus âm")
	assert_false(_relic(&"n", [_block_trigger()], {"draw_per_turn_bonus": -1}).validate().is_empty())


func test_trigger_errors_are_reported_with_index() -> void:
	var bad := _relic(&"x", [TriggerData.new()])
	var errors := bad.validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("triggers[0]"))
	var with_null := _relic(&"y")
	with_null.triggers = [null] as Array[TriggerData]
	assert_false(with_null.validate().is_empty())


func test_has_static_bonus() -> void:
	assert_false(_relic(&"a", [_block_trigger()]).has_static_bonus())
	assert_true(_relic(&"b", [], {"max_energy_bonus": 1}).has_static_bonus())
	assert_true(_relic(&"c", [], {"draw_per_turn_bonus": 1}).has_static_bonus())


func test_new_enum_values_keep_old_numbers() -> void:
	assert_eq([RelicData.Rarity.STARTER, RelicData.Rarity.COMMON, RelicData.Rarity.UNCOMMON,
			RelicData.Rarity.RARE, RelicData.Rarity.BOSS, RelicData.Rarity.SHOP], [0, 1, 2, 3, 4, 5])


## --- Dữ liệu thật ---

func test_starter_relics_are_valid_and_have_designed_values() -> void:
	var registry := RelicRegistry.load_from_dir(RELIC_DIR)
	assert_eq(registry.size(), 10, "10 relic mẫu (file lỗi/trùng id sẽ bị loại)")
	for id in registry.all_ids():
		assert_eq(registry.get_relic(id).validate(), [] as Array[String], String(id))
	var blood := registry.get_relic(&"burning_blood")
	assert_eq(blood.rarity, RelicData.Rarity.STARTER)
	assert_eq(blood.character_id, &"warrior")
	assert_eq(blood.triggers[0].event, E.BATTLE_VICTORY)
	assert_eq([blood.triggers[0].effects[0].type, blood.triggers[0].effects[0].amount], [T.HEAL, 6])
	var anchor := registry.get_relic(&"anchor")
	assert_eq([anchor.triggers[0].event, anchor.triggers[0].effects[0].type, anchor.triggers[0].effects[0].amount],
			[E.BATTLE_START, T.BLOCK, 10])
	assert_eq(registry.get_relic(&"vajra").triggers[0].effects[0].status_id, &"strength")
	var lantern := registry.get_relic(&"lantern")
	assert_eq([lantern.triggers[0].event, lantern.triggers[0].max_per_battle], [E.TURN_START, 1])
	assert_eq(registry.get_relic(&"bag_of_preparation").triggers[0].effects[0].type, T.DRAW)
	assert_eq(registry.get_relic(&"happy_flower").triggers[0].every_n, 3)
	var oric := registry.get_relic(&"orichalcum")
	assert_eq([oric.triggers[0].event, oric.triggers[0].requires_zero_block], [E.TURN_END, true])
	var scales := registry.get_relic(&"bronze_scales")
	assert_eq([scales.triggers[0].effects[0].status_id, scales.triggers[0].effects[0].amount], [&"thorns", 3])
	var crystal := registry.get_relic(&"energy_crystal")
	assert_eq([crystal.max_energy_bonus, crystal.triggers.size(), crystal.rarity], [1, 0, RelicData.Rarity.BOSS])
	assert_eq(registry.get_relic(&"wide_lens").draw_per_turn_bonus, 1)


## --- Registry ---

func test_registry_rejects_wrong_type_duplicate_invalid_and_null() -> void:
	var registry := RelicRegistry.new()
	assert_true(registry.register(_relic(&"a", [_block_trigger()])))
	assert_false(registry.register(_relic(&"a", [_block_trigger()])), "trùng id")
	assert_false(registry.register(RelicData.new()), "không hợp lệ")
	assert_false(registry.register(Factory.weak()), "sai kiểu (StatusData)")
	assert_false(registry.register(null))
	assert_eq(registry.size(), 1)
	assert_true(registry.get_relic(&"nope") == null)
	assert_true(registry.has_relic(&"a"))


func test_resolve_keeps_order_and_returns_nothing_for_unknown_ids() -> void:
	var registry := RelicRegistry.load_from_dir(RELIC_DIR)
	var ids: Array[StringName] = [&"vajra", &"anchor"]
	var relics := registry.resolve(ids)
	assert_eq(relics.map(func(r: RelicData) -> StringName: return r.id), [&"vajra", &"anchor"])
	var bad: Array[StringName] = [&"vajra", &"ghost"]
	assert_eq(registry.resolve(bad).size(), 0, "không trả nửa chừng")
	var dupes: Array[StringName] = [&"ghost", &"phantom", &"ghost"]
	assert_eq(registry.missing_ids(dupes), [&"ghost", &"phantom"] as Array[StringName])
	var none: Array[StringName] = []
	assert_eq(registry.resolve(none).size(), 0)
