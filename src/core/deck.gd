class_name Deck
extends RefCounted
## Bốn pile: draw / hand / discard / exhaust. Không dùng node; UI chỉ lắng nghe Signal.
## "Đỉnh" draw pile là phần tử CUỐI mảng. RNG được tiêm từ ngoài để kết quả tái lập được.

signal card_drawn(card: CardInstance)
signal card_discarded(card: CardInstance)
signal card_exhausted(card: CardInstance)
signal reshuffled
signal pile_changed(pile: StringName)

const MAX_HAND_SIZE := 10
const DRAW := &"draw"
const HAND := &"hand"
const DISCARD := &"discard"
const EXHAUST := &"exhaust"
const PILES: Array[StringName] = [DRAW, HAND, DISCARD, EXHAUST]

var _draw_pile: Array[CardInstance] = []
var _hand: Array[CardInstance] = []
var _discard_pile: Array[CardInstance] = []
var _exhaust_pile: Array[CardInstance] = []
var _rng: RandomNumberGenerator
var _battle_started: bool = false


func _init(cards: Array[CardInstance], rng: RandomNumberGenerator = null) -> void:
	for card in cards:
		if card == null or _draw_pile.has(card):
			push_warning("Deck: bỏ qua thẻ null hoặc trùng instance")
			continue
		_draw_pile.append(card)
	if rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	else:
		_rng = rng


func is_battle_started() -> bool:
	return _battle_started


## Xáo draw pile và đưa thẻ innate lên đỉnh. Chỉ gọi được một lần, khi mọi thẻ còn trong draw pile.
func start_battle() -> bool:
	if _battle_started or not (_hand.is_empty() and _discard_pile.is_empty() and _exhaust_pile.is_empty()):
		push_warning("Deck.start_battle: trận đã bắt đầu")
		return false
	_battle_started = true
	_shuffle(_draw_pile)
	var regular: Array[CardInstance] = []
	var innate: Array[CardInstance] = []
	for card in _draw_pile:
		if card.data.innate:
			innate.append(card)
		else:
			regular.append(card)
	_draw_pile.clear()
	_draw_pile.append_array(regular)
	_draw_pile.append_array(innate)
	pile_changed.emit(DRAW)
	return true


## Trả về các thẻ thực sự vào tay. Thẻ rút dư khi tay đầy bị bỏ thẳng vào discard.
func draw(count: int) -> Array[CardInstance]:
	var drawn: Array[CardInstance] = []
	if not _battle_started:
		push_warning("Deck.draw: gọi trước start_battle")
		return drawn
	for i in maxi(count, 0):
		if _draw_pile.is_empty() and not _reshuffle_discard():
			break
		var card: CardInstance = _draw_pile.pop_back()
		if _hand.size() >= MAX_HAND_SIZE:
			_discard_pile.append(card)
			card_discarded.emit(card)
			_emit_changed(DRAW, DISCARD)
		else:
			_hand.append(card)
			drawn.append(card)
			card_drawn.emit(card)
			_emit_changed(DRAW, HAND)
	return drawn


## Thẻ phải đang ở tay. Thẻ exhaust vào exhaust pile, còn lại vào discard.
func play_card(card: CardInstance) -> bool:
	if card == null:
		return false
	return _move_from_hand(card, EXHAUST if card.data.exhaust else DISCARD)


func discard_card(card: CardInstance) -> bool:
	return _move_from_hand(card, DISCARD)


func exhaust_card(card: CardInstance) -> bool:
	return _move_from_hand(card, EXHAUST)


## Cuối lượt: retain ở lại tay (ưu tiên cao nhất), ethereal bị exhaust, còn lại discard.
func end_turn_discard() -> void:
	if not _battle_started:
		return
	for card: CardInstance in _hand.duplicate():
		if card.data.retain:
			continue
		_move_from_hand(card, EXHAUST if card.data.ethereal else DISCARD)


## Trả về false nếu thẻ null/đã có trong deck. Tay đầy thì thẻ vào discard (vẫn tính là đã nhận).
func add_to_hand(card: CardInstance) -> bool:
	if not _can_add(card):
		return false
	if _hand.size() >= MAX_HAND_SIZE:
		_discard_pile.append(card)
		card_discarded.emit(card)
		pile_changed.emit(DISCARD)
	else:
		_hand.append(card)
		card_drawn.emit(card)
		pile_changed.emit(HAND)
	return true


func add_to_discard(card: CardInstance) -> bool:
	if not _can_add(card):
		return false
	_discard_pile.append(card)
	pile_changed.emit(DISCARD)
	return true


## on_top = true: đặt lên đỉnh; ngược lại chèn vào vị trí ngẫu nhiên.
func add_to_draw_pile(card: CardInstance, on_top: bool = false) -> bool:
	if not _can_add(card):
		return false
	if on_top:
		_draw_pile.append(card)
	else:
		_draw_pile.insert(_rng.randi_range(0, _draw_pile.size()), card)
	pile_changed.emit(DRAW)
	return true


## Bản sao (không phải tham chiếu) để bên ngoài không sửa được pile.
func get_pile(pile_name: StringName) -> Array[CardInstance]:
	var copy: Array[CardInstance] = []
	if PILES.has(pile_name):
		copy.assign(_pile(pile_name))
	else:
		push_error("Deck: pile không tồn tại: %s" % pile_name)
	return copy


func count(pile_name: StringName) -> int:
	return _pile(pile_name).size() if PILES.has(pile_name) else 0


func total_count() -> int:
	return _draw_pile.size() + _hand.size() + _discard_pile.size() + _exhaust_pile.size()


## Tên pile chứa thẻ, hoặc &"" nếu thẻ không thuộc deck.
func find_pile(card: CardInstance) -> StringName:
	for pile_name in PILES:
		if _pile(pile_name).has(card):
			return pile_name
	return &""


func contains(card: CardInstance) -> bool:
	return card != null and find_pile(card) != &""


func _pile(pile_name: StringName) -> Array[CardInstance]:
	match pile_name:
		HAND:
			return _hand
		DISCARD:
			return _discard_pile
		EXHAUST:
			return _exhaust_pile
		_:
			return _draw_pile


func _can_add(card: CardInstance) -> bool:
	if card == null or contains(card):
		push_warning("Deck: không thể thêm thẻ null hoặc đã có trong deck")
		return false
	return true


func _move_from_hand(card: CardInstance, destination: StringName) -> bool:
	var index := _hand.find(card)
	if index == -1:
		push_warning("Deck: thẻ không ở trong tay, từ chối thao tác")
		return false
	_hand.remove_at(index)
	if destination == EXHAUST:
		_exhaust_pile.append(card)
		card_exhausted.emit(card)
	else:
		_discard_pile.append(card)
		card_discarded.emit(card)
	_emit_changed(HAND, destination)
	return true


func _reshuffle_discard() -> bool:
	if _discard_pile.is_empty():
		return false
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	_shuffle(_draw_pile)
	reshuffled.emit()
	_emit_changed(DISCARD, DRAW)
	return true


func _emit_changed(first: StringName, second: StringName) -> void:
	pile_changed.emit(first)
	pile_changed.emit(second)


## Fisher-Yates dùng RNG được tiêm (Array.shuffle() dùng RNG toàn cục nên không tái lập được).
func _shuffle(cards: Array[CardInstance]) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp := cards[i]
		cards[i] = cards[j]
		cards[j] = temp
