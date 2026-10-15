extends "res://tests/test_case.gd"

const Factory := preload("res://tests/card_factory.gd")


func _started(cards: Array[CardInstance], seed_value: int = 1) -> Deck:
	var deck := Deck.new(cards, Factory.rng(seed_value))
	deck.start_battle()
	return deck


func test_begin_play_moves_card_from_hand_to_limbo() -> void:
	var deck := _started(Factory.instances(5))
	var card := deck.draw(3)[0]
	assert_true(deck.begin_play(card))
	assert_eq(deck.find_pile(card), Deck.LIMBO)
	assert_eq(deck.count(Deck.HAND), 2)
	assert_eq(deck.count(Deck.LIMBO), 1)
	assert_eq(deck.total_count(), 5, "limbo vẫn được tính vào tổng số thẻ")


func test_finish_play_moves_to_discard_or_exhaust() -> void:
	var normal := Factory.instance(&"normal")
	var burn := Factory.instance(&"burn", {"exhaust": true})
	var deck := _started([normal, burn] as Array[CardInstance])
	deck.draw(2)
	deck.begin_play(normal)
	deck.begin_play(burn)
	assert_true(deck.finish_play(normal))
	assert_true(deck.finish_play(burn))
	assert_eq(deck.find_pile(normal), Deck.DISCARD)
	assert_eq(deck.find_pile(burn), Deck.EXHAUST)
	assert_eq(deck.count(Deck.LIMBO), 0)


func test_begin_and_finish_reject_wrong_locations_without_side_effects() -> void:
	var deck := _started(Factory.instances(5))
	var in_draw := deck.get_pile(Deck.DRAW)[0]
	assert_false(deck.begin_play(in_draw), "thẻ ở draw pile không chơi được")
	assert_false(deck.begin_play(null))
	assert_false(deck.finish_play(in_draw), "thẻ chưa ở limbo")
	assert_false(deck.finish_play(null))
	var card := deck.draw(1)[0]
	assert_false(deck.finish_play(card), "thẻ còn ở tay, chưa begin_play")
	deck.begin_play(card)
	assert_false(deck.begin_play(card), "đã ở limbo, không begin_play lần hai")
	assert_eq(deck.total_count(), 5)


func test_play_card_still_works_as_one_step() -> void:
	var deck := _started(Factory.instances(5))
	var card := deck.draw(1)[0]
	assert_true(deck.play_card(card))
	assert_eq(deck.find_pile(card), Deck.DISCARD)
	assert_false(deck.play_card(card), "đã ở discard")


func test_card_in_limbo_is_never_redrawn_even_after_a_reshuffle() -> void:
	# draw pile rỗng, discard có 2 thẻ; chơi thẻ "rút bài" trong lúc nó ở limbo.
	var cards := Factory.instances(5)
	var deck := _started(cards)
	var hand := deck.draw(5)
	deck.play_card(hand[0])
	deck.play_card(hand[1])
	var playing := hand[2]
	deck.begin_play(playing)
	var drawn := deck.draw(5)  # kích hoạt xáo lại discard (2 thẻ)
	assert_eq(drawn.size(), 2, "chỉ có 2 thẻ trong discard để xáo lại")
	assert_false(drawn.has(playing), "thẻ đang chơi không được rút lại")
	deck.finish_play(playing)
	assert_eq(deck.find_pile(playing), Deck.DISCARD)
	assert_eq(deck.total_count(), 5)


func test_begin_play_frees_a_hand_slot() -> void:
	var deck := _started(Factory.instances(12))
	var hand := deck.draw(10)
	assert_eq(deck.count(Deck.HAND), Deck.MAX_HAND_SIZE)
	deck.begin_play(hand[0])
	assert_eq(deck.draw(1).size(), 1, "tay còn chỗ trống sau khi thẻ rời tay")


func test_start_battle_requires_empty_limbo() -> void:
	var deck := Deck.new(Factory.instances(3), Factory.rng())
	assert_true(deck.start_battle())
	assert_false(deck.start_battle())
