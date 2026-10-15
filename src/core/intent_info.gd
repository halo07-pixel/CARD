class_name IntentInfo
extends RefCounted
## Thông tin ý định để UI hiển thị (loại biểu tượng + con số sát thương đã tính đủ
## Strength/Weak/Vulnerable). Dựng bằng IntentInfo.build(); dựng lại khi trạng thái hai bên đổi.

var move: EnemyMove = null
var attacks: bool = false
var defends: bool = false
var buffs: bool = false     ## tự cộng trạng thái cho bản thân
var debuffs: bool = false   ## gắn trạng thái lên phe người chơi
## Hiển thị kiểu "6 x 2": mô tả effect DAMAGE đầu tiên; total_damage cộng mọi effect DAMAGE.
var damage_per_hit: int = 0
var hit_count: int = 0
var total_damage: int = 0


## target = người chơi (dùng để tính Vulnerable của họ).
static func build(p_move: EnemyMove, source: Combatant, target: Combatant) -> IntentInfo:
	var info := IntentInfo.new()
	info.move = p_move
	for effect in p_move.effects:
		match effect.type:
			EffectData.Type.DAMAGE:
				var per_hit := DamageCalculator.compute_damage(effect.amount, source, target)
				if not info.attacks:
					info.damage_per_hit = per_hit
					info.hit_count = effect.hits
				info.attacks = true
				info.total_damage += per_hit * effect.hits
			EffectData.Type.BLOCK:
				info.defends = true
			EffectData.Type.APPLY_STATUS:
				if effect.target == EffectData.Target.SELF:
					info.buffs = true
				else:
					info.debuffs = true
	return info
