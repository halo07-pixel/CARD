extends "res://tests/test_case.gd"


func test_defaults_follow_slay_the_spire_and_are_valid() -> void:
	var config := BattleConfig.new()
	assert_eq(config.max_energy, 3)
	assert_eq(config.draw_per_turn, 5)
	assert_eq(config.turn_cap, 0)
	assert_eq(config.validate(), [] as Array[String])


func test_invalid_values_are_reported() -> void:
	var config := BattleConfig.new()
	config.max_energy = 0
	assert_false(config.validate().is_empty())
	config = BattleConfig.new()
	config.draw_per_turn = 0
	assert_false(config.validate().is_empty())
	config = BattleConfig.new()
	config.turn_cap = -1
	assert_false(config.validate().is_empty())
