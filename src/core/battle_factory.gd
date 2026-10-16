class_name BattleFactory
extends RefCounted
## Dựng một trận đấu hoàn chỉnh từ DỮ LIỆU (nhân vật, id thẻ, id quái) + các registry.
## Không phụ thuộc autoload/RunState: caller truyền vào máu hiện tại và danh sách id.


## Combatant cho người chơi. current_hp < 0 = đầy máu; ngược lại giới hạn trong [0, max_hp].
static func create_player(character: CharacterData, current_hp: int = -1) -> Combatant:
	var player := Combatant.create(character.id, character.display_name, character.max_hp)
	if player != null and current_hp >= 0 and current_hp < character.max_hp:
		player.lose_hp(character.max_hp - current_hp)
	return player


## Trả null (kèm log) nếu thiếu dữ liệu: id thẻ/quái không tồn tại, registry null, nhân vật lỗi...
static func create(character: CharacterData, player: Combatant, deck_ids: Array[StringName],
		enemy_ids: Array[StringName], cards: CardRegistry, enemies: EnemyRegistry,
		statuses: StatusRegistry, seed_value: int = 1, turn_cap: int = 0) -> BattleController:
	if character == null or player == null or cards == null or enemies == null or statuses == null:
		push_error("BattleFactory.create: thiếu character/player/registry")
		return null
	var config := character.make_battle_config()
	config.turn_cap = turn_cap
	var datas: Array[EnemyData] = []
	for enemy_id in enemy_ids:
		var data := enemies.get_enemy(enemy_id)
		if data == null:
			push_error("BattleFactory.create: không có quái '%s'" % enemy_id)
			return null
		datas.append(data)
	var instances := cards.create_instances(deck_ids)
	if instances.is_empty():
		push_error("BattleFactory.create: bộ bài rỗng hoặc có thẻ không tồn tại")
		return null
	return BattleController.create_from_data(player, instances, datas, statuses, seed_value, config)
