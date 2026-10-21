class_name BattleEvent
extends RefCounted
## Một sự kiện trong trận. subject = bên mà sự kiện "xảy ra với" (trigger của status/relic chỉ nổ
## khi chủ sở hữu là subject; null với BATTLE_START/BATTLE_VICTORY = mọi chủ sở hữu đều nghe).

var type: TriggerData.Event = TriggerData.Event.BATTLE_START
var subject: Combatant = null
var source: Combatant = null   ## bên gây ra (kẻ tấn công...), có thể null
var card: CardInstance = null  ## chỉ có với CARD_PLAYED
var amount: int = 0            ## sát thương gốc (ATTACKED) hoặc máu đã mất (HP_LOST)


static func create(p_type: TriggerData.Event, p_subject: Combatant = null, p_source: Combatant = null,
		p_amount: int = 0, p_card: CardInstance = null) -> BattleEvent:
	var event := BattleEvent.new()
	event.type = p_type
	event.subject = p_subject
	event.source = p_source
	event.amount = p_amount
	event.card = p_card
	return event
