class_name TriggerDispatcher
extends RefCounted
## Quyết định trigger nào nổ khi có một sự kiện, và giữ các bộ đếm (every_n, max_per_turn,
## max_per_battle). Không thực thi effect: chỉ trả về danh sách QueuedAction theo THỨ TỰ CỐ ĐỊNH
## (thứ tự của `sources`, rồi thứ tự trigger, rồi thứ tự effect).

var _occurrences: Dictionary = {}   ## khóa trigger -> số lần xảy ra thỏa điều kiện (cho every_n)
var _fired_battle: Dictionary = {}  ## khóa trigger -> số lần đã nổ trong trận
var _fired_turn: Dictionary = {}    ## khóa trigger -> số lần đã nổ trong lượt này


## Gọi ở đầu mỗi vòng (lượt người chơi mới): xóa bộ đếm theo lượt.
func new_turn() -> void:
	_fired_turn.clear()


func actions_for(event: BattleEvent, sources: Array[TriggerSource]) -> Array[QueuedAction]:
	var actions: Array[QueuedAction] = []
	for source in sources:
		if event.subject != null and source.owner != event.subject:
			continue
		if not source.owner.is_alive():
			continue
		for index in source.triggers.size():
			var trigger := source.triggers[index]
			if trigger.event != event.type or not _conditions_met(trigger, event, source):
				continue
			if trigger.scale_by_stacks and source.stacks < 1:
				continue
			if not _count_and_allow(trigger, _key(source, index)):
				continue
			for effect in trigger.effects:
				var final_effect := effect.scaled(source.stacks) if trigger.scale_by_stacks else effect
				actions.append(QueuedAction.create(final_effect, source.owner, event.source, source.key))
	return actions


func _conditions_met(trigger: TriggerData, event: BattleEvent, source: TriggerSource) -> bool:
	if trigger.filter_card_type and (event.card == null or event.card.data.card_type != trigger.card_type):
		return false
	if trigger.requires_zero_block and source.owner.block > 0:
		return false
	return true


## every_n đếm các lần xảy ra thỏa điều kiện; max_per_* đếm các lần ĐÃ nổ.
func _count_and_allow(trigger: TriggerData, key: String) -> bool:
	if trigger.every_n > 0:
		var seen: int = _occurrences.get(key, 0) + 1
		_occurrences[key] = seen
		if seen % trigger.every_n != 0:
			return false
	if trigger.max_per_battle > 0 and _fired_battle.get(key, 0) >= trigger.max_per_battle:
		return false
	if trigger.max_per_turn > 0 and _fired_turn.get(key, 0) >= trigger.max_per_turn:
		return false
	_fired_battle[key] = _fired_battle.get(key, 0) + 1
	_fired_turn[key] = _fired_turn.get(key, 0) + 1
	return true


func _key(source: TriggerSource, index: int) -> String:
	return "%d|%s|%d" % [source.owner.get_instance_id(), source.key, index]
