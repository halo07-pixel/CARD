class_name EffectResolver
extends RefCounted
## Áp dụng EffectData lên các Combatant. Không biết gì về UI/Deck: phần thuộc về trận
## (rút bài, năng lượng, tra status, RNG) đi qua ResolverContext.
## "opponents" = phe đối diện với source (người chơi đánh -> quái; quái đánh -> [người chơi]).
## "chosen_target" = mục tiêu đã chọn cho TARGET_ENEMY, hoặc kẻ gây sự kiện cho EVENT_SOURCE.

const T := EffectData.Type
const G := EffectData.Target


## Trả về danh sách kết quả (rỗng nếu bị từ chối). Kiểm tra state trước: source phải còn sống,
## effect phải hợp lệ, mục tiêu đơn phải còn sống và thuộc phe đối diện.
static func resolve(effect: EffectData, source: Combatant, chosen_target: Combatant,
		opponents: Array[Combatant], context: ResolverContext) -> Array[EffectResult]:
	var results: Array[EffectResult] = []
	if effect == null or source == null or context == null:
		push_error("EffectResolver: thiếu effect/source/context")
		return results
	if not source.is_alive():
		push_warning("EffectResolver: source đã chết, từ chối")
		return results
	var errors := effect.validate(true)  # EVENT_SOURCE đúng ngữ cảnh đã được TriggerData kiểm tra
	if not errors.is_empty():
		push_error("EffectResolver: effect không hợp lệ: %s" % [errors])
		return results
	match effect.type:
		T.DAMAGE:
			_resolve_damage(effect, source, chosen_target, opponents, context, results)
		T.BLOCK:
			_resolve_block(effect, source, results)
		T.DRAW:
			results.append(_make_result(effect, source, null, context.draw_cards(effect.amount)))
		T.GAIN_ENERGY:
			context.gain_energy(effect.amount)
			results.append(_make_result(effect, source, null, effect.amount))
		T.APPLY_STATUS:
			_resolve_status(effect, source, chosen_target, opponents, context, results)
		T.HEAL, T.LOSE_HP:
			_resolve_hp(effect, source, chosen_target, opponents, context, results)
	return results


static func _resolve_damage(effect: EffectData, source: Combatant, chosen: Combatant,
		opponents: Array[Combatant], context: ResolverContext, results: Array[EffectResult]) -> void:
	var single_target := effect.target == G.TARGET_ENEMY or effect.target == G.EVENT_SOURCE
	for hit in effect.hits:
		if hit > 0 and single_target and (chosen == null or not chosen.is_alive()):
			return  # mục tiêu đơn đã chết ở hit trước: dừng im lặng (không phải lỗi gọi sai)
		var targets := _pick_targets(effect, source, chosen, opponents, context)
		if targets.is_empty():
			return  # hết mục tiêu sống: dừng các hit còn lại
		for target in targets:
			var final_damage := DamageCalculator.compute_damage(effect.amount, source, target)
			var result := _make_result(effect, source, target, final_damage)
			result.damage = target.take_damage(final_damage)
			results.append(result)


static func _resolve_block(effect: EffectData, source: Combatant, results: Array[EffectResult]) -> void:
	var gained := DamageCalculator.compute_block(effect.amount, source)
	source.gain_block(gained)
	results.append(_make_result(effect, source, source, gained))


static func _resolve_status(effect: EffectData, source: Combatant, chosen: Combatant,
		opponents: Array[Combatant], context: ResolverContext, results: Array[EffectResult]) -> void:
	var data := context.get_status_data(effect.status_id)
	if data == null:
		push_error("EffectResolver: không có status '%s'" % effect.status_id)
		return
	for target in _pick_targets(effect, source, chosen, opponents, context):
		if target.add_status(data, effect.amount):
			var result := _make_result(effect, source, target, effect.amount)
			result.status_id = effect.status_id
			results.append(result)


## HEAL: hồi máu (SELF). LOSE_HP: mất máu trực tiếp, bỏ qua giáp. amount trong kết quả là lượng THỰC.
static func _resolve_hp(effect: EffectData, source: Combatant, chosen: Combatant,
		opponents: Array[Combatant], context: ResolverContext, results: Array[EffectResult]) -> void:
	for target in _pick_targets(effect, source, chosen, opponents, context):
		var actual := target.heal(effect.amount) if effect.type == T.HEAL else target.lose_hp(effect.amount)
		results.append(_make_result(effect, source, target, actual))


## Danh sách mục tiêu SỐNG cho một hit. RANDOM_ENEMY chọn lại mỗi hit bằng RNG của context.
static func _pick_targets(effect: EffectData, source: Combatant, chosen: Combatant,
		opponents: Array[Combatant], context: ResolverContext) -> Array[Combatant]:
	var targets: Array[Combatant] = []
	match effect.target:
		G.SELF:
			if source.is_alive():
				targets.append(source)
		G.TARGET_ENEMY:
			if chosen != null and chosen.is_alive() and opponents.has(chosen):
				targets.append(chosen)
			else:
				push_warning("EffectResolver: mục tiêu đơn không hợp lệ (null/đã chết/không thuộc phe đối diện)")
		G.EVENT_SOURCE:
			if chosen != null and chosen.is_alive():
				targets.append(chosen)  # kẻ gây sự kiện đã chết/không rõ thì bỏ qua, không phải lỗi
		G.ALL_ENEMIES:
			targets.assign(_living(opponents))
		G.RANDOM_ENEMY:
			var living := _living(opponents)
			if not living.is_empty():
				targets.append(living[context.get_rng().randi_range(0, living.size() - 1)])
	return targets


static func _living(combatants: Array[Combatant]) -> Array[Combatant]:
	var living: Array[Combatant] = []
	for combatant in combatants:
		if combatant != null and combatant.is_alive():
			living.append(combatant)
	return living


static func _make_result(effect: EffectData, source: Combatant, target: Combatant, amount: int) -> EffectResult:
	var result := EffectResult.new()
	result.type = effect.type
	result.source = source
	result.target = target
	result.amount = amount
	return result
