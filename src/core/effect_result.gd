class_name EffectResult
extends RefCounted
## Kết quả áp dụng một hiệu ứng lên một mục tiêu (UI/relic dùng để hiển thị và kích hoạt).

var type: EffectData.Type = EffectData.Type.DAMAGE
var source: Combatant = null          ## bên gây ra hiệu ứng (dùng để sinh sự kiện ATTACKED/HP_LOST)
var target: Combatant = null          ## null với DRAW / GAIN_ENERGY
var amount: int = 0                   ## DAMAGE: sát thương đã tính; BLOCK: giáp nhận; DRAW: số thẻ rút được; HEAL/LOSE_HP: máu thực sự hồi/mất
var damage: DamageResult = null       ## chỉ có với DAMAGE
var status_id: StringName = &""       ## chỉ có với APPLY_STATUS
