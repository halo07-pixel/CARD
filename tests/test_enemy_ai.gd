extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")
const P := EnemyData.PatternKind


func _ids(ai: EnemyAI, count: int) -> Array:
	var result: Array = []
	for i in count:
		result.append(String(ai.choose_next_move().id))
	return result


func _sequence_enemy(order: Array[StringName], overrides: Dictionary = {}) -> EnemyData:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"a", 5), Factory.block_move(&"b", 5),
			Factory.attack_move(&"c", 9)]
	var data := Factory.enemy(&"seq", 20, moves, P.SEQUENCE, overrides)
	data.sequence = order
	return data


func test_sequence_loops_in_declared_order_by_default() -> void:
	var data := _sequence_enemy([] as Array[StringName])
	assert_eq(_ids(EnemyAI.new(data, Factory.rng()), 7), ["a", "b", "c", "a", "b", "c", "a"])


func test_sequence_allows_repeated_moves() -> void:
	var data := _sequence_enemy([&"b", &"a", &"a"] as Array[StringName])
	assert_eq(_ids(EnemyAI.new(data, Factory.rng()), 7), ["b", "a", "a", "b", "a", "a", "b"])


func test_sequence_opening_move_sets_start_position() -> void:
	var data := _sequence_enemy([&"a", &"b", &"c"] as Array[StringName], {"opening_move_id": &"c"})
	assert_eq(_ids(EnemyAI.new(data, Factory.rng()), 4), ["c", "a", "b", "c"])


func test_weighted_opening_move_is_used_first_then_weighted() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"a", 5, 1), Factory.attack_move(&"b", 5, 1000)]
	var data := Factory.enemy(&"w", 20, moves, P.WEIGHTED, {"opening_move_id": &"a"})
	var ai := EnemyAI.new(data, Factory.rng(3))
	assert_eq(String(ai.choose_next_move().id), "a")


func test_weighted_never_exceeds_max_consecutive() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"hit", 5, 9, 2), Factory.attack_move(&"other", 3, 1, 0)]
	var data := Factory.enemy(&"w", 20, moves, P.WEIGHTED)
	var ai := EnemyAI.new(data, Factory.rng(7))
	var streak := 0
	var last := ""
	for i in 3000:
		var current := String(ai.choose_next_move().id)
		streak = streak + 1 if current == last else 1
		last = current
		if current == "hit":
			assert_true(streak <= 2, "hit lặp %d lần liên tiếp ở bước %d" % [streak, i])
		if not failures.is_empty():
			return


func test_weighted_never_deadlocks_when_every_move_is_blocked() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"only", 5, 1, 1)]
	var ai := EnemyAI.new(Factory.enemy(&"solo", 20, moves, P.WEIGHTED), Factory.rng())
	for i in 20:
		assert_eq(String(ai.choose_next_move().id), "only")


func test_weighted_distribution_follows_weights() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"heavy", 5, 6), Factory.attack_move(&"light", 3, 4)]
	var ai := EnemyAI.new(Factory.enemy(&"w", 20, moves, P.WEIGHTED), Factory.rng(11))
	var heavy := 0
	var total := 10000
	for i in total:
		if ai.choose_next_move().id == &"heavy":
			heavy += 1
	var ratio := float(heavy) / total
	assert_true(ratio > 0.57 and ratio < 0.63, "tỉ lệ heavy %.3f (kỳ vọng ~0.60)" % ratio)


func test_same_seed_gives_same_moves_and_different_seed_differs() -> void:
	var moves: Array[EnemyMove] = [Factory.attack_move(&"a", 5, 1), Factory.attack_move(&"b", 5, 1),
			Factory.attack_move(&"c", 5, 1)]
	var data := Factory.enemy(&"w", 20, moves, P.WEIGHTED)
	assert_eq(_ids(EnemyAI.new(data, Factory.rng(5)), 40), _ids(EnemyAI.new(data, Factory.rng(5)), 40))
	assert_ne(_ids(EnemyAI.new(data, Factory.rng(5)), 40), _ids(EnemyAI.new(data, Factory.rng(6)), 40))


func test_real_starter_enemies_behave_as_designed() -> void:
	var registry := EnemyRegistry.load_from_dir("res://data/enemies")
	var goblin := EnemyAI.new(registry.get_enemy(&"goblin"), Factory.rng())
	assert_eq(_ids(goblin, 4), ["stab", "guard", "stab", "guard"])
	var acolyte := EnemyAI.new(registry.get_enemy(&"acolyte"), Factory.rng())
	assert_eq(_ids(acolyte, 6), ["ritual", "slash", "slash", "ritual", "slash", "slash"])
	var slime := EnemyAI.new(registry.get_enemy(&"slime"), Factory.rng(2))
	var streak := 0
	var last := ""
	for i in 500:
		var current := String(slime.choose_next_move().id)
		streak = streak + 1 if current == last else 1
		last = current
		assert_true(streak <= (2 if current == "tackle" else 1), "slime vi phạm max_consecutive")
		if not failures.is_empty():
			return
