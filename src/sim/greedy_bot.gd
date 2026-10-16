class_name GreedyBot
extends BattleBot
## Người chơi "biết đại khái": mỗi bước chọn (thẻ, mục tiêu) có giá trị cao nhất trên mỗi năng lượng.
## Ưu tiên hạ quái (thắng trận > hạ một quái > gây sát thương), chặn đúng lượng sát thương sắp nhận
## (không phí giáp), rút bài/lấy năng lượng khi rẻ, và kết thúc lượt khi không còn gì đáng chơi.

const WIN_BONUS := 1000.0
const KILL_BONUS := 25.0
const BLOCK_USEFUL := 1.1
const BLOCK_WASTED := 0.1
const DRAW_VALUE := 2.5
const ENERGY_VALUE := 3.0
const SELF_BUFF_VALUE := 3.0
const MIN_VALUE := 0.01
const COST_SMOOTHING := 0.5  ## thẻ 0 năng lượng không có giá trị "vô hạn"

const STATUS_VALUE := {&"vulnerable": 4.0, &"weak": 3.0}
const OTHER_DEBUFF_VALUE := 2.0


func act(controller: BattleController) -> void:
	var best_card: CardInstance = null
	var best_target: EnemyUnit = null
	var best_value := MIN_VALUE
	var incoming := _incoming_damage(controller)
	for card in _playable_cards(controller):
		var targets := controller.valid_targets(card)
		var options: Array = [null] if targets.is_empty() else targets
		var cost := controller.energy if card.data.is_x_cost else card.get_cost()
		for option in options:
			var target := option as EnemyUnit
			var value := _score(controller, card, target, incoming) / (float(cost) + COST_SMOOTHING)
			if value > best_value:
				best_value = value
				best_card = card
				best_target = target
	if best_card == null:
		controller.end_player_turn()
	else:
		controller.play_card(best_card, best_target)


func _incoming_damage(controller: BattleController) -> int:
	var total := 0
	for unit in controller.living_enemies():
		if unit.intent != null and unit.intent.attacks:
			total += unit.intent.total_damage
	return total


func _score(controller: BattleController, card: CardInstance, target: EnemyUnit, incoming: int) -> float:
	var score := _damage_score(controller, card, target)
	var living_count := controller.living_enemies().size()
	for effect in card.data.effects:
		match effect.type:
			EffectData.Type.BLOCK:
				var gained := DamageCalculator.compute_block(effect.amount, controller.player)
				var useful := clampi(incoming - controller.player.block, 0, gained)
				score += useful * BLOCK_USEFUL + (gained - useful) * BLOCK_WASTED
			EffectData.Type.DRAW:
				if controller.deck.count(Deck.HAND) < Deck.MAX_HAND_SIZE - 1:
					score += DRAW_VALUE * effect.amount
			EffectData.Type.GAIN_ENERGY:
				score += ENERGY_VALUE * effect.amount
			EffectData.Type.APPLY_STATUS:
				score += _status_score(effect, living_count)
	return score


## Sát thương kỳ vọng + thưởng hạ quái; hạ hết quái còn sống = thắng trận.
func _damage_score(controller: BattleController, card: CardInstance, target: EnemyUnit) -> float:
	var living := controller.living_enemies()
	var dealt: Dictionary = {}  ## EnemyUnit -> sát thương kỳ vọng
	for effect in card.data.effects:
		if effect.type != EffectData.Type.DAMAGE:
			continue
		var victims: Array[EnemyUnit] = []
		match effect.target:
			EffectData.Target.TARGET_ENEMY:
				if target != null:
					victims.append(target)
			EffectData.Target.ALL_ENEMIES:
				victims.assign(living)
			EffectData.Target.RANDOM_ENEMY:
				victims.assign(living)
		for victim in victims:
			var per_hit := DamageCalculator.compute_damage(effect.amount, controller.player, victim.combatant)
			var share := effect.hits * (1.0 / victims.size() if effect.target == EffectData.Target.RANDOM_ENEMY else 1.0)
			dealt[victim] = dealt.get(victim, 0.0) + per_hit * share
	var score := 0.0
	var kills := 0
	for victim: EnemyUnit in dealt:
		var effective_hp := victim.combatant.hp + victim.combatant.block
		score += minf(dealt[victim], effective_hp)
		if dealt[victim] >= effective_hp:
			kills += 1
			score += KILL_BONUS
	if kills > 0 and kills == living.size():
		score += WIN_BONUS
	return score


func _status_score(effect: EffectData, living_count: int) -> float:
	if effect.target == EffectData.Target.SELF:
		return SELF_BUFF_VALUE * effect.amount
	var per_target: float = STATUS_VALUE.get(effect.status_id, OTHER_DEBUFF_VALUE)
	var target_count := living_count if effect.target == EffectData.Target.ALL_ENEMIES else 1
	return per_target * effect.amount * target_count
