extends "res://tests/test_case.gd"

const DUMMY := "res://tests/fixtures/dummy_scene.tscn"


func test_rejects_missing_scene() -> void:
	assert_false(SceneRouter.change_scene("res://does/not/exist.tscn"))
	assert_false(SceneRouter.is_busy())


func test_changes_scene_and_emits_signal() -> void:
	var emitted: Array[String] = []
	var listener := func(path: String) -> void: emitted.append(path)
	EventBus.scene_changed.connect(listener)
	assert_true(SceneRouter.change_scene(DUMMY))
	assert_true(SceneRouter.is_busy())
	await EventBus.scene_changed
	EventBus.scene_changed.disconnect(listener)
	assert_eq(emitted, [DUMMY])
	assert_false(SceneRouter.is_busy())


func test_rejects_second_request_while_busy() -> void:
	assert_true(SceneRouter.change_scene(DUMMY))
	assert_false(SceneRouter.change_scene(DUMMY))
	await EventBus.scene_changed
	assert_false(SceneRouter.is_busy())
