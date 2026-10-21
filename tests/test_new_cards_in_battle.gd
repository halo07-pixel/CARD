extends "res://tests/test_case.gd"
## Mỗi thẻ mới (đọc từ data/cards/*.tres thật) được chơi trong một trận thật qua BattleController.

const Factory := preload("res://tests/combat_factory.gd")
const Recorder := preload("res://tests/battle_recorder.gd")

var _cards: CardRegistry


func before_each() -> void:
	_cards = CardRegistry.load_from_dir("res://data/cards")


func _real(id: StringName) -> CardInstance:
	return _cards.create_instances([id] as Array[StringName])[0]


func _battle(enemy_count: int = 1, enemy_hp: int = 20) -> BattleController:
	var datas: Array[EnemyData] = []
	for i in enemy_count:
		datas.append(Factory.dummy_enemy(StringName("e%d" % i), enemy_hp, 0 + 6))
	var controller := Factory.battle(Factory.fillers(10), datas)
	controller.start_battle()
	return controller


func _hp(controller: BattleController, index: int = 0) -> int:
	return controller.enemies[index].combatant.hp


func test_bash_deals_damage_applies_vulnerable_and_costs_two() -> void:
	var controller := _battle()
	var bash := Factory.inject(controller, _real(&"bash"))
	assert_true(controller.play_card(bash, controller.enemies[0]))
	assert_eq(controller.energy, 1)
	assert_eq(_hp(controller), 12)
	assert_eq(controller.enemies[0].combatant.get_status(&"vulnerable"), 2)
	assert_true(controller.play_card(Factory.inject(controller, Factory.strike(&"follow_up", 6)), controller.enemies[0]))
	assert_eq(_hp(controller), 3, "Vulnerable: 6 x 1.5 = 9 sát thương")


func test_cleave_hits_all_enemies() -> void:
	var controller := _battle(2)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"cleave"))))
	assert_eq(_hp(controller, 0), 12)
	assert_eq(_hp(controller, 1), 12)


func test_iron_wave_gives_block_and_damage() -> void:
	var controller := _battle()
	assert_true(controller.play_card(Factory.inject(controller, _real(&"iron_wave")), controller.enemies[0]))
	assert_eq(controller.player.block, 5)
	assert_eq(_hp(controller), 15)


func test_pommel_strike_damages_and_draws_one() -> void:
	var controller := _battle()
	var hand_before := controller.deck.count(Deck.HAND)
	var pommel := Factory.inject(controller, _real(&"pommel_strike"))
	assert_true(controller.play_card(pommel, controller.enemies[0]))
	assert_eq(_hp(controller), 11)
	assert_eq(controller.deck.count(Deck.HAND), hand_before + 1, "+1 chèn, -1 chơi, +1 rút")


func test_shrug_it_off_gives_block_and_draws_one() -> void:
	var controller := _battle()
	var hand_before := controller.deck.count(Deck.HAND)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"shrug_it_off"))))
	assert_eq(controller.player.block, 8)
	assert_eq(controller.deck.count(Deck.HAND), hand_before + 1)


func test_twin_strike_hits_twice() -> void:
	var controller := _battle()
	assert_true(controller.play_card(Factory.inject(controller, _real(&"twin_strike")), controller.enemies[0]))
	assert_eq(_hp(controller), 10)


func test_twin_strike_stops_after_the_first_hit_kills() -> void:
	var controller := _battle(1, 5)
	var rec := Recorder.new(controller)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"twin_strike")), controller.enemies[0]))
	assert_eq(_hp(controller), 0)
	assert_eq(controller.state.phase, BattleState.Phase.VICTORY)
	assert_eq(rec.with_prefix("ended:"), ["ended:true"])


