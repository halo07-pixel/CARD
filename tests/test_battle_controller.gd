extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")
const P := BattleState.Phase


func _started(cards: Array[CardInstance], datas: Array[EnemyData], seed_value: int = 1,
		config: BattleConfig = null, hp: int = 80) -> BattleController:
	var controller := Factory.battle(cards, datas, seed_value, config, hp)
	controller.start_battle()
	return controller


func _one_dummy(hp: int = 20, damage: int = 6) -> Array[EnemyData]:
	return [Factory.dummy_enemy(&"dummy", hp, damage)] as Array[EnemyData]


func _target(controller: BattleController, index: int = 0) -> EnemyUnit:
	return controller.enemies[index]


## --- Tạo trận ---

func test_create_rejects_invalid_setup() -> void:
	var rng := Factory.rng()
	var unit := EnemyUnit.create(Factory.dummy_enemy(), rng)
	var units: Array[EnemyUnit] = [unit]
	var no_units: Array[EnemyUnit] = []
	var no_cards: Array[CardInstance] = []
	var cards := Factory.fillers(5)
	var player := Factory.combatant(&"player", 80)
	var registry := Factory.registry()
	assert_true(BattleController.create(player, cards, units, registry) != null, "đối chứng: tham số đúng thì tạo được")
	assert_true(BattleController.create(null, cards, units, registry) == null, "player null")
	var dead := Factory.combatant(&"dead", 10)
	dead.take_damage(99)
	assert_true(BattleController.create(dead, cards, units, registry) == null, "player đã chết")
	assert_true(BattleController.create(player, no_cards, units, registry) == null, "bộ bài rỗng")
	assert_true(BattleController.create(player, cards, no_units, registry) == null, "không có quái")
	assert_true(BattleController.create(player, cards, units, null) == null, "thiếu registry")
	var bad_config := BattleConfig.new()
	bad_config.max_energy = 0
	assert_true(BattleController.create(player, cards, units, registry, 1, bad_config) == null, "config sai")


func test_create_from_data_gives_unique_unit_ids() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(), Factory.dummy_enemy()]
	var controller := Factory.battle(Factory.fillers(5), datas)
	assert_eq(controller.enemies.size(), 2)
	assert_ne(controller.enemies[0].combatant.id, controller.enemies[1].combatant.id)


## --- Bắt đầu trận ---

func test_start_battle_sets_up_first_turn() -> void:
	var controller := Factory.battle(Factory.fillers(10), _one_dummy())
	var rec := Recorder.new(controller)
	assert_eq(controller.state.phase, P.SETUP)
	assert_true(controller.start_battle())
	assert_eq(controller.state.phase, P.PLAYER_TURN)
	assert_eq(controller.turn, 1)
	assert_eq(controller.energy, 3)
	assert_eq(controller.deck.count(Deck.HAND), 5)
	assert_true(controller.enemies[0].intent != null, "quái đã báo ý định")
	assert_eq(controller.enemies[0].intent.damage_per_hit, 6)
	assert_eq(rec.with_prefix("state:"), ["state:SETUP>PLAYER_START", "state:PLAYER_START>PLAYER_TURN"])
	assert_true(rec.has_event("energy:0>3"))
	assert_true(rec.has_event("turn:1:player"))


func test_start_battle_twice_is_rejected() -> void:
	var controller := Factory.battle(Factory.fillers(10), _one_dummy())
	var rec := Recorder.new(controller)
	controller.start_battle()
	assert_false(controller.start_battle())
	assert_eq(rec.last_rejection(), "already_started")
	assert_eq(controller.turn, 1)


## --- Từ chối hành động sai (không được thay đổi gì) ---

func test_actions_before_start_are_rejected() -> void:
	var controller := Factory.battle(Factory.fillers(5), _one_dummy())
	var rec := Recorder.new(controller)
	assert_false(controller.play_card(controller.deck.get_pile(Deck.DRAW)[0], _target(controller)))
	assert_eq(rec.last_rejection(), "not_player_turn")
	assert_false(controller.end_player_turn())
	assert_eq(rec.last_rejection(), "not_player_turn")


