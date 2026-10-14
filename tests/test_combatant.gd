extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func test_create_rejects_invalid_params() -> void:
	assert_true(Combatant.create(&"", "x", 10) == null)
	assert_true(Combatant.create(&"x", "x", 0) == null)
	assert_true(Combatant.create(&"x", "x", -5) == null)
	var ok := Combatant.create(&"hero", "Hero", 80)
	assert_eq(ok.hp, 80)
	assert_true(ok.is_alive())


func test_block_absorbs_damage_before_hp() -> void:
	var c := Factory.combatant(&"c", 50)
	c.gain_block(10)
	var result := c.take_damage(4)
	assert_true(result.accepted)
	assert_eq(result.blocked, 4)
	assert_eq(result.hp_lost, 0)
	assert_eq(c.block, 6)
	assert_eq(c.hp, 50)


func test_damage_exceeding_block_hits_hp() -> void:
	var c := Factory.combatant(&"c", 50)
	c.gain_block(5)
	var result := c.take_damage(12)
	assert_eq(result.incoming, 12)
	assert_eq(result.blocked, 5)
	assert_eq(result.hp_lost, 7)
	assert_eq(c.block, 0)
	assert_eq(c.hp, 43)


func test_overkill_is_capped_and_hp_never_negative() -> void:
	var c := Factory.combatant(&"c", 10)
	var result := c.take_damage(999)
	assert_eq(result.hp_lost, 10)
	assert_true(result.killed)
	assert_eq(c.hp, 0)
	assert_false(c.is_alive())


func test_died_emitted_exactly_once() -> void:
	var c := Factory.combatant(&"c", 10)
	var deaths: Array = []
	c.died.connect(func() -> void: deaths.append(1))
	c.take_damage(10)
	c.take_damage(10)
	c.lose_hp(5)
	assert_eq(deaths.size(), 1)


func test_dead_combatant_rejects_everything() -> void:
	var c := Factory.combatant(&"c", 10)
	c.take_damage(10)
	var late := c.take_damage(5)
	assert_false(late.accepted)
	assert_eq(c.heal(5), 0)
	assert_eq(c.gain_block(5), 0)
	assert_eq(c.lose_hp(5), 0)
	assert_false(c.start_turn())
	assert_false(c.end_turn())
	assert_false(c.add_status(Factory.weak(), 2))
	assert_eq(c.hp, 0)
	assert_eq(c.block, 0)


func test_negative_damage_is_rejected_and_zero_is_harmless() -> void:
	var c := Factory.combatant(&"c", 10)
	assert_false(c.take_damage(-5).accepted)
	var zero := c.take_damage(0)
	assert_true(zero.accepted)
	assert_eq(zero.hp_lost, 0)
	assert_false(zero.killed)
	assert_eq(c.hp, 10)


func test_lose_hp_bypasses_block() -> void:
	var c := Factory.combatant(&"c", 20)
	c.gain_block(100)
	assert_eq(c.lose_hp(7), 7)
	assert_eq(c.hp, 13)
	assert_eq(c.block, 100)
	assert_eq(c.lose_hp(0), 0)
	assert_eq(c.lose_hp(-3), 0)


func test_heal_is_clamped_to_max_hp() -> void:
	var c := Factory.combatant(&"c", 20)
	c.take_damage(5)
	assert_eq(c.heal(100), 5)
	assert_eq(c.hp, 20)
	assert_eq(c.heal(10), 0)


func test_start_turn_clears_block() -> void:
	var c := Factory.combatant()
	c.gain_block(8)
	assert_true(c.start_turn())
	assert_eq(c.block, 0)


func test_intensity_statuses_stack_and_can_go_negative() -> void:
	var c := Factory.combatant()
	assert_true(c.add_status(Factory.strength(), 2))
	assert_true(c.add_status(Factory.strength(), 3))
	assert_eq(c.get_status(&"strength"), 5)
	assert_true(c.add_status(Factory.strength(), -8))
	assert_eq(c.get_status(&"strength"), -3)


