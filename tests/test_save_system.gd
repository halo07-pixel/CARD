extends "res://tests/test_case.gd"

const TEST_DIR := "user://test_saves"
var _original_dir: String


func before_each() -> void:
	_original_dir = SaveSystem.save_dir
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	SaveSystem.save_dir = TEST_DIR
	SaveSystem.delete_run()
	DirAccess.remove_absolute(TEST_DIR.path_join(SaveSystem.SETTINGS_FILE))


func after_each() -> void:
	SaveSystem.delete_run()
	DirAccess.remove_absolute(TEST_DIR.path_join(SaveSystem.SETTINGS_FILE))
	SaveSystem.save_dir = _original_dir


func test_run_roundtrip() -> void:
	assert_false(SaveSystem.has_run())
	assert_true(SaveSystem.save_run({"hp": 42, "name": "x"}))
	assert_true(SaveSystem.has_run())
	var loaded := SaveSystem.load_run()
	assert_eq(int(loaded["hp"]), 42)
	assert_eq(loaded["name"], "x")


func test_delete_run_removes_file() -> void:
	SaveSystem.save_run({"a": 1})
	SaveSystem.delete_run()
	assert_false(SaveSystem.has_run())
	assert_true(SaveSystem.load_run().is_empty())


func test_corrupt_file_returns_empty_instead_of_crashing() -> void:
	var file := FileAccess.open(TEST_DIR.path_join(SaveSystem.RUN_FILE), FileAccess.WRITE)
	file.store_string("{ not json ")
	file.close()
	assert_true(SaveSystem.load_run().is_empty())


func test_wrong_version_is_rejected() -> void:
	var file := FileAccess.open(TEST_DIR.path_join(SaveSystem.RUN_FILE), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 999, "data": {"hp": 1}}))
	file.close()
	assert_true(SaveSystem.load_run().is_empty())


func test_settings_defaults_when_missing() -> void:
	assert_eq(SaveSystem.load_settings(), SaveSystem.DEFAULT_SETTINGS)


func test_settings_merge_and_ignore_bad_types() -> void:
	SaveSystem.save_settings({"master_volume": 0.5, "sfx_volume": "loud", "unknown": 1})
	var settings := SaveSystem.load_settings()
	assert_almost_eq(settings["master_volume"], 0.5)
	assert_almost_eq(settings["sfx_volume"], SaveSystem.DEFAULT_SETTINGS["sfx_volume"])
	assert_false(settings.has("unknown"))
