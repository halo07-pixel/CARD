extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _data() -> EnemyData:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"hit", 6), Factory.block_move(&"guard", 5)]
	return Factory.enemy(&"dummy", 25, moves)


func test_create_builds_combatant_from_data() -> void:
	var unit := EnemyUnit.create(_data(), Factory.rng())
	assert_eq(unit.combatant.max_hp, 25)
	assert_eq(unit.combatant.hp, 25)
	assert_eq(unit.combatant.id, &"dummy")
	assert_true(unit.is_alive())
	assert_true(unit.current_move == null and unit.intent == null)


func test_unit_id_distinguishes_duplicates() -> void:
	var a := EnemyUnit.create(_data(), Factory.rng(), &"dummy_0")
	var b := EnemyUnit.create(_data(), Factory.rng(), &"dummy_1")
	assert_ne(a.combatant.id, b.combatant.id)
	a.combatant.take_damage(10)
	assert_eq(b.combatant.hp, 25, "hai quái cùng loại không dùng chung máu")


func test_create_rejects_invalid_inputs() -> void:
	assert_true(EnemyUnit.create(null, Factory.rng()) == null)
	assert_true(EnemyUnit.create(_data(), null) == null)
	assert_true(EnemyUnit.create(EnemyData.new(), Factory.rng()) == null, "dữ liệu không hợp lệ")


func test_plan_next_move_sets_move_and_intent() -> void:
	var player := Factory.combatant(&"player", 80)
	var unit := EnemyUnit.create(_data(), Factory.rng())
	var intent := unit.plan_next_move(player)
	assert_eq(unit.current_move.id, &"hit")
	assert_true(intent.attacks)
	assert_eq(unit.intent.damage_per_hit, 6)
	unit.plan_next_move(player)
	assert_eq(unit.current_move.id, &"guard")
	assert_true(unit.intent.defends)


func test_refresh_intent_reflects_status_changes_without_changing_move() -> void:
	var player := Factory.combatant(&"player", 80)
	var unit := EnemyUnit.create(_data(), Factory.rng())
	unit.plan_next_move(player)
	assert_eq(unit.intent.damage_per_hit, 6)
	player.add_status(Factory.vulnerable(), 2)
	unit.refresh_intent(player)
	assert_eq(unit.intent.damage_per_hit, 9)
	assert_eq(unit.current_move.id, &"hit", "refresh không được đổi chiêu")
	unit.combatant.add_status(Factory.strength(), 3)
	unit.refresh_intent(player)
	assert_eq(unit.intent.damage_per_hit, 13, "(6+3) x 1.5 = 13.5 -> 13")


func test_dead_unit_or_missing_player_plans_nothing() -> void:
	var player := Factory.combatant(&"player", 80)
	var unit := EnemyUnit.create(_data(), Factory.rng())
	assert_true(unit.plan_next_move(null) == null)
	unit.combatant.take_damage(999)
	assert_true(unit.plan_next_move(player) == null)
	assert_true(unit.refresh_intent(player) == unit.intent)
