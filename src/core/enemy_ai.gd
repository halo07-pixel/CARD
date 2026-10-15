class_name EnemyAI
extends RefCounted
## Chọn chiêu tiếp theo cho MỘT quái. RNG được tiêm từ ngoài nên cùng seed -> cùng chuỗi chiêu.
##  - SEQUENCE: đi theo thứ tự (vòng lặp); chiêu mở màn đặt điểm bắt đầu của vòng.
##  - WEIGHTED: bốc theo weight, không vượt max_consecutive; nếu mọi chiêu đều bị chặn thì
##    bỏ qua giới hạn (không bao giờ bị kẹt).

var _data: EnemyData
var _rng: RandomNumberGenerator
var _sequence: Array[StringName] = []
var _sequence_index: int = 0
var _opening_pending: bool = false
var _last_move_id: StringName = &""
var _streak: int = 0


func _init(data: EnemyData, rng: RandomNumberGenerator) -> void:
	_data = data
	_rng = rng
	_sequence = data.get_sequence()
	if data.opening_move_id.is_empty():
		return
	if data.pattern == EnemyData.PatternKind.SEQUENCE:
		_sequence_index = maxi(_sequence.find(data.opening_move_id), 0)
	else:
		_opening_pending = true


## Trả null nếu dữ liệu quái không có chiêu nào (đã bị validate loại trước đó).
func choose_next_move() -> EnemyMove:
	var move: EnemyMove = null
	if _opening_pending:
		_opening_pending = false
		move = _data.find_move(_data.opening_move_id)
	elif _data.pattern == EnemyData.PatternKind.SEQUENCE:
		if _sequence.is_empty():
			push_error("EnemyAI: quái '%s' không có sequence" % _data.id)
			return null
		move = _data.find_move(_sequence[_sequence_index % _sequence.size()])
		_sequence_index += 1
	else:
		move = _pick_weighted()
	if move != null:
		_record(move)
	return move


func _pick_weighted() -> EnemyMove:
	var candidates: Array[EnemyMove] = []
	for move in _data.moves:
		if not _is_blocked(move):
			candidates.append(move)
	if candidates.is_empty():
		candidates.assign(_data.moves)
	var total := 0
	for move in candidates:
		total += move.weight
	var roll := _rng.randi_range(1, total)
	for move in candidates:
		roll -= move.weight
		if roll <= 0:
			return move
	return candidates[candidates.size() - 1]


func _is_blocked(move: EnemyMove) -> bool:
	return move.max_consecutive > 0 and move.id == _last_move_id and _streak >= move.max_consecutive


func _record(move: EnemyMove) -> void:
	if move.id == _last_move_id:
		_streak += 1
	else:
		_last_move_id = move.id
		_streak = 1