func _assert_rejected_without_change(controller: BattleController, rec: Recorder, card: CardInstance,
		target: EnemyUnit, reason: String) -> void:
	var energy_before := controller.energy
	var hand_before := controller.deck.count(Deck.HAND)
	var hp_before := controller.enemies[0].combatant.hp
	assert_false(controller.play_card(card, target), reason)
	assert_eq(rec.last_rejection(), reason)
	assert_eq(controller.energy, energy_before, reason + ": năng lượng không đổi")
	assert_eq(controller.deck.count(Deck.HAND), hand_before, reason + ": tay không đổi")
	assert_eq(controller.enemies[0].combatant.hp, hp_before, reason + ": máu quái không đổi")


func test_play_rejections_leave_everything_untouched() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a"), Factory.dummy_enemy(&"b")]
	var controller := _started(Factory.fillers(10), datas)
	var rec := Recorder.new(controller)
	var strike := Factory.inject(controller, Factory.strike(&"s"))
	var costly := Factory.inject(controller, Factory.strike(&"costly", 6, {"cost": 4}))
	var locked := Factory.inject(controller, Factory.strike(&"locked", 6, {"unplayable": true, "cost": 0}))
	_assert_rejected_without_change(controller, rec, Factory.strike(&"stranger"), _target(controller), "card_not_in_hand")
	_assert_rejected_without_change(controller, rec, costly, _target(controller), "not_enough_energy")
	_assert_rejected_without_change(controller, rec, locked, _target(controller), "unplayable")
	_assert_rejected_without_change(controller, rec, strike, null, "invalid_target")
	var outsider := EnemyUnit.create(Factory.dummy_enemy(&"x"), Factory.rng())
	_assert_rejected_without_change(controller, rec, strike, outsider, "invalid_target")
	_target(controller, 1).combatant.take_damage(999)
	_assert_rejected_without_change(controller, rec, strike, _target(controller, 1), "invalid_target")
	assert_eq(controller.state.phase, P.PLAYER_TURN, "từ chối không đổi pha")


## --- Chơi thẻ ---

func test_playing_an_attack_spends_energy_damages_and_discards() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20))
	var rec := Recorder.new(controller)
	var strike := Factory.inject(controller, Factory.strike(&"hit_me", 6))
	var total := controller.deck.total_count()
	assert_true(controller.play_card(strike, _target(controller)))
	assert_eq(controller.energy, 2)
	assert_eq(_target(controller).combatant.hp, 14)
	assert_eq(controller.deck.find_pile(strike), Deck.DISCARD)
	assert_eq(controller.deck.total_count(), total, "không mất thẻ")
	assert_eq(controller.deck.count(Deck.LIMBO), 0)
	assert_true(rec.has_event("played:hit_me"))


func test_exhaust_card_goes_to_exhaust_pile() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var burn := Factory.inject(controller, Factory.strike(&"burn", 6, {"exhaust": true}))
	controller.play_card(burn, _target(controller))
	assert_eq(controller.deck.find_pile(burn), Deck.EXHAUST)


func test_aoe_hits_every_living_enemy_and_ignores_target_argument() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 20), Factory.dummy_enemy(&"b", 20),
			Factory.dummy_enemy(&"c", 20)]
	var controller := _started(Factory.fillers(10), datas)
	_target(controller, 2).combatant.take_damage(999)
	var aoe := Factory.inject(controller, Factory.aoe(&"sweep", 5))
	assert_true(controller.play_card(aoe))
	assert_eq(_target(controller, 0).combatant.hp, 15)
	assert_eq(_target(controller, 1).combatant.hp, 15)
	assert_eq(_target(controller, 2).combatant.hp, 0)


func test_block_card_grants_block() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	assert_true(controller.play_card(Factory.inject(controller, Factory.defend(&"guard", 5))))
	assert_eq(controller.player.block, 5)


func test_draw_effect_goes_through_the_deck() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var before := controller.deck.count(Deck.HAND)
	var draw := Factory.inject(controller, Factory.draw_card(&"dr", 2))
	controller.play_card(draw)
	assert_eq(controller.deck.count(Deck.HAND), before + 1 - 1 + 2, "tay: +1 (chèn) -1 (đã chơi) +2 (rút)")
	assert_eq(controller.energy, 2)


