extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const FakeContext := preload("res://tests/fake_context.gd")
const T := EffectData.Type
const G := EffectData.Target

var _ctx: FakeContext
var _hero: Combatant
var _a: Combatant
var _b: Combatant
var _c: Combatant


func before_each() -> void:
	_ctx = FakeContext.new()
	_hero = Factory.combatant(&"hero", 80)
	_a = Factory.combatant(&"a", 30)
	_b = Factory.combatant(&"b", 30)
	_c = Factory.combatant(&"c", 30)


func _enemies() -> Array[Combatant]:
	return [_a, _b, _c] as Array[Combatant]


func test_single_target_damage() -> void:
	var results := EffectResolver.resolve(Factory.damage_effect(6), _hero, _a, _enemies(), _ctx)
	assert_eq(results.size(), 1)
	assert_eq(results[0].amount, 6)
	assert_true(results[0].target == _a)
	assert_eq(results[0].damage.hp_lost, 6)
	assert_eq(_a.hp, 24)
	assert_eq(_b.hp, 30)


func test_damage_is_absorbed_by_block_first() -> void:
	_a.gain_block(4)
	var results := EffectResolver.resolve(Factory.damage_effect(6), _hero, _a, _enemies(), _ctx)
	assert_eq(results[0].damage.blocked, 4)
	assert_eq(results[0].damage.hp_lost, 2)
	assert_eq(_a.hp, 28)


func test_damage_uses_attacker_and_defender_statuses() -> void:
	_hero.add_status(_ctx.get_status_data(&"strength"), 2)
	_hero.add_status(_ctx.get_status_data(&"weak"), 1)
	_a.add_status(_ctx.get_status_data(&"vulnerable"), 1)
	var results := EffectResolver.resolve(Factory.damage_effect(6), _hero, _a, _enemies(), _ctx)
	assert_eq(results[0].amount, 9, "(6+2) x 0.75 x 1.5")
	assert_eq(_a.hp, 21)


func test_multi_hit_recomputes_and_hits_every_time() -> void:
	var results := EffectResolver.resolve(Factory.damage_effect(4, G.TARGET_ENEMY, 3), _hero, _a, _enemies(), _ctx)
	assert_eq(results.size(), 3)
	assert_eq(_a.hp, 18)


func test_multi_hit_stops_when_target_dies() -> void:
	_a.take_damage(25)  # còn 5 máu
	var results := EffectResolver.resolve(Factory.damage_effect(4, G.TARGET_ENEMY, 5), _hero, _a, _enemies(), _ctx)
	assert_eq(results.size(), 2, "hit 1: còn 1 máu, hit 2: chết, các hit sau bị bỏ")
	assert_false(_a.is_alive())


func test_all_enemies_hits_living_only() -> void:
	_b.take_damage(30)
	var results := EffectResolver.resolve(Factory.damage_effect(5, G.ALL_ENEMIES), _hero, null, _enemies(), _ctx)
	assert_eq(results.size(), 2)
	assert_eq(_a.hp, 25)
	assert_eq(_c.hp, 25)
	assert_eq(_b.hp, 0)


func test_all_enemies_multi_hit_sweeps_each_time() -> void:
	EffectResolver.resolve(Factory.damage_effect(3, G.ALL_ENEMIES, 2), _hero, null, _enemies(), _ctx)
	assert_eq(_a.hp, 24)
	assert_eq(_b.hp, 24)
	assert_eq(_c.hp, 24)


func test_random_enemy_never_targets_dead_and_is_reproducible() -> void:
	_b.take_damage(30)
	var first := _random_hit_ids(11)
	_a = Factory.combatant(&"a", 30)
	_c = Factory.combatant(&"c", 30)
	_b = Factory.combatant(&"b", 30)
	_b.take_damage(30)
	var second := _random_hit_ids(11)
	assert_eq(first, second, "cùng seed phải cùng kết quả")
	assert_false(first.has("b"), "không được đánh kẻ đã chết")
	assert_true(first.has("a") or first.has("c"))


func _random_hit_ids(seed_value: int) -> Array:
	var ctx := FakeContext.new(null, seed_value)
	var results := EffectResolver.resolve(Factory.damage_effect(1, G.RANDOM_ENEMY, 12), _hero, null, _enemies(), ctx)
	var ids: Array = []
	for r in results:
		ids.append(String(r.target.id))
	return ids


func test_random_enemy_with_no_living_target_returns_nothing() -> void:
	for e in _enemies():
		e.take_damage(30)
	var results := EffectResolver.resolve(Factory.damage_effect(5, G.RANDOM_ENEMY, 3), _hero, null, _enemies(), _ctx)
	assert_eq(results.size(), 0)


func test_invalid_single_target_is_rejected_without_side_effects() -> void:
	var stranger := Factory.combatant(&"stranger", 30)
	_b.take_damage(30)
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), _hero, null, _enemies(), _ctx).size(), 0, "null")
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), _hero, _b, _enemies(), _ctx).size(), 0, "đã chết")
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), _hero, stranger, _enemies(), _ctx).size(), 0, "không thuộc phe đối diện")
	assert_eq(stranger.hp, 30)
	assert_eq(_a.hp, 30)


