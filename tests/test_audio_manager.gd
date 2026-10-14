extends "res://tests/test_case.gd"


func test_custom_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index(AudioManager.BUS_MUSIC), -1)
	assert_ne(AudioServer.get_bus_index(AudioManager.BUS_SFX), -1)


func test_set_bus_volume_clamps_and_mutes_at_zero() -> void:
	assert_true(AudioManager.set_bus_volume(AudioManager.BUS_SFX, 5.0))
	var index := AudioServer.get_bus_index(AudioManager.BUS_SFX)
	assert_almost_eq(AudioServer.get_bus_volume_db(index), 0.0, 0.01)
	assert_false(AudioServer.is_bus_mute(index))
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, 0.0)
	assert_true(AudioServer.is_bus_mute(index))
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, 0.8)


func test_unknown_bus_is_rejected() -> void:
	assert_false(AudioManager.set_bus_volume(&"NoSuchBus", 1.0))


func test_missing_audio_file_returns_false_without_crash() -> void:
	assert_false(AudioManager.play_sfx(&"definitely_missing"))
	assert_false(AudioManager.play_music(&"definitely_missing"))
