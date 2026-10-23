class_name TriggerSource
extends RefCounted
## Một "nguồn trigger" tại thời điểm có sự kiện: chủ sở hữu + danh sách trigger + số stack hiện có.
## Được dựng MỚI mỗi lần từ status đang có (không lưu đăng ký) nên gỡ status là hết hiệu lực ngay.

var key: StringName = &""   ## định danh ổn định, ví dụ &"status:poison"
var owner: Combatant = null
var triggers: Array[TriggerData] = []
var stacks: int = 1


static func create(p_key: StringName, p_owner: Combatant, p_triggers: Array[TriggerData],
		p_stacks: int = 1) -> TriggerSource:
	var source := TriggerSource.new()
	source.key = p_key
	source.owner = p_owner
	source.triggers = p_triggers
	source.stacks = p_stacks
	return source


## Mỗi relic có trigger là một nguồn (stacks = 1), theo thứ tự nhặt.
static func from_relics(owner: Combatant, relics: Array[RelicData]) -> Array[TriggerSource]:
	var sources: Array[TriggerSource] = []
	if not owner.is_alive():
		return sources
	for relic in relics:
		if not relic.triggers.is_empty():
			sources.append(TriggerSource.create(StringName("relic:%s" % relic.id), owner, relic.triggers, 1))
	return sources


## Mọi status ĐANG CÓ trên combatant mà có trigger, theo thứ tự áp dụng lần đầu.
static func from_statuses(combatant: Combatant) -> Array[TriggerSource]:
	var sources: Array[TriggerSource] = []
	if not combatant.is_alive():
		return sources
	for status_id in combatant.get_status_ids():
		var data := combatant.get_status_data(status_id)
		if data != null and not data.triggers.is_empty():
			sources.append(TriggerSource.create(StringName("status:%s" % status_id), combatant,
					data.triggers, combatant.get_status(status_id)))
	return sources
