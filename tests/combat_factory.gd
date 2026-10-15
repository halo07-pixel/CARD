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


## --- Dựng trận đấu cho test ---

static func registry() -> StatusRegistry:
	return StatusRegistry.load_from_dir("res://data/statuses")


## Thẻ tùy ý (không qua validate): effects + chế độ nhắm + ghi đè thuộc tính.
static func card_inst(id: StringName, effects: Array[EffectData], mode: CardData.TargetMode,
		extra: Dictionary = {}) -> CardInstance:
	var overrides := {"effects": effects, "target_mode": mode}
	overrides.merge(extra, true)
	return CardFactory.instance(id, overrides)


static func strike(id: StringName = &"strike", damage: int = 6, extra: Dictionary = {}) -> CardInstance:
	var effects: Array[EffectData] = [damage_effect(damage)]
	return card_inst(id, effects, CardData.TargetMode.SINGLE_ENEMY, extra)


static func defend(id: StringName = &"defend", amount: int = 5, extra: Dictionary = {}) -> CardInstance:
	var effects: Array[EffectData] = [EffectData.create(EffectData.Type.BLOCK, amount, EffectData.Target.SELF)]
	var overrides := {"card_type": CardData.CardType.SKILL}
	overrides.merge(extra, true)
	return card_inst(id, effects, CardData.TargetMode.SELF, overrides)


static func aoe(id: StringName = &"aoe", damage: int = 5, extra: Dictionary = {}) -> CardInstance:
	var effects: Array[EffectData] = [damage_effect(damage, EffectData.Target.ALL_ENEMIES)]
	return card_inst(id, effects, CardData.TargetMode.ALL_ENEMIES, extra)


static func draw_card(id: StringName = &"draw", count: int = 2, extra: Dictionary = {}) -> CardInstance:
	var effects: Array[EffectData] = [EffectData.create(EffectData.Type.DRAW, count, EffectData.Target.SELF)]
	var overrides := {"card_type": CardData.CardType.SKILL}
	overrides.merge(extra, true)
	return card_inst(id, effects, CardData.TargetMode.SELF, overrides)


static func energy_card(id: StringName = &"energy", amount: int = 2) -> CardInstance:
	var effects: Array[EffectData] = [EffectData.create(EffectData.Type.GAIN_ENERGY, amount, EffectData.Target.SELF)]
	return card_inst(id, effects, CardData.TargetMode.SELF,
			{"card_type": CardData.CardType.SKILL, "cost": 0, "exhaust": true})


static func weaken_card(id: StringName = &"weaken", amount: int = 1) -> CardInstance:
	var effects: Array[EffectData] = [
		EffectData.create(EffectData.Type.APPLY_STATUS, amount, EffectData.Target.TARGET_ENEMY, 1, &"weak")]
	return card_inst(id, effects, CardData.TargetMode.SINGLE_ENEMY, {"card_type": CardData.CardType.SKILL})


static func fillers(count: int, prefix: String = "f") -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for i in count:
		cards.append(strike(StringName("%s%d" % [prefix, i])))
	return cards


static func dummy_enemy(id: StringName = &"dummy", hp: int = 20, damage: int = 6) -> EnemyData:
	var moves: Array[EnemyMove] = [attack_move(&"hit", damage)]
	return enemy(id, hp, moves)


static func battle(cards: Array[CardInstance], datas: Array[EnemyData], seed_value: int = 1,
		config: BattleConfig = null, player_hp: int = 80) -> BattleController:
	return BattleController.create_from_data(combatant(&"player", player_hp), cards, datas,
			registry(), seed_value, config)


## Thẻ chèn thẳng vào tay (độc lập với kết quả xáo bài) để test có tính xác định.
static func inject(controller: BattleController, card: CardInstance) -> CardInstance:
	controller.deck.add_to_hand(card)
	return card


static func hand_card(controller: BattleController, id: StringName) -> CardInstance:
	for card in controller.deck.get_pile(Deck.HAND):
		if card.data.id == id:
			return card
	return null
