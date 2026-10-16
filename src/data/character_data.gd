class_name CharacterData
extends Resource
## Định nghĩa một nhân vật chơi được (dữ liệu thuần): chỉ số khởi đầu + bộ bài khởi đầu (theo id thẻ).

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 80
@export var max_energy: int = 3
@export var draw_per_turn: int = 5
@export var starting_gold: int = 99
@export var starting_deck: Array[StringName] = []
@export var icon_id: StringName = &""


## Cấu hình trận đấu theo nhân vật (turn_cap do nơi gọi đặt nếu cần).
func make_battle_config() -> BattleConfig:
	var config := BattleConfig.new()
	config.max_energy = max_energy
	config.draw_per_turn = draw_per_turn
	return config


## Trả về danh sách lỗi (rỗng = hợp lệ). Việc id thẻ có tồn tại hay không do CardRegistry kiểm tra.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("id trống")
	if display_name.strip_edges().is_empty():
		errors.append("display_name trống")
	if max_hp <= 0:
		errors.append("max_hp phải > 0 (hiện %d)" % max_hp)
	if max_energy < 1:
		errors.append("max_energy phải >= 1 (hiện %d)" % max_energy)
	if draw_per_turn < 1:
		errors.append("draw_per_turn phải >= 1 (hiện %d)" % draw_per_turn)
	if starting_gold < 0:
		errors.append("starting_gold không được âm (hiện %d)" % starting_gold)
	if starting_deck.is_empty():
		errors.append("bộ bài khởi đầu rỗng")
	for card_id in starting_deck:
		if card_id.is_empty():
			errors.append("starting_deck chứa id trống")
			break
	return errors
