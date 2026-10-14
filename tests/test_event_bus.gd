extends "res://tests/test_case.gd"

var _received: Array = []


func test_declares_expected_signals() -> void:
	for signal_name in ["scene_change_requested", "scene_changed", "run_started",
			"run_ended", "settings_changed", "sfx_requested", "music_requested"]:
		assert_true(EventBus.has_signal(signal_name), "thiếu signal " + signal_name)


func test_signal_reaches_listener() -> void:
	_received.clear()
	var listener := func(victory: bool) -> void: _received.append(victory)
	EventBus.run_ended.connect(listener)
	EventBus.run_ended.emit(true)
	EventBus.run_ended.disconnect(listener)
	assert_eq(_received, [true])
