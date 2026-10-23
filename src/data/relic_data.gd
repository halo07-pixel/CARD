class_name RelicData
extends Resource
## Định nghĩa một relic (dữ liệu thuần). Relic mang trigger (dùng lại hệ thống sự kiện của status)
## và/hoặc bonus tĩnh áp vào cấu hình trận. Hiệu ứng "khi nhặt" (vd. +máu tối đa vĩnh viễn) thuộc
## tầng run (Giai đoạn 4), KHÔNG nằm ở đây.
## LƯU Ý: enum lưu dạng số nguyên trong .tres -> giá trị mới luôn thêm vào CUỐI.

enum Rarity { STARTER, COMMON, UNCOMMON, RARE, BOSS, SHOP }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_id: StringName = &""
@export var rarity: Rarity = Rarity.COMMON
@export var character_id: StringName = &""  ## rỗng = dùng chung mọi nhân vật
@export var triggers: Array[TriggerData] = []
@export var max_energy_bonus: int = 0       ## cộng vào năng lượng tối đa mỗi lượt
@export var draw_per_turn_bonus: int = 0    ## cộng vào số thẻ rút mỗi lượt


func has_static_bonus() -> bool:
	return max_energy_bonus != 0 or draw_per_turn_bonus != 0


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if max_energy_bonus < 0:
		errors.append("max_energy_bonus không được âm (hiện %d)" % max_energy_bonus)
	if draw_per_turn_bonus < 0:
		errors.append("draw_per_turn_bonus không được âm (hiện %d)" % draw_per_turn_bonus)
	if triggers.is_empty() and not has_static_bonus():
		errors.append("relic phải có ít nhất một trigger hoặc một bonus tĩnh")
	for i in triggers.size():
		var trigger := triggers[i]
		if trigger == null:
			errors.append("triggers[%d] là null" % i)
			continue
		for message: String in trigger.validate():
			errors.append("triggers[%d]: %s" % [i, message])
	return errors
