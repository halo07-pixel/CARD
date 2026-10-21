class_name QueuedAction
extends RefCounted
## Một hiệu ứng do trigger sinh ra, chờ trong ActionQueue. effect đã được nhân stack (nếu có).

var effect: EffectData = null
var owner: Combatant = null         ## bên thực hiện (chủ sở hữu trigger)
var event_source: Combatant = null  ## kẻ gây sự kiện: đích của effect nhắm EVENT_SOURCE
var key: StringName = &""           ## nguồn trigger, để UI hiển thị


static func create(p_effect: EffectData, p_owner: Combatant, p_event_source: Combatant,
		p_key: StringName) -> QueuedAction:
	var action := QueuedAction.new()
	action.effect = p_effect
	action.owner = p_owner
	action.event_source = p_event_source
	action.key = p_key
	return action