func test_energy_effect_can_exceed_max_and_exhausts() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var rec := Recorder.new(controller)
	var gain := Factory.inject(controller, Factory.energy_card(&"surge", 2))
	assert_true(controller.play_card(gain))
	assert_eq(controller.energy, 5, "3 + 2, vượt mức tối đa là hợp lệ")
	assert_eq(controller.deck.find_pile(gain), Deck.EXHAUST)
	assert_true(rec.has_event("energy:3>5"))


func test_x_cost_card_spends_all_energy() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var x_card := Factory.inject(controller, Factory.strike(&"x", 6, {"is_x_cost": true, "cost": 0}))
	assert_true(controller.play_card(x_card, _target(controller)))
	assert_eq(controller.energy, 0)


func test_card_never_redraws_itself_during_its_own_draw_effect() -> void:
	# Bộ bài 5 thẻ: sau khi rút đủ 5 thì draw pile rỗng; chơi 2 thẻ -> discard có 2 thẻ.
	# Thẻ rút bài đang ở limbo khi xáo lại discard nên KHÔNG được rút lại chính nó.
	var controller := _started(Factory.fillers(5), _one_dummy(200))
	var draw := Factory.inject(controller, Factory.draw_card(&"dr", 3))
	var hand := controller.deck.get_pile(Deck.HAND)
	var played := 0
	for card in hand:
		if card != draw and played < 2:
			assert_true(controller.play_card(card, _target(controller)))
			played += 1
	assert_eq(controller.deck.count(Deck.DRAW), 0)
	assert_eq(controller.deck.count(Deck.DISCARD), 2)
	assert_true(controller.play_card(draw))
	assert_ne(controller.deck.find_pile(draw), Deck.HAND, "không được rút lại thẻ vừa chơi")
	assert_eq(controller.deck.find_pile(draw), Deck.DISCARD)
	assert_eq(controller.deck.count(Deck.LIMBO), 0)


func test_intent_updates_when_a_card_changes_the_damage() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20, 6))
	var rec := Recorder.new(controller)
	var weaken := Factory.inject(controller, Factory.weaken_card(&"wk", 1))
	assert_true(controller.play_card(weaken, _target(controller)))
	assert_eq(_target(controller).intent.damage_per_hit, 4, "6 x 0.75 = 4")
	assert_true(rec.has_event("intent:dummy_0:4"))


func test_playing_a_card_does_not_emit_intent_when_nothing_changed() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20, 6))
	var rec := Recorder.new(controller)
	controller.play_card(Factory.inject(controller, Factory.strike(&"s")), _target(controller))
	assert_eq(rec.count("intent:"), 0)


## --- Kết thúc lượt, lượt quái ---

func test_end_turn_runs_enemy_turn_and_starts_the_next_player_turn() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20, 6))
	var rec := Recorder.new(controller)
	assert_true(controller.end_player_turn())
	assert_eq(controller.player.hp, 74)
	assert_eq(controller.turn, 2)
	assert_eq(controller.energy, 3, "năng lượng được đặt lại, không cộng dồn")
	assert_eq(controller.deck.count(Deck.HAND), 5)
	assert_eq(controller.state.phase, P.PLAYER_TURN)
	assert_eq(rec.with_prefix("state:"), [
		"state:PLAYER_TURN>ENEMY_TURN", "state:ENEMY_TURN>CHECK_END",
		"state:CHECK_END>PLAYER_START", "state:PLAYER_START>PLAYER_TURN"])
	assert_true(rec.has_event("acted:dummy_0:hit"))
	assert_true(rec.has_event("turn:2:player"))


func test_unspent_energy_does_not_carry_over() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	controller.play_card(Factory.inject(controller, Factory.strike(&"s")), _target(controller))
	assert_eq(controller.energy, 2)
	controller.end_player_turn()
	assert_eq(controller.energy, 3)


func test_block_absorbs_enemy_attack_and_resets_at_next_player_turn() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20, 6))
	controller.play_card(Factory.inject(controller, Factory.defend(&"g", 5)))
	controller.end_player_turn()
	assert_eq(controller.player.hp, 79, "6 sát thương - 5 giáp = 1")
	assert_eq(controller.player.block, 0, "giáp của người chơi xóa ở đầu lượt của họ")


