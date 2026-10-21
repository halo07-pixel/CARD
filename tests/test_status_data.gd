extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const STATUS_DIR := "res://data/statuses"
const S := StatusData.StackMode


func test_factory_statuses_are_valid() -> void:
	for data: StatusData in [Factory.strength(), Factory.dexterity(), Factory.vulnerable(),
			Factory.weak(), Factory.frail()]:
		assert_eq(data.validate(), [] as Array[String], String(data.id))


func test_empty_id_and_name_are_invalid() -> void:
	assert_true(StatusData.new().validate().size() >= 2)


func test_only_intensity_can_be_negative() -> void:
	assert_false(Factory.status(&"x", S.DURATION, {"can_be_negative": true}).validate().is_empty())
	assert_true(Factory.status(&"x", S.INTENSITY, {"can_be_negative": true}).validate().is_empty())


func test_only_duration_decays() -> void:
	assert_false(Factory.status(&"x", S.INTENSITY, {"decays_at_turn_end": true}).validate().is_empty())


func test_duration_cannot_use_add_per_stack() -> void:
	assert_false(Factory.status(&"x", S.DURATION, {"damage_dealt_add_per_stack": 1.0}).validate().is_empty())
	assert_false(Factory.status(&"x", S.DURATION, {"block_gain_add_per_stack": 1.0}).validate().is_empty())


func test_negative_multiplier_is_invalid() -> void:
	assert_false(Factory.status(&"x", S.DURATION, {"damage_taken_mult": -0.5}).validate().is_empty())


func test_registry_rejects_duplicates_invalid_and_null() -> void:
	var registry := StatusRegistry.new()
	assert_true(registry.register(Factory.weak()))
	assert_false(registry.register(Factory.weak()), "trùng id")
	assert_false(registry.register(StatusData.new()), "không hợp lệ")
	assert_false(registry.register(null))
	assert_eq(registry.size(), 1)
	assert_true(registry.get_status(&"nope") == null)


func test_starter_status_files_are_valid_and_have_expected_values() -> void:
	var registry := StatusRegistry.load_from_dir(STATUS_DIR)
	assert_eq(registry.size(), 11, "5 status Giai đoạn 1 + 6 status Giai đoạn 2.1 (file lỗi/trùng id sẽ bị loại)")
	assert_almost_eq(registry.get_status(&"strength").damage_dealt_add_per_stack, 1.0)
	assert_almost_eq(registry.get_status(&"dexterity").block_gain_add_per_stack, 1.0)
	assert_almost_eq(registry.get_status(&"vulnerable").damage_taken_mult, 1.5)
	assert_almost_eq(registry.get_status(&"weak").damage_dealt_mult, 0.75)
	assert_almost_eq(registry.get_status(&"frail").block_gain_mult, 0.75)
	assert_true(registry.get_status(&"strength").can_be_negative)
	assert_true(registry.get_status(&"weak").decays_at_turn_end)
	assert_false(registry.get_status(&"strength").is_debuff)
	assert_true(registry.get_status(&"vulnerable").is_debuff)


func test_new_flag_rules() -> void:
	assert_false(Factory.status(&"x", S.INTENSITY, {"negates_debuff": true, "is_debuff": true}).validate().is_empty())
	assert_true(Factory.status(&"x", S.INTENSITY, {"negates_debuff": true}).validate().is_empty())
	assert_false(Factory.status(&"x", S.INTENSITY, {"decay_after_turn_start": true}).validate().is_empty())
	assert_true(Factory.status(&"x", S.DURATION, {"decay_after_turn_start": true}).validate().is_empty())
	assert_true(Factory.status(&"x", S.INTENSITY, {"retains_block": true}).validate().is_empty())


func test_trigger_errors_are_reported_with_index() -> void:
	var bad := TriggerData.new()  # không có effect
	var triggers: Array[TriggerData] = [bad]
	var errors := Factory.status_with_triggers(&"x", triggers).validate()
	assert_true(errors.size() > 0 and errors[0].begins_with("triggers[0]"))
	var with_null: Array[TriggerData] = [null]
	assert_false(Factory.status_with_triggers(&"y", with_null).validate().is_empty())


func test_real_phase_2_statuses_have_designed_triggers() -> void:
	var registry := StatusRegistry.load_from_dir(STATUS_DIR)
	var poison := registry.get_status(&"poison")
	assert_true(poison.is_debuff and poison.decay_after_turn_start)
	assert_eq(poison.triggers[0].event, TriggerData.Event.TURN_START)
	assert_eq(poison.triggers[0].effects[0].type, EffectData.Type.LOSE_HP)
	assert_true(poison.triggers[0].scale_by_stacks)
	var metallicize := registry.get_status(&"metallicize")
	assert_eq(metallicize.triggers[0].event, TriggerData.Event.TURN_END)
	assert_eq(metallicize.triggers[0].effects[0].type, EffectData.Type.BLOCK)
	var thorns := registry.get_status(&"thorns")
	assert_eq(thorns.triggers[0].event, TriggerData.Event.ATTACKED)
	assert_eq(thorns.triggers[0].effects[0].target, EffectData.Target.EVENT_SOURCE)
	var demon := registry.get_status(&"demon_form")
	assert_eq(demon.triggers[0].effects[0].status_id, &"strength")
	assert_true(registry.get_status(&"artifact").negates_debuff)
	assert_true(registry.get_status(&"barricade").retains_block)
	assert_false(registry.get_status(&"metallicize").is_debuff)
