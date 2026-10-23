extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const E := TriggerData.Event
const T := EffectData.Type
const G := EffectData.Target

var _dispatcher: TriggerDispatcher


func before_each() -> void:
	_dispatcher = TriggerDispatcher.new()


func _owner(id: StringName = &"owner") -> Combatant:
	return Factory.combatant(id, 50)


func _block(amount: int = 1) -> EffectData:
	return EffectData.create(T.BLOCK, amount, G.SELF)


func _trigger(event: TriggerData.Event, amount: int = 1, props: Dictionary = {}) -> TriggerData:
	return Factory.trigger1(event, _block(amount), props)


func _source(owner: Combatant, key: StringName, triggers: Array, stacks: int = 1) -> TriggerSource:
	var typed: Array[TriggerData] = []
	typed.assign(triggers)
	return TriggerSource.create(key, owner, typed, stacks)


func _sources(list: Array) -> Array[TriggerSource]:
	var typed: Array[TriggerSource] = []
	typed.assign(list)
	return typed


func _amounts(actions: Array[QueuedAction]) -> Array:
	return actions.map(func(a: QueuedAction) -> int: return a.effect.amount)


func test_fires_only_for_the_matching_event_type() -> void:
	var owner := _owner()
	var sources := _sources([_source(owner, &"s", [_trigger(E.TURN_START)])])
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_END, owner), sources).size(), 0)
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, owner), sources).size(), 1)


func test_trigger_only_fires_for_its_own_owner_but_battle_events_reach_everyone() -> void:
	var a := _owner(&"a")
	var b := _owner(&"b")
	var turn_sources := _sources([_source(a, &"sa", [_trigger(E.TURN_START)]), _source(b, &"sb", [_trigger(E.TURN_START)])])
	var actions := _dispatcher.actions_for(BattleEvent.create(E.TURN_START, a), turn_sources)
	assert_eq(actions.size(), 1)
	assert_true(actions[0].owner == a)
	var battle_sources := _sources([_source(a, &"sa", [_trigger(E.BATTLE_START)]), _source(b, &"sb", [_trigger(E.BATTLE_START)])])
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.BATTLE_START), battle_sources).size(), 2)


func test_dead_owner_never_fires() -> void:
	var owner := _owner()
	var sources := _sources([_source(owner, &"s", [_trigger(E.TURN_START)])])
	owner.take_damage(999)
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, owner), sources).size(), 0)


func test_scale_by_stacks_multiplies_amount_without_touching_the_shared_effect() -> void:
	var owner := _owner()
	var scaled := _trigger(E.TURN_START, 2, {"scale_by_stacks": true})
	var plain := _trigger(E.TURN_START, 2)
	var event := BattleEvent.create(E.TURN_START, owner)
	assert_eq(_amounts(_dispatcher.actions_for(event, _sources([_source(owner, &"s", [scaled], 4)]))), [8])
	assert_eq(_amounts(_dispatcher.actions_for(event, _sources([_source(owner, &"p", [plain], 4)]))), [2],
			"không bật scale_by_stacks thì bỏ qua số stack")
	assert_eq(scaled.effects[0].amount, 2, "effect gốc dùng chung không bị sửa")
	assert_eq(_dispatcher.actions_for(event, _sources([_source(owner, &"z", [scaled], 0)])).size(), 0,
			"0 stack thì không nổ")


func test_every_n_fires_on_every_nth_occurrence() -> void:
	var owner := _owner()
	var sources := _sources([_source(owner, &"s", [_trigger(E.TURN_START, 1, {"every_n": 3})])])
	var fired: Array = []
	for i in 7:
		fired.append(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, owner), sources).size() == 1)
	assert_eq(fired, [false, false, true, false, false, true, false])


func test_every_n_only_counts_occurrences_that_pass_the_conditions() -> void:
	var owner := _owner()
	var attacks_only := _trigger(E.CARD_PLAYED, 1, {"every_n": 2, "filter_card_type": true,
			"card_type": CardData.CardType.ATTACK})
	var sources := _sources([_source(owner, &"s", [attacks_only])])
	var fired: Array = []
	for card in [Factory.defend(&"d1"), Factory.strike(&"s1"), Factory.defend(&"d2"), Factory.strike(&"s2")]:
		fired.append(_dispatcher.actions_for(BattleEvent.create(E.CARD_PLAYED, owner, null, 0, card), sources).size() == 1)
	assert_eq(fired, [false, false, false, true], "kỹ năng không được tính vào bộ đếm")


func test_max_per_turn_resets_every_turn_but_max_per_battle_never_does() -> void:
	var owner := _owner()
	var per_turn := _source(owner, &"t", [_trigger(E.TURN_START, 1, {"max_per_turn": 1})])
	var per_battle := _source(owner, &"b", [_trigger(E.TURN_START, 1, {"max_per_battle": 2})])
	var event := BattleEvent.create(E.TURN_START, owner)
	var turn_counts: Array = []
	var battle_counts: Array = []
	for turn in 4:
		_dispatcher.new_turn()
		turn_counts.append(_dispatcher.actions_for(event, _sources([per_turn])).size()
				+ _dispatcher.actions_for(event, _sources([per_turn])).size())
		battle_counts.append(_dispatcher.actions_for(event, _sources([per_battle])).size())
	assert_eq(turn_counts, [1, 1, 1, 1], "mỗi lượt tối đa 1 lần dù gọi hai lần")
	assert_eq(battle_counts, [1, 1, 0, 0], "cả trận tối đa 2 lần")


