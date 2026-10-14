extends "res://tests/test_case.gd"

const Factory := preload("res://tests/card_factory.gd")


func _started_deck(n: int, seed_value: int = 1) -> Deck:
	var deck := Deck.new(Factory.instances(n), Factory.rng(seed_value))
	deck.start_battle()
	return deck


func test_new_deck_keeps_all_cards_in_draw_pile() -> void:
	var deck := Deck.new(Factory.instances(10), Factory.rng())
	assert_eq(deck.count(Deck.DRAW), 10)
	assert_eq(deck.total_count(), 10)
	assert_false(deck.is_battle_started())


func test_constructor_copies_input_and_skips_duplicates() -> void:
	var cards := Factory.instances(3)
	cards.append(cards[0])  # trùng instance
	var deck := Deck.new(cards, Factory.rng())
	assert_eq(deck.total_count(), 3)
	cards.clear()
	assert_eq(deck.total_count(), 3, "xóa mảng gốc không được ảnh hưởng Deck")


func test_draw_before_start_is_rejected() -> void:
	var deck := Deck.new(Factory.instances(5), Factory.rng())
	assert_eq(deck.draw(3).size(), 0)
	assert_eq(deck.count(Deck.HAND), 0)


func test_start_battle_only_once() -> void:
	var deck := Deck.new(Factory.instances(5), Factory.rng())
	assert_true(deck.start_battle())
	assert_false(deck.start_battle())


func test_draw_moves_cards_to_hand() -> void:
	var deck := _started_deck(10)
	var drawn := deck.draw(5)
	assert_eq(drawn.size(), 5)
	assert_eq(deck.count(Deck.HAND), 5)
	assert_eq(deck.count(Deck.DRAW), 5)


func test_draw_zero_or_negative_does_nothing() -> void:
	var deck := _started_deck(5)
	assert_eq(deck.draw(0).size(), 0)
	assert_eq(deck.draw(-3).size(), 0)
	assert_eq(deck.count(Deck.HAND), 0)


func test_draw_stops_when_all_piles_empty() -> void:
	var deck := _started_deck(3)
	assert_eq(deck.draw(10).size(), 3)
	assert_eq(deck.count(Deck.HAND), 3)
	assert_eq(deck.draw(1).size(), 0)


func test_reshuffles_discard_when_draw_pile_empty() -> void:
	var deck := _started_deck(5)
	var reshuffles := [0]
	deck.reshuffled.connect(func() -> void: reshuffles[0] += 1)
	var hand := deck.draw(5)
	for i in 3:
		deck.discard_card(hand[i])
	var drawn := deck.draw(2)
	assert_eq(drawn.size(), 2)
	assert_eq(reshuffles[0], 1)
	assert_eq(deck.count(Deck.DISCARD), 0, "discard đã được chuyển hết vào draw pile")
	assert_eq(deck.count(Deck.DRAW), 1, "3 thẻ xáo lại, rút 2 còn 1")
	assert_eq(deck.count(Deck.HAND), 4, "2 thẻ cũ còn trên tay + 2 thẻ mới rút")
	assert_eq(deck.total_count(), 5)


func test_hand_limit_overflow_goes_to_discard() -> void:
	var deck := _started_deck(12)
	var drawn := deck.draw(12)
	assert_eq(drawn.size(), Deck.MAX_HAND_SIZE)
	assert_eq(deck.count(Deck.HAND), Deck.MAX_HAND_SIZE)
	assert_eq(deck.count(Deck.DISCARD), 2)
	assert_eq(deck.total_count(), 12, "không được mất thẻ nào")


func test_same_seed_gives_same_draw_order() -> void:
	var first := Factory.ids(_started_deck(20, 42).draw(10))
	var second := Factory.ids(_started_deck(20, 42).draw(10))
	assert_eq(first, second)


func test_different_seed_gives_different_order() -> void:
	var first := Factory.ids(_started_deck(20, 1).draw(10))
	var second := Factory.ids(_started_deck(20, 2).draw(10))
	assert_ne(first, second)


func test_play_card_requires_card_in_hand() -> void:
	var deck := _started_deck(5)
	var in_draw_pile := deck.get_pile(Deck.DRAW)[0]
	assert_false(deck.play_card(in_draw_pile))
	assert_false(deck.play_card(null))
	assert_false(deck.play_card(Factory.instance(&"stranger")))
	assert_eq(deck.total_count(), 5)


func test_play_card_goes_to_discard_and_cannot_be_replayed() -> void:
	var deck := _started_deck(5)
	var card := deck.draw(1)[0]
	assert_true(deck.play_card(card))
	assert_eq(deck.find_pile(card), Deck.DISCARD)
	assert_false(deck.play_card(card), "đã ở discard, không chơi lại được")


func test_exhaust_card_goes_to_exhaust_pile() -> void:
	var cards: Array[CardInstance] = [Factory.instance(&"burn", {"exhaust": true})]
	var deck := Deck.new(cards, Factory.rng())
	deck.start_battle()
	var card := deck.draw(1)[0]
	assert_true(deck.play_card(card))
	assert_eq(deck.find_pile(card), Deck.EXHAUST)


func test_end_turn_discard_handles_retain_and_ethereal() -> void:
	var normal := Factory.instance(&"normal")
	var kept := Factory.instance(&"kept", {"retain": true})
	var ghost := Factory.instance(&"ghost", {"ethereal": true})
	var deck := Deck.new([normal, kept, ghost] as Array[CardInstance], Factory.rng())
	deck.start_battle()
	deck.draw(3)
	deck.end_turn_discard()
	assert_eq(deck.find_pile(normal), Deck.DISCARD)
	assert_eq(deck.find_pile(kept), Deck.HAND)
	assert_eq(deck.find_pile(ghost), Deck.EXHAUST)


