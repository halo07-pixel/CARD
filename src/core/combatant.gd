class_name Combatant
extends RefCounted
## Người chơi hoặc quái. Chỉ phát Signal, không biết gì về UI ("signal up").
## Tạo bằng Combatant.create() (trả null nếu tham số sai).

signal health_changed(old_hp: int, new_hp: int)
signal block_changed(old_block: int, new_block: int)
signal status_changed(status_id: StringName, old_amount: int, new_amount: int)
signal died

const MAX_STATUS_AMOUNT := 999

var id: StringName = &""
var display_name: String = ""
var max_hp: int = 0
var hp: int = 0
var block: int = 0

var _amounts: Dictionary = {}      ## status_id -> int (khác 0)
var _status_data: Dictionary = {}  ## status_id -> StatusData


static func create(p_id: StringName, p_display_name: String, p_max_hp: int) -> Combatant:
	if p_id.is_empty() or p_max_hp <= 0:
		push_error("Combatant.create: id trống hoặc max_hp <= 0")
		return null
	var combatant := Combatant.new()
	combatant.id = p_id
	combatant.display_name = p_display_name
	combatant.max_hp = p_max_hp
	combatant.hp = p_max_hp
	return combatant


func is_alive() -> bool:
	return hp > 0


## Sát thương đã tính (sau Strength/Weak/Vulnerable). Giáp trừ trước, phần dư trừ máu.
func take_damage(amount: int) -> DamageResult:
	var result := DamageResult.new()
	if not is_alive() or amount < 0:
		return result
	result.accepted = true
	result.incoming = amount
	result.blocked = mini(block, amount)
	result.hp_lost = mini(hp, amount - result.blocked)
	if result.blocked > 0:
		_set_block(block - result.blocked)
	if result.hp_lost > 0:
		_set_hp(hp - result.hp_lost)
	result.killed = not is_alive() and result.hp_lost > 0
	if result.killed:
		died.emit()
	return result


## Mất máu trực tiếp, bỏ qua giáp. Trả về lượng máu thực sự mất.
func lose_hp(amount: int) -> int:
	if not is_alive() or amount <= 0:
		return 0
	var lost := mini(hp, amount)
	_set_hp(hp - lost)
	if not is_alive():
		died.emit()
	return lost


## Trả về lượng máu thực sự hồi (người đã chết không hồi được).
func heal(amount: int) -> int:
	if not is_alive() or amount <= 0:
		return 0
	var healed := mini(max_hp - hp, amount)
	if healed > 0:
		_set_hp(hp + healed)
	return healed


func gain_block(amount: int) -> int:
	if not is_alive() or amount <= 0:
		return 0
	_set_block(block + amount)
	return amount


## Đầu lượt của chính combatant này: giáp về 0.
func start_turn() -> bool:
	if not is_alive():
		return false
	_set_block(0)
	return true


## Cuối lượt của chính combatant này: trạng thái hết hạn giảm 1 (về 0 thì bị gỡ).
func end_turn() -> bool:
	if not is_alive():
		return false
	for status_id: StringName in _amounts.keys():
		if (_status_data[status_id] as StatusData).decays_at_turn_end:
			_set_status(status_id, _amounts[status_id] - 1)
	return true


## amount dương = thêm, âm = bớt (chỉ status can_be_negative mới được xuống dưới 0).
func add_status(data: StatusData, amount: int) -> bool:
	if data == null or amount == 0 or not is_alive():
		return false
	var old: int = _amounts.get(data.id, 0)
	var target := clampi(old + amount, -MAX_STATUS_AMOUNT, MAX_STATUS_AMOUNT)
	if target < 0 and not data.can_be_negative:
		if old == 0:
			return false  # không tạo mới status với giá trị âm
		target = 0
	_status_data[data.id] = data
	_set_status(data.id, target)
	return true


func remove_status(status_id: StringName) -> bool:
	if not _amounts.has(status_id):
		return false
	_set_status(status_id, 0)
	return true


func get_status(status_id: StringName) -> int:
	return _amounts.get(status_id, 0)


func has_status(status_id: StringName) -> bool:
	return _amounts.has(status_id)


func get_status_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_amounts.keys())
	return ids


## Cộng dồn "+X mỗi stack" của mọi status đang có.
func damage_dealt_add() -> float:
	return _sum_per_stack(&"damage_dealt_add_per_stack")


func block_gain_add() -> float:
	return _sum_per_stack(&"block_gain_add_per_stack")


## Nhân dồn hệ số của mọi status đang có.
func damage_dealt_mult() -> float:
	return _product(&"damage_dealt_mult")


func damage_taken_mult() -> float:
	return _product(&"damage_taken_mult")


func block_gain_mult() -> float:
	return _product(&"block_gain_mult")


func _sum_per_stack(property: StringName) -> float:
	var total := 0.0
	for status_id: StringName in _amounts:
		total += float((_status_data[status_id] as StatusData).get(property)) * _amounts[status_id]
	return total


func _product(property: StringName) -> float:
	var total := 1.0
	for status_id: StringName in _amounts:
		total *= float((_status_data[status_id] as StatusData).get(property))
	return total


func _set_hp(new_hp: int) -> void:
	var old := hp
	hp = clampi(new_hp, 0, max_hp)
	if hp != old:
		health_changed.emit(old, hp)


func _set_block(new_block: int) -> void:
	var old := block
	block = maxi(new_block, 0)
	if block != old:
		block_changed.emit(old, block)


func _set_status(status_id: StringName, new_amount: int) -> void:
	var old: int = _amounts.get(status_id, 0)
	if new_amount == 0:
		_amounts.erase(status_id)
		_status_data.erase(status_id)
	else:
		_amounts[status_id] = new_amount
	if new_amount != old:
		status_changed.emit(status_id, old, new_amount)
