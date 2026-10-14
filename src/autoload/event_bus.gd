extends Node
## Trung tâm Signal toàn cục ("signal up"). KHÔNG chứa logic.
## Node/system phát tín hiệu ở đây, ai quan tâm thì tự kết nối.

@warning_ignore_start("unused_signal")
signal scene_change_requested(path: String)
signal scene_changed(path: String)
signal run_started(character_id: String)
signal run_ended(victory: bool)
signal settings_changed(settings: Dictionary)
signal sfx_requested(sfx_name: StringName)
signal music_requested(track_name: StringName)
@warning_ignore_restore("unused_signal")