func test_adrenaline_gains_energy_draws_two_and_exhausts() -> void:
	var controller := _battle()
	var hand_before := controller.deck.count(Deck.HAND)
	var adrenaline := Factory.inject(controller, _real(&"adrenaline"))
	assert_true(controller.play_card(adrenaline))
	assert_eq(controller.energy, 4, "cost 0, +1 năng lượng")
	assert_eq(controller.deck.count(Deck.HAND), hand_before + 2, "+1 chèn, -1 chơi, +2 rút")
	assert_eq(controller.deck.find_pile(adrenaline), Deck.EXHAUST)


func test_thunderclap_damages_and_weakens_everyone() -> void:
	var controller := _battle(2)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"thunderclap"))))
	for i in 2:
		assert_eq(_hp(controller, i), 16)
		assert_eq(controller.enemies[i].combatant.get_status(&"vulnerable"), 1)


func test_upgraded_cards_are_stronger() -> void:
	var controller := _battle()
	assert_true(controller.play_card(Factory.inject(controller, _real(&"strike+")), controller.enemies[0]))
	assert_eq(_hp(controller), 11, "Strike+ gây 9")
	assert_true(controller.play_card(Factory.inject(controller, _real(&"defend+"))))
	assert_eq(controller.player.block, 8, "Defend+ cho 8 giáp")


## --- Thẻ Giai đoạn 2.1 ---

func test_inflame_is_a_power_that_grants_strength() -> void:
	var controller := _battle()
	var inflame := Factory.inject(controller, _real(&"inflame"))
	assert_true(controller.play_card(inflame))
	assert_eq(controller.player.get_status(&"strength"), 2)
	assert_eq(controller.deck.find_pile(inflame), Deck.EXHAUST, "Power rời vòng xáo bài")
	assert_eq(controller.energy, 2)


func test_demon_form_and_barricade_cost_three_and_apply_their_status() -> void:
	var controller := _battle()
	assert_true(controller.play_card(Factory.inject(controller, _real(&"demon_form"))))
	assert_eq(controller.energy, 0)
	assert_eq(controller.player.get_status(&"demon_form"), 2)
	var other := _battle()
	assert_true(other.play_card(Factory.inject(other, _real(&"barricade"))))
	assert_eq(other.player.get_status(&"barricade"), 1)
	assert_eq(other.energy, 0)


func test_deadly_poison_ticks_at_the_start_of_the_enemy_turn() -> void:
	var controller := _battle(1, 30)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"deadly_poison")), controller.enemies[0]))
	assert_eq(controller.enemies[0].combatant.get_status(&"poison"), 5)
	controller.end_player_turn()
	assert_eq(_hp(controller), 25)
	assert_eq(controller.enemies[0].combatant.get_status(&"poison"), 4)


func test_bloodletting_costs_hp_ignoring_block_and_gives_energy() -> void:
	var controller := _battle()
	controller.player.gain_block(10)
	assert_true(controller.play_card(Factory.inject(controller, _real(&"bloodletting"))))
	assert_eq(controller.player.hp, 77)
	assert_eq(controller.player.block, 10, "mất máu trực tiếp không đụng giáp")
	assert_eq(controller.energy, 5, "cost 0, +2 năng lượng")


func test_bandage_up_heals_and_exhausts() -> void:
	var controller := _battle()
	controller.player.take_damage(30)
	var bandage := Factory.inject(controller, _real(&"bandage_up"))
	assert_true(controller.play_card(bandage))
	assert_eq(controller.player.hp, 54)
	assert_eq(controller.deck.find_pile(bandage), Deck.EXHAUST)


func test_a_card_that_kills_the_player_stops_resolving_its_other_effects() -> void:
	var controller := _battle()
	var rec := Recorder.new(controller)
	controller.player.take_damage(77)  # còn 3 máu
	assert_true(controller.play_card(Factory.inject(controller, _real(&"bloodletting"))))
	assert_false(controller.player.is_alive())
	assert_eq(controller.energy, 3, "effect nhận năng lượng phía sau bị bỏ")
	assert_eq(controller.state.phase, BattleState.Phase.DEFEAT)
	assert_eq(rec.with_prefix("ended:"), ["ended:false"])
