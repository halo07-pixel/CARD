class_name StatusData
extends Resource
## Định nghĩa một trạng thái (dữ liệu thuần). Hiệu ứng là các HỆ SỐ, không có code riêng
## cho từng trạng thái. Trạng thái có trigger (Poison...) sẽ do hệ thống hook ở Giai đoạn 2 xử lý.

enum StackMode {
	INTENSITY,  ## amount là cường độ (Strength +2). Cộng dồn trực tiếp.
	DURATION,   ## amount là số lượt còn lại (Weak 2). Cộng dồn số lượt.
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_id: StringName = &""
@export var is_debuff: bool = false
@export var stack_mode: StackMode = StackMode.DURATION
@export var decays_at_turn_end: bool = false  ## giảm 1 vào cuối lượt của chủ sở hữu
@export var can_be_negative: bool = false
@export var damage_dealt_add_per_stack: float = 0.0
@export var damage_dealt_mult: float = 1.0
@export var damage_taken_mult: float = 1.0
@export var block_gain_add_per_stack: float = 0.0
@export var block_gain_mult: float = 1.0


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if can_be_negative and stack_mode != StackMode.INTENSITY:
		errors.append("chỉ INTENSITY mới có thể âm")
	if decays_at_turn_end and stack_mode != StackMode.DURATION:
		errors.append("chỉ DURATION mới giảm theo lượt")
	if stack_mode == StackMode.DURATION and (not is_zero_approx(damage_dealt_add_per_stack) \
			or not is_zero_approx(block_gain_add_per_stack)):
		errors.append("DURATION không dùng *_add_per_stack (amount là số lượt, không phải cường độ)")
	for mult_name: String in ["damage_dealt_mult", "damage_taken_mult", "block_gain_mult"]:
		if float(get(mult_name)) < 0.0:
			errors.append("%s không được âm" % mult_name)
	return errors
