extends RefCounted
## Tiện ích dựng dữ liệu chiến đấu cho test. Status dựng bằng code (độc lập với file .tres).

const S := StatusData.StackMode
const CardFactory := preload("res://tests/card_factory.gd")


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


## --- Dữ liệu quái cho test ---

static func move(id: StringName, effects: Array[EffectData], weight: int = 1,
		max_consecutive: int = 0) -> EnemyMove:
	var m := EnemyMove.new()
	m.id = id
	m.display_name = String(id).capitalize()
	m.effects = effects
	m.weight = weight
	m.max_consecutive = max_consecutive
	return m


static func attack_move(id: StringName, damage: int, weight: int = 1, max_consecutive: int = 0,
		hits: int = 1) -> EnemyMove:
	var effects: Array[EffectData] = [damage_effect(damage, EffectData.Target.TARGET_ENEMY, hits)]
	return move(id, effects, weight, max_consecutive)


static func block_move(id: StringName, amount: int) -> EnemyMove:
	var effects: Array[EffectData] = [EffectData.create(EffectData.Type.BLOCK, amount, EffectData.Target.SELF)]
	return move(id, effects)


static func status_move(id: StringName, status_id: StringName, amount: int,
		target: EffectData.Target) -> EnemyMove:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, amount, target, 1, status_id)]
	return move(id, effects)


static func enemy(id: StringName, hp: int, moves: Array[EnemyMove],
		pattern: EnemyData.PatternKind = EnemyData.PatternKind.SEQUENCE,
		overrides: Dictionary = {}) -> EnemyData:
	var data := EnemyData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.max_hp = hp
	data.moves = moves
	data.pattern = pattern
	for key: String in overrides:
		data.set(key, overrides[key])
	return data


## RNG có seed cố định (dùng lại hàm của card_factory để không chép code).
static func rng(seed_value: int = 1) -> RandomNumberGenerator:
	return CardFactory.rng(seed_value)
