class_name EnemyUnit
extends RefCounted
## Một quái trong trận: ghép Combatant (máu/giáp/trạng thái) + dữ liệu + AI + chiêu đang chuẩn bị.
## Tạo bằng EnemyUnit.create() (trả null nếu dữ liệu không hợp lệ).

var combatant: Combatant = null
var data: EnemyData = null
var ai: EnemyAI = null
var current_move: EnemyMove = null
var intent: IntentInfo = null


## unit_id dùng khi có nhiều quái cùng loại (ví dụ "slime_0", "slime_1"); mặc định lấy id dữ liệu.
static func create(p_data: EnemyData, rng: RandomNumberGenerator, unit_id: StringName = &"") -> EnemyUnit:
	if p_data == null or rng == null:
		push_error("EnemyUnit.create: thiếu data hoặc rng")
		return null
	var errors := p_data.validate()
	if not errors.is_empty():
		push_error("EnemyUnit.create: dữ liệu quái '%s' không hợp lệ: %s" % [p_data.id, errors])
		return null
	var unit := EnemyUnit.new()
	unit.data = p_data
	unit.combatant = Combatant.create(p_data.id if unit_id.is_empty() else unit_id,
			p_data.display_name, p_data.max_hp)
	unit.ai = EnemyAI.new(p_data, rng)
	return unit


func is_alive() -> bool:
	return combatant.is_alive()


## Chọn chiêu cho lượt kế tiếp và dựng ý định. Trả null nếu quái đã chết hoặc thiếu người chơi.
func plan_next_move(player: Combatant) -> IntentInfo:
	if not is_alive() or player == null:
		return null
	current_move = ai.choose_next_move()
	if current_move == null:
		return null
	intent = IntentInfo.build(current_move, combatant, player)
	return intent


## Dựng lại ý định cho chiêu ĐÃ chọn (khi Strength/Weak/Vulnerable của hai bên thay đổi).
func refresh_intent(player: Combatant) -> IntentInfo:
	if current_move == null or not is_alive() or player == null:
		return intent
	intent = IntentInfo.build(current_move, combatant, player)
	return intent
