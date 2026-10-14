extends "res://tests/test_case.gd"

const TEST_DIR := "user://test_saves"
var _original_dir: String


func before_each() -> void:
	_original_dir = SaveSystem.save_dir
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	SaveSystem.save_dir = TEST_DIR
	SaveSystem.delete_run()
	RunState.end_run(false) if RunState.is_active else null


func after_each() -> void:
	SaveSystem.delete_run()
	SaveSystem.save_dir = _original_dir


func _start(seed_value: int = 12345) -> bool:
	var deck: Array[String] = ["strike", "strike", "defend"]
	return RunState.start_new_run("warrior", 80, deck, 99, seed_value)


func test_start_new_run_sets_initial_values() -> void:
	assert_true(_start())
	assert_true(RunState.is_active)
	assert_eq(RunState.hp, 80)
	assert_eq(RunState.max_hp, 80)
	assert_eq(RunState.gold, 99)
	assert_eq(RunState.deck.size(), 3)


func test_start_new_run_rejects_invalid_params() -> void:
	var empty_deck: Array[String] = []
	assert_false(RunState.start_new_run("", 80, ["a"] as Array[String]))
	assert_false(RunState.start_new_run("warrior", 0, ["a"] as Array[String]))
	assert_false(RunState.start_new_run("warrior", 80, empty_deck))


func test_start_copies_deck_instead_of_aliasing() -> void:
	var deck: Array[String] = ["strike"]
	RunState.start_new_run("warrior", 80, deck, 99, 1)
	deck.append("hacked")
	assert_eq(RunState.deck.size(), 1)


func test_change_hp_is_clamped() -> void:
	_start()
	RunState.change_hp(-1000)
	assert_eq(RunState.hp, 0)
	RunState.change_hp(1000)
	assert_eq(RunState.hp, 80)


func test_change_gold_cannot_go_negative() -> void:
	_start()
	assert_false(RunState.change_gold(-100))
	assert_eq(RunState.gold, 99)
	assert_true(RunState.change_gold(-99))
	assert_eq(RunState.gold, 0)


func test_mutators_refuse_when_no_active_run() -> void:
	assert_false(RunState.is_active)
	assert_false(RunState.change_hp(-1))
	assert_false(RunState.change_gold(1))
	assert_false(RunState.add_card("strike"))


func test_remove_card_removes_only_one_copy() -> void:
	_start()
	assert_true(RunState.remove_card("strike"))
	assert_eq(RunState.deck.count("strike"), 1)
	assert_false(RunState.remove_card("missing"))


func test_to_dict_returns_copies() -> void:
	_start()
	var data := RunState.to_dict()
	(data["deck"] as Array).append("hacked")
	assert_eq(RunState.deck.size(), 3)


func test_save_and_load_roundtrip_preserves_everything() -> void:
	_start(9007199254740993)  # lớn hơn 2^53: float sẽ làm mất độ chính xác
	RunState.change_hp(-10)
	RunState.add_card("bash")
	RunState.rng.randi()
	var expected_next := RunState.rng.randi()
	RunState.start_new_run("x", 1, ["x"] as Array[String])  # làm bẩn state
	_start(9007199254740993)
	RunState.change_hp(-10)
	RunState.add_card("bash")
	RunState.rng.randi()
	assert_true(RunState.save_to_disk())
	var saved_seed := RunState.seed_value
	RunState.start_new_run("other", 5, ["z"] as Array[String])
	assert_true(RunState.load_from_disk())
	assert_eq(RunState.character_id, "warrior")
	assert_eq(RunState.seed_value, saved_seed)
	assert_eq(RunState.hp, 70)
	assert_eq(RunState.deck.size(), 4)
	assert_eq(RunState.rng.randi(), expected_next, "RNG phải tiếp tục đúng chuỗi sau khi load")


func test_from_dict_rejects_invalid_and_keeps_current_state() -> void:
	_start()
	var bad := RunState.to_dict()
	bad["hp"] = 9999  # vượt max_hp
	assert_false(RunState.from_dict(bad))
	assert_eq(RunState.hp, 80, "state hiện tại không được bị ghi đè")
	assert_false(RunState.from_dict({}))
	var wrong_type := RunState.to_dict()
	wrong_type["deck"] = "not an array"
	assert_false(RunState.from_dict(wrong_type))


func test_end_run_deactivates_and_deletes_save() -> void:
	_start()
	RunState.save_to_disk()
	assert_true(RunState.end_run(true))
	assert_false(RunState.is_active)
	assert_false(SaveSystem.has_run())
	assert_false(RunState.end_run(true), "end_run lần 2 phải bị từ chối")
