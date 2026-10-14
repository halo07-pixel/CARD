class_name CardInstance
extends RefCounted
## Một bản thẻ cụ thể trong trận (5 thẻ Strike giống nhau là 5 instance khác nhau).
## Trạng thái tạm (cost_override...) nằm ở đây, KHÔNG sửa CardData gốc.

const NO_COST_OVERRIDE := -1

static var _next_uid: int = 1

var uid: int = 0
var data: CardData = null
var cost_override: int = NO_COST_OVERRIDE


static func create(p_data: CardData) -> CardInstance:
	if p_data == null:
		push_error("CardInstance.create: CardData null")
		return null
	var instance := CardInstance.new()
	instance.uid = _next_uid
	instance.data = p_data
	_next_uid += 1
	return instance


func get_cost() -> int:
	return data.cost if cost_override == NO_COST_OVERRIDE else cost_override


func set_cost_override(value: int) -> void:
	cost_override = maxi(value, 0)


func clear_cost_override() -> void:
	cost_override = NO_COST_OVERRIDE


## Thẻ X-cost chơi được với mọi mức năng lượng (kể cả 0).
func is_playable(energy: int) -> bool:
	if data.unplayable:
		return false
	return data.is_x_cost or get_cost() <= energy