func test_hand_is_discarded_but_retain_cards_stay() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var keep := Factory.inject(controller, Factory.strike(&"keep", 6, {"retain": true}))
	var plain := Factory.inject(controller, Factory.strike(&"plain"))
	controller.end_player_turn()
	assert_eq(controller.deck.find_pile(keep), Deck.HAND)
	assert_ne(controller.deck.find_pile(plain), Deck.HAND)


func test_player_statuses_decay_at_end_of_player_turn() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(20, 0 + 6))
	controller.player.add_status(Factory.weak(), 2)
	controller.end_player_turn()
	assert_eq(controller.player.get_status(&"weak"), 1)


func test_enemy_block_clears_at_the_start_of_its_own_turn() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var datas: Array[EnemyData] = [registry.get_enemy(&"goblin")]
	var controller := _started(Factory.fillers(10), datas)
	var goblin := _target(controller)
	controller.end_player_turn()  # lượt 1: Stab
	assert_eq(goblin.combatant.block, 0)
	controller.end_player_turn()  # lượt 2: Guard
	assert_eq(goblin.combatant.block, 8, "giáp tồn tại qua lượt người chơi")
	controller.end_player_turn()  # lượt 3: Stab (giáp cũ bị xóa đầu lượt quái)
	assert_eq(goblin.combatant.block, 0)


func test_real_goblin_sequence_damages_player_as_designed() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var datas: Array[EnemyData] = [registry.get_enemy(&"goblin")]
	var controller := _started(Factory.fillers(10), datas)
	var hp: Array = []
	for i in 4:
		controller.end_player_turn()
		hp.append(controller.player.hp)
	assert_eq(hp, [73, 73, 66, 66], "Stab 7, Guard, Stab 7, Guard")


func test_real_acolyte_strength_scales_damage_and_intent() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var datas: Array[EnemyData] = [registry.get_enemy(&"acolyte")]
	var controller := _started(Factory.fillers(10), datas)
	var acolyte := _target(controller)
	assert_false(acolyte.intent.attacks, "chiêu đầu là Ritual (buff)")
	var hp: Array = []
	for i in 5:
		controller.end_player_turn()
		hp.append(controller.player.hp)
	# Ritual(+2 STR) | Slash 6+2=8 | Slash 8 | Ritual(+2 -> 4) | Slash 6+4=10
	assert_eq(hp, [80, 72, 64, 64, 54])
	assert_eq(acolyte.combatant.get_status(&"strength"), 4)


func test_enemy_intent_is_replanned_after_acting() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var datas: Array[EnemyData] = [registry.get_enemy(&"goblin")]
	var controller := _started(Factory.fillers(10), datas)
	assert_eq(_target(controller).current_move.id, &"stab")
	controller.end_player_turn()
	assert_eq(_target(controller).current_move.id, &"guard")
	assert_true(_target(controller).intent.defends)


func test_dead_enemies_do_not_act_and_are_reported_once() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 20), Factory.dummy_enemy(&"b", 20)]
	var controller := _started(Factory.fillers(10), datas)
	var rec := Recorder.new(controller)
	_target(controller, 0).combatant.take_damage(999)
	controller.end_player_turn()
	assert_eq(rec.count("acted:"), 1)
	assert_true(rec.has_event("acted:b_1:hit"))
	assert_eq(rec.count("defeated:"), 1)
	controller.end_player_turn()
	assert_eq(rec.count("defeated:"), 1, "không báo chết lần hai")


## --- Thắng / thua ---

func test_killing_the_last_enemy_wins_immediately_and_once() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(6))
	var rec := Recorder.new(controller)
	var strike := Factory.inject(controller, Factory.strike(&"finisher", 6))
	assert_true(controller.play_card(strike, _target(controller)))
	assert_eq(controller.state.phase, P.VICTORY)
	assert_eq(controller.end_reason, BattleController.END_VICTORY)
	assert_eq(rec.with_prefix("ended:"), ["ended:true"])
	assert_eq(rec.count("defeated:"), 1)
	assert_false(controller.play_card(Factory.inject(controller, Factory.strike(&"late")), null))
	assert_eq(rec.last_rejection(), "battle_over")
	assert_false(controller.end_player_turn())
	assert_eq(rec.last_rejection(), "battle_over")
	assert_eq(rec.count("ended:"), 1, "battle_ended chỉ phát một lần")


