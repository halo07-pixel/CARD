extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")

var _warrior: CharacterData
var _cards: CardRegistry
var _enemies: EnemyRegistry
var _statuses: StatusRegistry


func before_each() -> void:
	# load() trả về Resource được cache dùng chung: nhân bản để test sửa chỉ số không rò sang test khác.
	_warrior = (load("res://data/characters/warrior.tres") as CharacterData).duplicate() as CharacterData
	_cards = CardRegistry.load_from_dir("res://data/cards")
	_enemies = EnemyRegistry.load_from_dir("res://data/enemies")
	_statuses = StatusRegistry.load_from_dir("res://data/statuses")


func _create(enemy_ids: Array[StringName], player_hp: int = -1, seed_value: int = 1,
		turn_cap: int = 0) -> BattleController:
	var player := BattleFactory.create_player(_warrior, player_hp)
	return BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids,
			_cards, _enemies, _statuses, seed_value, turn_cap)


func test_create_player_defaults_to_full_hp_and_clamps() -> void:
	assert_eq(BattleFactory.create_player(_warrior).hp, 80)
	assert_eq(BattleFactory.create_player(_warrior, 50).hp, 50)
	assert_eq(BattleFactory.create_player(_warrior, 999).hp, 80, "không vượt máu tối đa")
	assert_eq(BattleFactory.create_player(_warrior, 50).max_hp, 80)


func test_creates_a_playable_battle_from_data() -> void:
	var controller := _create([&"slime", &"goblin"] as Array[StringName])
	assert_true(controller != null)
	assert_eq(controller.enemies.size(), 2)
	assert_eq(controller.deck.total_count(), 10)
	assert_true(controller.start_battle())
	assert_eq(controller.energy, 3)
	assert_eq(controller.deck.count(Deck.HAND), 5)
	assert_eq(controller.player.hp, 80)


func test_current_hp_carries_into_the_battle() -> void:
	var controller := _create([&"slime"] as Array[StringName], 33)
	assert_eq(controller.player.hp, 33)


func test_character_stats_drive_the_battle_config() -> void:
	_warrior.max_energy = 4
	_warrior.draw_per_turn = 7
	var controller := _create([&"slime"] as Array[StringName])
	controller.start_battle()
	assert_eq(controller.energy, 4)
	assert_eq(controller.deck.count(Deck.HAND), 7)


func test_turn_cap_is_passed_through() -> void:
	var controller := _create([&"slime"] as Array[StringName], -1, 1, 9)
	assert_eq(controller.config.turn_cap, 9)


func test_unknown_enemy_or_card_or_missing_registry_returns_null() -> void:
	var player := BattleFactory.create_player(_warrior)
	var enemy_ids: Array[StringName] = [&"slime"]
	assert_true(_create([&"dragon"] as Array[StringName]) == null, "quái không tồn tại")
	var bad_deck: Array[StringName] = [&"strike", &"ghost_card"]
	assert_true(BattleFactory.create(_warrior, player, bad_deck, enemy_ids, _cards, _enemies, _statuses) == null,
			"thẻ không tồn tại")
	var empty_deck: Array[StringName] = []
	assert_true(BattleFactory.create(_warrior, player, empty_deck, enemy_ids, _cards, _enemies, _statuses) == null,
			"bộ bài rỗng")
	assert_true(BattleFactory.create(null, player, _warrior.starting_deck, enemy_ids, _cards, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, null, _warrior.starting_deck, enemy_ids, _cards, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, null, _enemies, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, null, _statuses) == null)
	assert_true(BattleFactory.create(_warrior, player, _warrior.starting_deck, enemy_ids, _cards, _enemies, null) == null)


func test_dead_player_cannot_start_a_battle() -> void:
	assert_true(_create([&"slime"] as Array[StringName], 0) == null)


func test_same_seed_gives_same_opening_hand() -> void:
	var first := _create([&"slime"] as Array[StringName], -1, 42)
	var second := _create([&"slime"] as Array[StringName], -1, 42)
	first.start_battle()
	second.start_battle()
	var a: Array = []
	var b: Array = []
	for card in first.deck.get_pile(Deck.HAND):
		a.append(String(card.data.id))
	for card in second.deck.get_pile(Deck.HAND):
		b.append(String(card.data.id))
	assert_eq(a, b)
