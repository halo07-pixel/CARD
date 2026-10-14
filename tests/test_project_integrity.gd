extends "res://tests/test_case.gd"
## Mọi script/scene/resource trong game phải nạp được (bắt lỗi cú pháp, tham chiếu hỏng).

const SCAN_ROOTS: Array[String] = ["res://src", "res://scenes", "res://data"]


func test_all_scripts_compile() -> void:
	for path in _collect(["gd"]):
		var script := load(path) as GDScript
		assert_true(script != null and script.can_instantiate(), "script lỗi: " + path)


func test_all_scenes_load_and_instantiate() -> void:
	for path in _collect(["tscn"]):
		var scene := load(path) as PackedScene
		assert_true(scene != null, "scene không nạp được: " + path)
		if scene == null:
			continue
		var node := scene.instantiate()
		assert_true(node != null, "scene không instantiate được: " + path)
		if node != null:
			node.free()


func test_all_data_resources_load() -> void:
	for path in _collect(["tres"]):
		assert_true(load(path) != null, "resource không nạp được: " + path)


func test_main_scene_is_configured_and_exists() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	assert_false(main_scene.is_empty())
	assert_true(ResourceLoader.exists(main_scene), "main scene không tồn tại: " + main_scene)


func test_base_resolution_is_1080p() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)


func _collect(extensions: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for root in SCAN_ROOTS:
		_scan(root, extensions, result)
	return result


func _scan(dir_path: String, extensions: Array[String], out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_scan(dir_path.path_join(sub), extensions, out)
	for file_name in dir.get_files():
		if file_name.get_extension() in extensions:
			out.append(dir_path.path_join(file_name))
