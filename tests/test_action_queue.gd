extends "res://tests/test_case.gd"

const Factory := preload("res://tests/combat_factory.gd")


func _action(label: StringName) -> QueuedAction:
	return QueuedAction.create(EffectData.create(EffectData.Type.BLOCK, 1, EffectData.Target.SELF),
			Factory.combatant(), null, label)


func test_is_first_in_first_out() -> void:
	var queue := ActionQueue.new()
	for label in [&"a", &"b", &"c"]:
		queue.push(_action(label))
	assert_eq(queue.size(), 3)
	var order: Array = []
	while not queue.is_empty():
		order.append(queue.pop().key)
	assert_eq(order, [&"a", &"b", &"c"])


func test_new_actions_pushed_while_draining_go_to_the_back() -> void:
	var queue := ActionQueue.new()
	queue.push(_action(&"first"))
	queue.push(_action(&"second"))
	var order: Array = []
	while not queue.is_empty():
		var action := queue.pop()
		order.append(action.key)
		if action.key == &"first":
			queue.push(_action(&"spawned"))
	assert_eq(order, [&"first", &"second", &"spawned"])


func test_pop_on_empty_returns_null_and_clear_empties() -> void:
	var queue := ActionQueue.new()
	assert_true(queue.pop() == null)
	queue.push(_action(&"x"))
	queue.clear()
	assert_true(queue.is_empty())
	assert_eq(queue.size(), 0)