func test_status_is_removed_when_it_reaches_zero() -> void:
	var c := Factory.combatant()
	c.add_status(Factory.strength(), 2)
	c.add_status(Factory.strength(), -2)
	assert_false(c.has_status(&"strength"))
	assert_eq(c.get_status_ids().size(), 0)


func test_non_negative_status_cannot_be_created_negative_or_pushed_below_zero() -> void:
	var c := Factory.combatant()
	assert_false(c.add_status(Factory.weak(), -1))
	assert_false(c.has_status(&"weak"))
	c.add_status(Factory.weak(), 2)
	assert_true(c.add_status(Factory.weak(), -5))
	assert_false(c.has_status(&"weak"), "giảm quá tay thì chỉ bị gỡ, không thành số âm")


func test_zero_and_null_status_are_rejected() -> void:
	var c := Factory.combatant()
	assert_false(c.add_status(Factory.weak(), 0))
	assert_false(c.add_status(null, 3))


func test_status_amount_is_capped() -> void:
	var c := Factory.combatant()
	c.add_status(Factory.strength(), 5000)
	assert_eq(c.get_status(&"strength"), Combatant.MAX_STATUS_AMOUNT)


func test_end_turn_decays_duration_statuses_only() -> void:
	var c := Factory.combatant()
	c.add_status(Factory.weak(), 2)
	c.add_status(Factory.strength(), 3)
	c.end_turn()
	assert_eq(c.get_status(&"weak"), 1)
	assert_eq(c.get_status(&"strength"), 3)
	c.end_turn()
	assert_false(c.has_status(&"weak"))
	assert_eq(c.get_status(&"strength"), 3)


func test_signals_carry_old_and_new_values() -> void:
	var c := Factory.combatant(&"c", 30)
	var hp_log: Array = []
	var block_log: Array = []
	var status_log: Array = []
	c.health_changed.connect(func(o: int, n: int) -> void: hp_log.append([o, n]))
	c.block_changed.connect(func(o: int, n: int) -> void: block_log.append([o, n]))
	c.status_changed.connect(func(id: StringName, o: int, n: int) -> void: status_log.append([id, o, n]))
	c.gain_block(5)
	c.take_damage(8)
	c.add_status(Factory.weak(), 2)
	c.end_turn()
	assert_eq(block_log, [[0, 5], [5, 0]])
	assert_eq(hp_log, [[30, 27]])
	assert_eq(status_log, [[&"weak", 0, 2], [&"weak", 2, 1]])


func test_no_signal_when_nothing_changes() -> void:
	var c := Factory.combatant()
	var events: Array = []
	c.health_changed.connect(func(o: int, n: int) -> void: events.append(1))
	c.block_changed.connect(func(o: int, n: int) -> void: events.append(1))
	c.heal(10)
	c.take_damage(0)
	c.start_turn()
	assert_eq(events.size(), 0)


func test_modifiers_sum_and_multiply_across_statuses() -> void:
	var c := Factory.combatant()
	assert_almost_eq(c.damage_dealt_add(), 0.0)
	assert_almost_eq(c.damage_dealt_mult(), 1.0)
	c.add_status(Factory.strength(), 3)
	c.add_status(Factory.weak(), 1)
	c.add_status(Factory.vulnerable(), 1)
	c.add_status(Factory.dexterity(), -2)
	c.add_status(Factory.frail(), 1)
	assert_almost_eq(c.damage_dealt_add(), 3.0)
	assert_almost_eq(c.damage_dealt_mult(), 0.75)
	assert_almost_eq(c.damage_taken_mult(), 1.5)
	assert_almost_eq(c.block_gain_add(), -2.0)
	assert_almost_eq(c.block_gain_mult(), 0.75)


func test_get_status_ids_returns_copy() -> void:
	var c := Factory.combatant()
	c.add_status(Factory.weak(), 1)
	var ids := c.get_status_ids()
	ids.clear()
	assert_true(c.has_status(&"weak"))