func test_player_dying_on_enemy_turn_stops_remaining_enemies() -> void:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 20, 6), Factory.dummy_enemy(&"b", 20, 6)]
	var controller := _started(Factory.fillers(10), datas, 1, null, 5)
	var rec := Recorder.new(controller)
	controller.end_player_turn()
	assert_eq(controller.state.phase, P.DEFEAT)
	assert_eq(controller.end_reason, BattleController.END_DEFEAT)
	assert_eq(rec.count("acted:"), 1, "quái thứ hai không được đánh xác chết")
	assert_eq(rec.with_prefix("ended:"), ["ended:false"])
	assert_eq(controller.player.hp, 0)


func test_defeat_takes_priority_when_both_sides_are_dead() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy())
	var rec := Recorder.new(controller)
	controller.player.take_damage(999)
	_target(controller).combatant.take_damage(999)
	assert_true(controller._check_end())
	assert_eq(controller.state.phase, P.DEFEAT)
	assert_eq(rec.with_prefix("ended:"), ["ended:false"])


func test_turn_cap_ends_a_stalled_battle_as_defeat() -> void:
	var guard_only: Array[EnemyMove] = [Factory.block_move(&"guard", 5)]
	var datas: Array[EnemyData] = [Factory.enemy(&"turtle", 30, guard_only)]
	var config := BattleConfig.new()
	config.turn_cap = 3
	var controller := _started(Factory.fillers(10), datas, 1, config)
	var rec := Recorder.new(controller)
	controller.end_player_turn()
	controller.end_player_turn()
	assert_false(controller.state.is_terminal())
	controller.end_player_turn()
	assert_eq(controller.state.phase, P.DEFEAT)
	assert_eq(controller.end_reason, BattleController.END_TURN_CAP)
	assert_eq(rec.with_prefix("ended:"), ["ended:false"])
	assert_eq(controller.turn, 3)


func test_player_combatant_is_shared_so_hp_persists_after_battle() -> void:
	var player := Factory.combatant(&"player", 80)
	var controller := BattleController.create_from_data(player, Factory.fillers(10), _one_dummy(),
			Factory.registry(), 1)
	controller.start_battle()
	controller.end_player_turn()
	assert_true(controller.player == player)
	assert_eq(player.hp, 74, "caller đọc lại máu từ chính Combatant của mình")


## --- Tái lập theo seed ---

func _scripted_log(seed_value: int) -> Array:
	var datas: Array[EnemyData] = [Factory.dummy_enemy(&"a", 60, 4), Factory.dummy_enemy(&"b", 60, 5)]
	var controller := _started(Factory.fillers(12), datas, seed_value)
	var rec := Recorder.new(controller)
	var hands: Array = []
	for i in 4:
		var ids: Array = []
		for card in controller.deck.get_pile(Deck.HAND):
			ids.append(String(card.data.id))
		hands.append(ids)
		for card in controller.deck.get_pile(Deck.HAND):
			if controller.can_play(card):
				controller.play_card(card, controller.living_enemies()[0])
		controller.end_player_turn()
	return [rec.events, hands, controller.player.hp]


func test_same_seed_replays_identically_and_different_seed_differs() -> void:
	assert_eq(_scripted_log(77), _scripted_log(77))
	assert_ne(_scripted_log(77)[1], _scripted_log(78)[1], "tay bài phải khác khi đổi seed")


func test_check_end_is_idempotent_after_the_battle_is_over() -> void:
	var controller := _started(Factory.fillers(10), _one_dummy(6))
	var rec := Recorder.new(controller)
	controller.play_card(Factory.inject(controller, Factory.strike(&"finisher", 6)), _target(controller))
	assert_true(controller._check_end())
	assert_true(controller._check_end())
	assert_eq(rec.with_prefix("ended:"), ["ended:true"], "gọi lại không được phát battle_ended lần nữa")
	assert_eq(rec.with_prefix("state:"), ["state:PLAYER_TURN>VICTORY"], "không có chuyển trạng thái thừa")
