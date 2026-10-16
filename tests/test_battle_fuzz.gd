extends "res://tests/test_case.gd"
## Chơi ngẫu nhiên nhiều trận (kể cả hành động sai) và kiểm tra điều kiện bất biến sau MỖI bước.

const Factory := preload("res://tests/combat_factory.gd")

const BATTLES := 150
const MAX_STEPS := 600
const TURN_CAP := 40


func _random_deck(rnd: RandomNumberGenerator) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	var size := rnd.randi_range(8, 16)
	for i in size:
		var id := StringName("c%d" % i)
		match rnd.randi_range(0, 9):
			0, 1, 2:
				cards.append(Factory.strike(id, rnd.randi_range(4, 9)))
			3, 4:
				cards.append(Factory.defend(id, rnd.randi_range(4, 8)))
			5:
				cards.append(Factory.aoe(id, rnd.randi_range(3, 7)))
			6:
				cards.append(Factory.draw_card(id, rnd.randi_range(1, 3)))
			7:
				cards.append(Factory.energy_card(id, rnd.randi_range(1, 2)))
			8:
				cards.append(Factory.strike(id, 5, {"is_x_cost": true, "cost": 0, "exhaust": true}))
			_:
				cards.append(Factory.strike(id, 6, {"retain": true, "ethereal": rnd.randf() < 0.5}))
	return cards


func _random_enemies(rnd: RandomNumberGenerator, registry: EnemyRegistry) -> Array[EnemyData]:
	var ids: Array[StringName] = [&"slime", &"goblin", &"acolyte"]
	var datas: Array[EnemyData] = []
	for i in rnd.randi_range(1, 3):
		datas.append(registry.get_enemy(ids[rnd.randi_range(0, ids.size() - 1)]))
	return datas


func _random_action(controller: BattleController, rnd: RandomNumberGenerator) -> void:
	if rnd.randf() < 0.05:  # hành động sai có chủ ý: không được đổi gì
		controller.play_card(Factory.strike(&"ghost"), controller.enemies[0])
		return
	if rnd.randf() < 0.2:
		controller.end_player_turn()
		return
	var playable: Array[CardInstance] = []
	for card in controller.deck.get_pile(Deck.HAND):
		if controller.can_play(card):
			playable.append(card)
	if playable.is_empty():
		controller.end_player_turn()
		return
	var card := playable[rnd.randi_range(0, playable.size() - 1)]
	var targets := controller.valid_targets(card)
	var target: EnemyUnit = targets[rnd.randi_range(0, targets.size() - 1)] if not targets.is_empty() else null
	controller.play_card(card, target)


func test_random_battles_never_break_invariants() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var rnd := Factory.rng(2024)
	var wins := 0
	var losses := 0
	for battle_index in BATTLES:
		var cards := _random_deck(rnd)
		var config := BattleConfig.new()
		config.turn_cap = TURN_CAP
		var controller := Factory.battle(cards, _random_enemies(rnd, registry), battle_index + 1, config)
		var invariants := BattleInvariants.new(controller)
		controller.start_battle()
		var steps := 0
		while not controller.state.is_terminal() and steps < MAX_STEPS:
			steps += 1
			_random_action(controller, rnd)
			var violations := invariants.check()
			assert_eq(violations, [] as Array[String], "trận %d bước %d" % [battle_index, steps])
			if not failures.is_empty():
				return
		assert_true(controller.state.is_terminal(), "trận %d không kết thúc sau %d bước" % [battle_index, steps])
		if controller.end_reason == BattleController.END_VICTORY:
			wins += 1
		else:
			losses += 1
		# Sau khi kết thúc mọi hành động đều bị từ chối và không phát thêm battle_ended
		assert_false(controller.end_player_turn())
		assert_eq(invariants.ended_count(), 1)
		if not failures.is_empty():
			return
	assert_true(wins > 0 and losses > 0, "bộ test phải có cả trận thắng (%d) lẫn thua (%d) mới đủ phủ" % [wins, losses])
