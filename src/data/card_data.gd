class_name CardData
extends Resource
## Định nghĩa một loại thẻ (dữ liệu thuần). KHÔNG giữ Texture/Node: UI tự tra hình theo icon_id.
## Bản nâng cấp là một CardData riêng (id kết thúc bằng "+"), trỏ tới bằng upgraded_id.

enum CardType { ATTACK, SKILL, POWER }
enum Rarity { STARTER, COMMON, UNCOMMON, RARE }
enum TargetMode { SINGLE_ENEMY, ALL_ENEMIES, SELF, NONE }

const UPGRADE_SUFFIX := "+"

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var character_id: StringName = &""  ## rỗng = thẻ trung tính
@export var cost: int = 1
@export var is_x_cost: bool = false
@export var unplayable: bool = false
@export var target_mode: TargetMode = TargetMode.SINGLE_ENEMY
@export var effects: Array[EffectData] = []
@export var exhaust: bool = false
@export var ethereal: bool = false
@export var innate: bool = false
@export var retain: bool = false
@export var upgraded_id: StringName = &""
@export var icon_id: StringName = &""


func is_upgrade() -> bool:
	return String(id).ends_with(UPGRADE_SUFFIX)


## Chế độ nhắm đúng suy ra từ các hiệu ứng (dùng để validate dữ liệu).
func expected_target_mode() -> TargetMode:
	if _has_target(EffectData.Target.TARGET_ENEMY):
		return TargetMode.SINGLE_ENEMY
	if _has_target(EffectData.Target.ALL_ENEMIES):
		return TargetMode.ALL_ENEMIES
	if _has_target(EffectData.Target.RANDOM_ENEMY):
		return TargetMode.NONE
	return TargetMode.SELF


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if cost < 0:
		errors.append("cost không được âm (hiện %d)" % cost)
	if is_x_cost and cost != 0:
		errors.append("thẻ X-cost phải có cost = 0")
	if not unplayable and effects.is_empty():
		errors.append("thẻ chơi được phải có ít nhất 1 effect")
	for i in effects.size():
		var effect := effects[i]
		if effect == null:
			errors.append("effects[%d] là null" % i)
			continue
		for message: String in effect.validate():
			errors.append("effects[%d]: %s" % [i, message])
	if card_type == CardType.ATTACK and not _has_effect_type(EffectData.Type.DAMAGE):
		errors.append("thẻ ATTACK phải có effect DAMAGE")
	if not effects.is_empty() and target_mode != expected_target_mode():
		errors.append("target_mode %s không khớp effects (cần %s)" % [
			TargetMode.keys()[target_mode], TargetMode.keys()[expected_target_mode()]])
	if not upgraded_id.is_empty() and upgraded_id == id:
		errors.append("upgraded_id không được trùng id")
	if is_upgrade() and not upgraded_id.is_empty():
		errors.append("bản nâng cấp không được có upgraded_id")
	return errors


func _has_target(target: EffectData.Target) -> bool:
	for effect in effects:
		if effect != null and effect.target == target:
			return true
	return false


func _has_effect_type(type: EffectData.Type) -> bool:
	for effect in effects:
		if effect != null and effect.type == type:
			return true
	return false
