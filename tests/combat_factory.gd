extends RefCounted
## Tiện ích dựng dữ liệu chiến đấu cho test. Status dựng bằng code (độc lập với file .tres).

const S := StatusData.StackMode


static func status(id: StringName, mode: StatusData.StackMode, props: Dictionary = {}) -> StatusData:
	var data := StatusData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.stack_mode = mode
	for key: String in props:
		data.set(key, props[key])
	return data


static func strength() -> StatusData:
	return status(&"strength", S.INTENSITY, {"can_be_negative": true, "damage_dealt_add_per_stack": 1.0})


static func dexterity() -> StatusData:
	return status(&"dexterity", S.INTENSITY, {"can_be_negative": true, "block_gain_add_per_stack": 1.0})


static func vulnerable() -> StatusData:
	return status(&"vulnerable", S.DURATION, {"decays_at_turn_end": true, "damage_taken_mult": 1.5})


static func weak() -> StatusData:
	return status(&"weak", S.DURATION, {"decays_at_turn_end": true, "damage_dealt_mult": 0.75})


static func frail() -> StatusData:
	return status(&"frail", S.DURATION, {"decays_at_turn_end": true, "block_gain_mult": 0.75})


static func combatant(id: StringName = &"c", hp: int = 50) -> Combatant:
	return Combatant.create(id, String(id).capitalize(), hp)


static func damage_effect(amount: int, target: EffectData.Target = EffectData.Target.TARGET_ENEMY,
		hits: int = 1) -> EffectData:
	return EffectData.create(EffectData.Type.DAMAGE, amount, target, hits)