func test_dead_source_cannot_act() -> void:
	_hero.take_damage(999)
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), _hero, _a, _enemies(), _ctx).size(), 0)
	assert_eq(_a.hp, 30)


func test_invalid_effect_is_rejected() -> void:
	var bad := EffectData.create(T.DAMAGE, 0, G.TARGET_ENEMY)
	assert_eq(EffectResolver.resolve(bad, _hero, _a, _enemies(), _ctx).size(), 0)
	assert_eq(_a.hp, 30)
	assert_eq(EffectResolver.resolve(null, _hero, _a, _enemies(), _ctx).size(), 0)
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), null, _a, _enemies(), _ctx).size(), 0)
	assert_eq(EffectResolver.resolve(Factory.damage_effect(6), _hero, _a, _enemies(), null).size(), 0)


func test_enemy_attacking_player() -> void:
	var player_side: Array[Combatant] = [_hero]
	var results := EffectResolver.resolve(Factory.damage_effect(12), _a, _hero, player_side, _ctx)
	assert_eq(results.size(), 1)
	assert_eq(_hero.hp, 68)


func test_block_uses_dexterity_and_frail() -> void:
	_hero.add_status(_ctx.get_status_data(&"dexterity"), 2)
	_hero.add_status(_ctx.get_status_data(&"frail"), 1)
	var effect := EffectData.create(T.BLOCK, 5, G.SELF)
	var results := EffectResolver.resolve(effect, _hero, null, _enemies(), _ctx)
	assert_eq(results[0].amount, 5, "(5+2) x 0.75 = 5.25 -> 5")
	assert_eq(_hero.block, 5)


func test_draw_goes_through_context() -> void:
	_ctx.draw_result = 1  # chỉ rút được 1 dù yêu cầu 2
	var results := EffectResolver.resolve(EffectData.create(T.DRAW, 2, G.SELF), _hero, null, _enemies(), _ctx)
	assert_eq(_ctx.draw_requests, [2] as Array[int])
	assert_eq(results[0].amount, 1)
	assert_true(results[0].target == null)


func test_gain_energy_goes_through_context() -> void:
	var results := EffectResolver.resolve(EffectData.create(T.GAIN_ENERGY, 2, G.SELF), _hero, null, _enemies(), _ctx)
	assert_eq(_ctx.energy_gained, 2)
	assert_eq(results[0].amount, 2)


func test_apply_status_to_single_target() -> void:
	var effect := EffectData.create(T.APPLY_STATUS, 2, G.TARGET_ENEMY, 1, &"vulnerable")
	var results := EffectResolver.resolve(effect, _hero, _a, _enemies(), _ctx)
	assert_eq(results.size(), 1)
	assert_eq(results[0].status_id, &"vulnerable")
	assert_eq(_a.get_status(&"vulnerable"), 2)
	assert_eq(_b.get_status(&"vulnerable"), 0)


func test_apply_status_stacks_duration() -> void:
	var effect := EffectData.create(T.APPLY_STATUS, 2, G.TARGET_ENEMY, 1, &"weak")
	EffectResolver.resolve(effect, _hero, _a, _enemies(), _ctx)
	EffectResolver.resolve(effect, _hero, _a, _enemies(), _ctx)
	assert_eq(_a.get_status(&"weak"), 4)


func test_apply_status_to_self_and_to_all() -> void:
	var self_buff := EffectData.create(T.APPLY_STATUS, 3, G.SELF, 1, &"strength")
	EffectResolver.resolve(self_buff, _hero, null, _enemies(), _ctx)
	assert_eq(_hero.get_status(&"strength"), 3)
	var debuff_all := EffectData.create(T.APPLY_STATUS, 1, G.ALL_ENEMIES, 1, &"weak")
	_c.take_damage(30)
	var results := EffectResolver.resolve(debuff_all, _hero, null, _enemies(), _ctx)
	assert_eq(results.size(), 2, "bỏ qua kẻ đã chết")
	assert_false(_c.has_status(&"weak"))


func test_unknown_status_id_is_rejected() -> void:
	var effect := EffectData.create(T.APPLY_STATUS, 1, G.TARGET_ENEMY, 1, &"does_not_exist")
	assert_eq(EffectResolver.resolve(effect, _hero, _a, _enemies(), _ctx).size(), 0)
	assert_eq(_a.get_status_ids().size(), 0)


func test_real_starter_cards_work_end_to_end() -> void:
	var strike := load("res://data/cards/strike.tres") as CardData
	var defend := load("res://data/cards/defend.tres") as CardData
	for effect in strike.effects:
		EffectResolver.resolve(effect, _hero, _a, _enemies(), _ctx)
	for effect in defend.effects:
		EffectResolver.resolve(effect, _hero, null, _enemies(), _ctx)
	assert_eq(_a.hp, 24)
	assert_eq(_hero.block, 5)
