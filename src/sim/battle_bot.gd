@abstract
class_name BattleBot
extends RefCounted
## Một "người chơi" tự động. act() thực hiện ĐÚNG MỘT hành động hợp lệ trên controller
## (chơi một thẻ hoặc kết thúc lượt). Bot chỉ dùng API công khai của BattleController.

@abstract func act(controller: BattleController) -> void


## Các thẻ đang ở tay mà controller cho phép chơi ngay.
func _playable_cards(controller: BattleController) -> Array[CardInstance]:
	var playable: Array[CardInstance] = []
	for card in controller.deck.get_pile(Deck.HAND):
		if controller.can_play(card):
			playable.append(card)
	return playable
