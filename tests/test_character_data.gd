extends "res://tests/test_case.gd"

const WARRIOR_PATH := "res://data/characters/warrior.tres"


func _valid() -> CharacterData:
	var data := CharacterData.new()
	data.id = &"hero"
	data.display_name = "Hero"
	data.starting_deck = [&"strike", &"defend"] as Array[StringName]
	return data


func test_valid_character_and_defaults() -> void:
	var data := _valid()
	assert_eq(data.validate(), [] as Array[String])
	assert_eq(data.max_hp, 80)
	assert_eq(data.max_energy, 3)
	assert_eq(data.draw_per_turn, 5)


func test_each_invalid_field_is_reported() -> void:
	var cases := {"id": &"", "display_name": "  ", "max_hp": 0, "max_energy": 0,
			"draw_per_turn": 0, "starting_gold": -1}
	for key: String in cases:
		var data := _valid()
		data.set(key, cases[key])
		assert_false(data.validate().is_empty(), "phải báo lỗi khi %s không hợp lệ" % key)


func test_deck_rules() -> void:
	var data := _valid()
	data.starting_deck = [] as Array[StringName]
	assert_false(data.validate().is_empty(), "bộ bài rỗng")
	data.starting_deck = [&"strike", &""] as Array[StringName]
	assert_false(data.validate().is_empty(), "id thẻ trống")


func test_make_battle_config_copies_character_stats() -> void:
	var data := _valid()
	data.max_energy = 4
	data.draw_per_turn = 7
	var config := data.make_battle_config()
	assert_eq(config.max_energy, 4)
	assert_eq(config.draw_per_turn, 7)
	assert_eq(config.turn_cap, 0)


func test_warrior_resource_is_valid_and_matches_slay_the_spire_start() -> void:
	var warrior := load(WARRIOR_PATH) as CharacterData
	assert_true(warrior != null)
	assert_eq(warrior.validate(), [] as Array[String])
	assert_eq(warrior.max_hp, 80)
	assert_eq(warrior.max_energy, 3)
	assert_eq(warrior.draw_per_turn, 5)
	assert_eq(warrior.starting_gold, 99)
	assert_eq(warrior.starting_deck.size(), 10)
	assert_eq(warrior.starting_deck.count(&"strike"), 5)
	assert_eq(warrior.starting_deck.count(&"defend"), 4)
	assert_eq(warrior.starting_deck.count(&"bash"), 1)


func test_warrior_starting_deck_only_uses_existing_cards() -> void:
	var warrior := load(WARRIOR_PATH) as CharacterData
	var cards := CardRegistry.load_from_dir("res://data/cards")
	assert_eq(cards.missing_ids(warrior.starting_deck), [] as Array[StringName])
