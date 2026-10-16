class_name RandomBot
extends BattleBot
## Chơi ngẫu nhiên: thẻ hợp lệ bất kỳ, mục tiêu bất kỳ, thỉnh thoảng kết thúc lượt sớm.
## Dùng để tìm lỗi (đi vào các tình huống mà người chơi thật hiếm khi tạo ra).

const END_TURN_CHANCE := 0.2

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func act(controller: BattleController) -> void:
	var playable := _playable_cards(controller)
	if playable.is_empty() or _rng.randf() < END_TURN_CHANCE:
		controller.end_player_turn()
		return
	var card := playable[_rng.randi_range(0, playable.size() - 1)]
	var targets := controller.valid_targets(card)
	var target: EnemyUnit = null
	if not targets.is_empty():
		target = targets[_rng.randi_range(0, targets.size() - 1)]
	controller.play_card(card, target)
