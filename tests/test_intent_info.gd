extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const G := EffectData.Target


func _pair() -> Array[Combatant]:
	return [Factory.combatant(&"enemy", 30), Factory.combatant(&"player", 80)] as Array[Combatant]


func test_attack_intent() -> void:
	var p := _pair()
	var info := IntentInfo.build(Factory.attack_move(&"hit", 6), p[0], p[1])
	assert_true(info.attacks)
	assert_false(info.defends or info.buffs or info.debuffs)
	assert_eq(info.damage_per_hit, 6)
	assert_eq(info.hit_count, 1)
	assert_eq(info.total_damage, 6)


func test_multi_hit_intent_shows_per_hit_and_total() -> void:
	var p := _pair()
	var info := IntentInfo.build(Factory.attack_move(&"flurry", 4, 1, 0, 3), p[0], p[1])
	assert_eq(info.damage_per_hit, 4)
	assert_eq(info.hit_count, 3)
	assert_eq(info.total_damage, 12)


func test_damage_includes_strength_weak_and_vulnerable() -> void:
	var p := _pair()
	p[0].add_status(Factory.strength(), 2)
	p[0].add_status(Factory.weak(), 1)
	p[1].add_status(Factory.vulnerable(), 1)
	var info := IntentInfo.build(Factory.attack_move(&"hit", 6), p[0], p[1])
	assert_eq(info.damage_per_hit, 9, "(6+2) x 0.75 x 1.5")


func test_defend_buff_and_debuff_flags() -> void:
	var p := _pair()
	var guard := IntentInfo.build(Factory.block_move(&"guard", 8), p[0], p[1])
	assert_true(guard.defends)
	assert_false(guard.attacks)
	assert_eq(guard.total_damage, 0)
	var ritual := IntentInfo.build(Factory.status_move(&"ritual", &"strength", 2, G.SELF), p[0], p[1])
	assert_true(ritual.buffs)
	assert_false(ritual.debuffs)
	var curse := IntentInfo.build(Factory.status_move(&"curse", &"weak", 1, G.TARGET_ENEMY), p[0], p[1])
	assert_true(curse.debuffs)
	assert_false(curse.buffs)


func test_mixed_move_sets_all_relevant_flags() -> void:
	var p := _pair()
	var effects: Array[EffectData] = [
		Factory.damage_effect(3),
		EffectData.create(EffectData.Type.APPLY_STATUS, 1, G.TARGET_ENEMY, 1, &"weak"),
		EffectData.create(EffectData.Type.BLOCK, 4, G.SELF),
	]
	var info := IntentInfo.build(Factory.move(&"mix", effects), p[0], p[1])
	assert_true(info.attacks and info.debuffs and info.defends)
	assert_false(info.buffs)
