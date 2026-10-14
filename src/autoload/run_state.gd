extends Node
## Dữ liệu của run hiện tại (chỉ lưu ID, không giữ Resource -> tách khỏi Card Data/UI).
## Mọi thay đổi đi qua hàm có kiểm tra; serialize qua to_dict()/from_dict().

const SAVE_KEYS := [
	"character_id", "seed_value", "rng_state", "act", "floor_index",
	"max_hp", "hp", "gold", "deck", "relics", "potions",
]

var is_active: bool = false
var character_id: String = ""
var seed_value: int = 0
var act: int = 1
var floor_index: int = 0
var max_hp: int = 0
var hp: int = 0
var gold: int = 0
var deck: Array[String] = []
var relics: Array[String] = []
var potions: Array[String] = []
var rng := RandomNumberGenerator.new()


func start_new_run(p_character_id: String, p_max_hp: int, starting_deck: Array[String],
		starting_gold: int = 99, p_seed: int = 0) -> bool:
	if p_character_id.is_empty() or p_max_hp <= 0 or starting_deck.is_empty():
		push_error("RunState: tham số run không hợp lệ")
		return false
	_reset()
	is_active = true
	character_id = p_character_id
	max_hp = p_max_hp
	hp = p_max_hp
	gold = maxi(starting_gold, 0)
	deck = starting_deck.duplicate()
	seed_value = p_seed if p_seed != 0 else int(Time.get_ticks_usec()) ^ randi()
	rng.seed = seed_value
	EventBus.run_started.emit(character_id)
	return true


func end_run(victory: bool) -> bool:
	if not is_active:
		push_warning("RunState: end_run khi không có run đang chạy")
		return false
	is_active = false
	SaveSystem.delete_run()
	EventBus.run_ended.emit(victory)
	return true


func change_hp(delta: int) -> bool:
	if not is_active:
		return false
	hp = clampi(hp + delta, 0, max_hp)
	return true


func change_gold(delta: int) -> bool:
	if not is_active or gold + delta < 0:
		return false
	gold += delta
	return true


func add_card(card_id: String) -> bool:
	if not is_active or card_id.is_empty():
		return false
	deck.append(card_id)
	return true


func remove_card(card_id: String) -> bool:
	if not is_active:
		return false
	var index := deck.find(card_id)
	if index == -1:
		return false
	deck.remove_at(index)
	return true


func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"seed_value": str(seed_value),  # chuỗi: JSON float làm mất độ chính xác int64
		"rng_state": str(rng.state),
		"act": act,
		"floor_index": floor_index,
		"max_hp": max_hp,
		"hp": hp,
		"gold": gold,
		"deck": deck.duplicate(),
		"relics": relics.duplicate(),
		"potions": potions.duplicate(),
	}


## Kiểm tra TOÀN BỘ dữ liệu trước, chỉ gán khi hợp lệ (không để state nửa vời).
func from_dict(data: Dictionary) -> bool:
	if not _is_valid_save(data):
		push_warning("RunState: dữ liệu save không hợp lệ")
		return false
	_reset()
	is_active = true
	character_id = data["character_id"]
	seed_value = String(data["seed_value"]).to_int()
	rng.seed = seed_value
	rng.state = String(data["rng_state"]).to_int()
	act = int(data["act"])
	floor_index = int(data["floor_index"])
	max_hp = int(data["max_hp"])
	hp = int(data["hp"])
	gold = int(data["gold"])
	deck = _to_string_array(data["deck"])
	relics = _to_string_array(data["relics"])
	potions = _to_string_array(data["potions"])
	return true


func save_to_disk() -> bool:
	if not is_active:
		return false
	return SaveSystem.save_run(to_dict())


func load_from_disk() -> bool:
	var data := SaveSystem.load_run()
	if data.is_empty():
		return false
	return from_dict(data)


func _reset() -> void:
	is_active = false
	character_id = ""
	seed_value = 0
	act = 1
	floor_index = 0
	max_hp = 0
	hp = 0
	gold = 0
	deck = []
	relics = []
	potions = []
	rng = RandomNumberGenerator.new()


func _is_valid_save(data: Dictionary) -> bool:
	for key: String in SAVE_KEYS:
		if not data.has(key):
			return false
	for key: String in ["act", "floor_index", "max_hp", "hp", "gold"]:
		if typeof(data[key]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	for key: String in ["deck", "relics", "potions"]:
		if typeof(data[key]) != TYPE_ARRAY:
			return false
		for item: Variant in data[key]:
			if typeof(item) != TYPE_STRING:
				return false
	if typeof(data["character_id"]) != TYPE_STRING or String(data["character_id"]).is_empty():
		return false
	for key: String in ["seed_value", "rng_state"]:
		if typeof(data[key]) != TYPE_STRING or not String(data[key]).is_valid_int():
			return false
	return int(data["max_hp"]) > 0 and int(data["hp"]) >= 0 and int(data["hp"]) <= int(data["max_hp"]) \
			and not (data["deck"] as Array).is_empty()


func _to_string_array(source: Array) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in source:
		result.append(String(item))
	return result