func test_retain_takes_precedence_over_ethereal() -> void:
	var both := Factory.instance(&"both", {"retain": true, "ethereal": true})
	var deck := Deck.new([both] as Array[CardInstance], Factory.rng())
	deck.start_battle()
	deck.draw(1)
	deck.end_turn_discard()
	assert_eq(deck.find_pile(both), Deck.HAND)


func test_innate_cards_are_drawn_first() -> void:
	for seed_value in 10:
		var cards := Factory.instances(15)
		var innate_a := Factory.instance(&"innate_a", {"innate": true})
		var innate_b := Factory.instance(&"innate_b", {"innate": true})
		cards.append(innate_a)
		cards.append(innate_b)
		var deck := Deck.new(cards, Factory.rng(seed_value))
		deck.start_battle()
		var first_two := deck.draw(2)
		assert_true(first_two.has(innate_a) and first_two.has(innate_b), "seed %d" % seed_value)


func test_add_to_hand_respects_limit() -> void:
	var deck := _started_deck(10)
	deck.draw(10)
	var extra := Factory.instance(&"extra")
	assert_true(deck.add_to_hand(extra))
	assert_eq(deck.find_pile(extra), Deck.DISCARD)
	assert_eq(deck.count(Deck.HAND), Deck.MAX_HAND_SIZE)


func test_add_rejects_null_and_duplicates() -> void:
	var deck := _started_deck(3)
	var card := deck.get_pile(Deck.DRAW)[0]
	assert_false(deck.add_to_hand(null))
	assert_false(deck.add_to_discard(card), "instance đã có trong deck")
	var fresh := Factory.instance(&"fresh")
	assert_true(deck.add_to_discard(fresh))
	assert_false(deck.add_to_draw_pile(fresh), "không thêm được lần hai")
	assert_eq(deck.total_count(), 4)


func test_add_to_draw_pile_on_top_is_drawn_next() -> void:
	var deck := _started_deck(5)
	var top := Factory.instance(&"top")
	assert_true(deck.add_to_draw_pile(top, true))
	assert_eq(deck.draw(1)[0], top)


func test_add_to_draw_pile_random_position_keeps_card() -> void:
	var deck := _started_deck(5)
	var card := Factory.instance(&"random_spot")
	assert_true(deck.add_to_draw_pile(card))
	assert_eq(deck.find_pile(card), Deck.DRAW)
	assert_eq(deck.count(Deck.DRAW), 6)


func test_get_pile_returns_copy() -> void:
	var deck := _started_deck(5)
	var copy := deck.get_pile(Deck.DRAW)
	copy.clear()
	assert_eq(deck.count(Deck.DRAW), 5)
	assert_eq(deck.get_pile(&"no_such_pile").size(), 0)
	assert_eq(deck.count(&"no_such_pile"), 0)


func test_signals_fire_for_draw_play_and_exhaust() -> void:
	var deck := _started_deck(4)
	var log: Array = []
	deck.card_drawn.connect(func(c: CardInstance) -> void: log.append("drawn"))
	deck.card_discarded.connect(func(c: CardInstance) -> void: log.append("discarded"))
	deck.card_exhausted.connect(func(c: CardInstance) -> void: log.append("exhausted"))
	var changed: Array = []
	deck.pile_changed.connect(func(p: StringName) -> void: changed.append(p))
	var hand := deck.draw(2)
	deck.play_card(hand[0])
	deck.exhaust_card(hand[1])
	assert_eq(log, ["drawn", "drawn", "discarded", "exhausted"])
	assert_true(changed.has(Deck.HAND) and changed.has(Deck.DISCARD) and changed.has(Deck.EXHAUST))


func test_rejected_actions_emit_no_signals() -> void:
	var deck := _started_deck(3)
	var emitted := [0]
	deck.card_discarded.connect(func(c: CardInstance) -> void: emitted[0] += 1)
	deck.pile_changed.connect(func(p: StringName) -> void: emitted[0] += 1)
	deck.play_card(deck.get_pile(Deck.DRAW)[0])
	assert_eq(emitted[0], 0)


func test_random_operations_never_lose_or_duplicate_cards() -> void:
	var ops := Factory.rng(777)
	var deck := _started_deck(25, 5)
	var expected_total := 25
	for step in 600:
		match ops.randi_range(0, 6):
			0:
				deck.draw(ops.randi_range(0, 7))
			1:
				var hand := deck.get_pile(Deck.HAND)
				if not hand.is_empty():
					deck.play_card(hand[ops.randi_range(0, hand.size() - 1)])
			2:
				var hand := deck.get_pile(Deck.HAND)
				if not hand.is_empty():
					deck.exhaust_card(hand[ops.randi_range(0, hand.size() - 1)])
			3:
				deck.end_turn_discard()
			4:
				if deck.add_to_hand(Factory.instance(&"gen")):
					expected_total += 1
			5:
				if deck.add_to_draw_pile(Factory.instance(&"gen")):
					expected_total += 1
			6:
				var hand := deck.get_pile(Deck.HAND)
				if not hand.is_empty():
					deck.discard_card(hand[0])
		assert_eq(deck.total_count(), expected_total, "bước %d" % step)
		assert_true(deck.count(Deck.HAND) <= Deck.MAX_HAND_SIZE, "tay vượt giới hạn ở bước %d" % step)
		var seen: Dictionary = {}
		for pile_name in Deck.PILES:
			for card in deck.get_pile(pile_name):
				assert_false(seen.has(card.uid), "thẻ xuất hiện ở 2 nơi, bước %d" % step)
				seen[card.uid] = true
		if not failures.is_empty():
			return