func test_card_type_filter_and_zero_block_conditions() -> void:
	var owner := _owner()
	var skills := _trigger(E.CARD_PLAYED, 1, {"filter_card_type": true, "card_type": CardData.CardType.SKILL})
	var skill_sources := _sources([_source(owner, &"k", [skills])])
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.CARD_PLAYED, owner, null, 0, Factory.defend()), skill_sources).size(), 1)
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.CARD_PLAYED, owner, null, 0, Factory.strike()), skill_sources).size(), 0)
	var no_card := BattleEvent.create(E.CARD_PLAYED, owner)
	assert_eq(_dispatcher.actions_for(no_card, skill_sources).size(), 0, "sự kiện thiếu thẻ thì không khớp bộ lọc")
	var zero := _sources([_source(owner, &"z", [_trigger(E.TURN_END, 6, {"requires_zero_block": true})])])
	var end_event := BattleEvent.create(E.TURN_END, owner)
	assert_eq(_dispatcher.actions_for(end_event, zero).size(), 1)
	owner.gain_block(1)
	assert_eq(_dispatcher.actions_for(end_event, zero).size(), 0)


func test_counters_are_independent_per_owner_and_per_trigger() -> void:
	var a := _owner(&"a")
	var b := _owner(&"b")
	var every_two := _trigger(E.TURN_START, 1, {"every_n": 2})
	var sources := _sources([_source(a, &"same", [every_two]), _source(b, &"same", [every_two])])
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, a), sources).size(), 0)
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, b), sources).size(), 0,
			"lần đầu của b: bộ đếm của a không được dùng chung")
	assert_eq(_dispatcher.actions_for(BattleEvent.create(E.TURN_START, a), sources).size(), 1)
	var two_triggers := _sources([_source(a, &"multi", [_trigger(E.TURN_END, 1, {"every_n": 2}), _trigger(E.TURN_END, 5)])])
	var event := BattleEvent.create(E.TURN_END, a)
	assert_eq(_amounts(_dispatcher.actions_for(event, two_triggers)), [5])
	assert_eq(_amounts(_dispatcher.actions_for(event, two_triggers)), [1, 5])


func test_order_follows_sources_then_triggers_then_effects() -> void:
	var a := _owner(&"a")
	var b := _owner(&"b")
	var two_effects: Array[EffectData] = [_block(1), _block(2)]
	var first := _source(a, &"first", [Factory.trigger(E.BATTLE_START, two_effects), _trigger(E.BATTLE_START, 3)])
	var second := _source(b, &"second", [_trigger(E.BATTLE_START, 4)])
	var actions := _dispatcher.actions_for(BattleEvent.create(E.BATTLE_START), _sources([first, second]))
	assert_eq(_amounts(actions), [1, 2, 3, 4])
	assert_eq(actions.map(func(x: QueuedAction) -> StringName: return x.key), [&"first", &"first", &"first", &"second"])


func test_event_source_is_passed_to_every_action() -> void:
	var owner := _owner()
	var attacker := _owner(&"attacker")
	var sources := _sources([_source(owner, &"s", [_trigger(E.ATTACKED)])])
	var actions := _dispatcher.actions_for(BattleEvent.create(E.ATTACKED, owner, attacker, 6), sources)
	assert_true(actions[0].event_source == attacker)
	assert_true(actions[0].owner == owner)


func test_sources_follow_the_statuses_currently_on_the_combatant() -> void:
	var c := Factory.combatant()
	var poison := Factory.status_with_triggers(&"poison", [_trigger(E.TURN_START)] as Array[TriggerData])
	assert_eq(TriggerSource.from_statuses(c).size(), 0)
	c.add_status(poison, 3)
	var sources := TriggerSource.from_statuses(c)
	assert_eq(sources.size(), 1)
	assert_eq(sources[0].stacks, 3)
	assert_eq(sources[0].key, &"status:poison")
	c.remove_status(&"poison")
	assert_eq(TriggerSource.from_statuses(c).size(), 0, "gỡ status là hết hiệu lực ngay, không cần hủy đăng ký")
	c.add_status(Factory.weak(), 1)
	assert_eq(TriggerSource.from_statuses(c).size(), 0, "status không có trigger bị bỏ qua")
	c.add_status(poison, 1)
	c.take_damage(999)
	assert_eq(TriggerSource.from_statuses(c).size(), 0, "đơn vị đã chết không có nguồn trigger")


func test_relic_sources_use_relic_keys_stacks_of_one_and_skip_relics_without_triggers() -> void:
	var owner := _owner()
	var with_trigger := RelicData.new()
	with_trigger.id = &"anchor"
	with_trigger.triggers = [_trigger(E.BATTLE_START)] as Array[TriggerData]
	var bonus_only := RelicData.new()
	bonus_only.id = &"crystal"
	bonus_only.max_energy_bonus = 1
	var relics: Array[RelicData] = [with_trigger, bonus_only]
	var sources := TriggerSource.from_relics(owner, relics)
	assert_eq(sources.size(), 1, "relic chỉ có bonus tĩnh không phải nguồn trigger")
	assert_eq(sources[0].key, &"relic:anchor")
	assert_eq(sources[0].stacks, 1)
	owner.take_damage(999)
	assert_eq(TriggerSource.from_relics(owner, relics).size(), 0, "chủ sở hữu đã chết")
