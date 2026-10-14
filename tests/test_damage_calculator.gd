extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _pair() -> Array[Combatant]:
	return [Factory.combatant(&"attacker"), Factory.combatant(&"defender")] as Array[Combatant]


func test_plain_damage() -> void:
	var p := _pair()
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 6)


func test_strength_adds_before_multipliers() -> void:
	var p := _pair()
	p[0].add_status(Factory.strength(), 2)
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 8)


func test_weak_reduces_and_rounds_down() -> void:
	var p := _pair()
	p[0].add_status(Factory.weak(), 1)
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 4, "6 x 0.75 = 4.5 -> 4")


func test_vulnerable_increases() -> void:
	var p := _pair()
	p[1].add_status(Factory.vulnerable(), 1)
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 9)
	assert_eq(DamageCalculator.compute_damage(5, p[0], p[1]), 7, "5 x 1.5 = 7.5 -> 7")


func test_combined_formula_order() -> void:
	var p := _pair()
	p[0].add_status(Factory.strength(), 2)
	p[0].add_status(Factory.weak(), 1)
	p[1].add_status(Factory.vulnerable(), 1)
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 9, "(6+2) x 0.75 x 1.5 = 9")
	assert_eq(DamageCalculator.compute_damage(5, p[0], p[1]), 7, "(5+2) x 0.75 x 1.5 = 7.875 -> 7")


func test_rounding_happens_only_at_the_end() -> void:
	var p := _pair()
	p[0].add_status(Factory.weak(), 1)
	p[1].add_status(Factory.vulnerable(), 1)
	assert_eq(DamageCalculator.compute_damage(5, p[0], p[1]), 5, "5 x 0.75 x 1.5 = 5.625 -> 5 (làm tròn từng bước sẽ ra 4 hoặc 6)")


func test_negative_strength_never_goes_below_zero() -> void:
	var p := _pair()
	p[0].add_status(Factory.strength(), -10)
	assert_eq(DamageCalculator.compute_damage(6, p[0], p[1]), 0)


func test_block_with_dexterity_and_frail() -> void:
	var c := Factory.combatant()
	assert_eq(DamageCalculator.compute_block(5, c), 5)
	c.add_status(Factory.dexterity(), 2)
	assert_eq(DamageCalculator.compute_block(5, c), 7)
	c.add_status(Factory.frail(), 1)
	assert_eq(DamageCalculator.compute_block(5, c), 5, "(5+2) x 0.75 = 5.25 -> 5")


func test_block_never_negative() -> void:
	var c := Factory.combatant()
	c.add_status(Factory.dexterity(), -9)
	assert_eq(DamageCalculator.compute_block(5, c), 0)
