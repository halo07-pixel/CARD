class_name EffectData
extends Resource
## Dữ liệu thuần của MỘT hiệu ứng thẻ. Không chứa logic thực thi (việc đó của EffectResolver).

enum Type { DAMAGE, BLOCK, DRAW, GAIN_ENERGY, APPLY_STATUS }
enum Target { SELF, TARGET_ENEMY, ALL_ENEMIES, RANDOM_ENEMY }

@export var type: Type = Type.DAMAGE
@export var amount: int = 0
@export var hits: int = 1
@export var status_id: StringName = &""
@export var target: Target = Target.TARGET_ENEMY


static func create(p_type: Type, p_amount: int, p_target: Target,
		p_hits: int = 1, p_status_id: StringName = &"") -> EffectData:
	var effect := EffectData.new()
	effect.type = p_type
	effect.amount = p_amount
	effect.target = p_target
	effect.hits = p_hits
	effect.status_id = p_status_id
	return effect


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	var type_name: String = Type.keys()[type]
	if amount <= 0:
		errors.append("%s: amount phải > 0 (hiện %d)" % [type_name, amount])
	if hits < 1:
		errors.append("%s: hits phải >= 1 (hiện %d)" % [type_name, hits])
	if hits > 1 and type != Type.DAMAGE:
		errors.append("%s: hits > 1 chỉ dùng cho DAMAGE" % type_name)
	if type == Type.APPLY_STATUS and status_id.is_empty():
		errors.append("APPLY_STATUS: thiếu status_id")
	if type != Type.APPLY_STATUS and not status_id.is_empty():
		errors.append("%s: status_id chỉ dùng cho APPLY_STATUS" % type_name)
	match type:
		Type.DAMAGE:
			if target == Target.SELF:
				errors.append("DAMAGE: không được nhắm SELF")
		Type.BLOCK, Type.DRAW, Type.GAIN_ENERGY:
			if target != Target.SELF:
				errors.append("%s: phải nhắm SELF" % type_name)
	return errors
