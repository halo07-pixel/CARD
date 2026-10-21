class_name StatusData
extends Resource
## Định nghĩa một trạng thái (dữ liệu thuần). Hiệu ứng là các HỆ SỐ và/hoặc TRIGGER, không có code
## riêng cho từng trạng thái.

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
@export var triggers: Array[TriggerData] = []
@export var decay_after_turn_start: bool = false  ## giảm 1 SAU khi trigger đầu lượt nổ (Poison)
@export var retains_block: bool = false           ## giáp không bị xóa đầu lượt (Barricade)
@export var negates_debuff: bool = false          ## mỗi stack chặn 1 lần bị gắn debuff (Artifact)


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
	if decay_after_turn_start and stack_mode != StackMode.DURATION:
		errors.append("chỉ DURATION mới giảm sau trigger đầu lượt")
	if negates_debuff and is_debuff:
		errors.append("status chặn debuff không được tự là debuff")
	if stack_mode == StackMode.DURATION and (not is_zero_approx(damage_dealt_add_per_stack) \
			or not is_zero_approx(block_gain_add_per_stack)):
		errors.append("DURATION không dùng *_add_per_stack (amount là số lượt, không phải cường độ)")
	for mult_name: String in ["damage_dealt_mult", "damage_taken_mult", "block_gain_mult"]:
		if float(get(mult_name)) < 0.0:
			errors.append("%s không được âm" % mult_name)
	for i in triggers.size():
		var trigger := triggers[i]
		if trigger == null:
			errors.append("triggers[%d] là null" % i)
			continue
		for message: String in trigger.validate():
			errors.append("triggers[%d]: %s" % [i, message])
	return errors
