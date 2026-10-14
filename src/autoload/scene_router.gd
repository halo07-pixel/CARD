extends CanvasLayer
## Chuyển cảnh có fade. Nhận yêu cầu qua EventBus.scene_change_requested.
## State guard: đang chuyển cảnh thì từ chối yêu cầu mới.

const FADE_TIME := 0.15
const OVERLAY_LAYER := 100

var _fade := ColorRect.new()
var _busy: bool = false


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	EventBus.scene_change_requested.connect(change_scene)


func is_busy() -> bool:
	return _busy


## Trả về true nếu yêu cầu được chấp nhận; việc chuyển diễn ra bất đồng bộ,
## hoàn tất khi EventBus.scene_changed được phát.
func change_scene(path: String) -> bool:
	if _busy:
		push_warning("SceneRouter: đang chuyển cảnh, bỏ qua yêu cầu %s" % path)
		return false
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: không tìm thấy scene %s" % path)
		return false
	_busy = true
	_transition(path)
	return true


func _transition(path: String) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: change_scene_to_file lỗi %d (%s)" % [err, path])
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	if err == OK:
		EventBus.scene_changed.emit(path)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
