extends "res://tests/test_case.gd"

const Factory := preload("res://tests/card_factory.gd")


func test_create_rejects_null_data() -> void:
	assert_true(CardInstance.create(null) == null)


func test_each_instance_has_unique_uid() -> void:
	var a := Factory.instance(&"strike")
	var b := Factory.instance(&"strike")
	assert_ne(a.uid, b.uid)
	assert_true(a.data.id == b.data.id)


func test_cost_override_does_not_touch_card_data() -> void:
	var card := Factory.instance(&"a", {"cost": 2})
	assert_eq(card.get_cost(), 2)
	card.set_cost_override(0)
	assert_eq(card.get_cost(), 0)
	assert_eq(card.data.cost, 2, "CardData gốc không được đổi")
	card.clear_cost_override()
	assert_eq(card.get_cost(), 2)


func test_negative_override_is_clamped_to_zero() -> void:
	var card := Factory.instance(&"a")
	card.set_cost_override(-5)
	assert_eq(card.get_cost(), 0)


func test_playable_depends_on_energy() -> void:
	var card := Factory.instance(&"a", {"cost": 2})
	assert_false(card.is_playable(1))
	assert_true(card.is_playable(2))


func test_x_cost_is_always_playable() -> void:
	var card := Factory.instance(&"x", {"is_x_cost": true, "cost": 0})
	assert_true(card.is_playable(0))


func test_unplayable_card_never_playable() -> void:
	var card := Factory.instance(&"curse", {"unplayable": true, "cost": 0})
	assert_false(card.is_playable(99))
