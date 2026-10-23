class_name TriggerRunner
extends RefCounted
## Nối sự kiện -> trigger -> hàng đợi -> thực thi. BattleController chỉ gọi fire()/drain();
## runner không giữ tham chiếu ngược tới controller (tránh vòng tham chiếu), controller được truyền
## vào mỗi lần gọi.
## Quy tắc chống vòng lặp: effect do TRIGGER sinh ra KHÔNG tạo sự kiện ATTACKED (Thorns không kích
## hoạt Thorns); thêm giới hạn cứng số hành động mỗi lần drain.

const MAX_ACTIONS_PER_DRAIN := 1000

var overflowed: bool = false  ## đã từng vượt giới hạn (bộ kiểm tra bất biến sẽ báo)
var _dispatcher := TriggerDispatcher.new()
var _queue := ActionQueue.new()


func new_turn() -> void:
	_dispatcher.new_turn()


func queue_size() -> int:
	return _queue.size()


## Xếp hàng các hiệu ứng mà sự kiện này kích hoạt (chưa thực thi).
func fire(event: BattleEvent, controller: BattleController) -> void:
	for action in _dispatcher.actions_for(event, _collect_sources(controller)):
		_queue.push(action)


## Chuyển kết quả effect thành sự kiện (ATTACKED chỉ khi không phải do trigger; HP_LOST luôn có).
func events_from_results(results: Array[EffectResult], from_trigger: bool, controller: BattleController) -> void:
	for result in results:
		match result.type:
			EffectData.Type.DAMAGE:
				if result.damage == null or not result.damage.accepted:
					continue
				if not from_trigger:
					fire(BattleEvent.create(TriggerData.Event.ATTACKED, result.target, result.source,
							result.damage.incoming), controller)
				if result.damage.hp_lost > 0:
					fire(BattleEvent.create(TriggerData.Event.HP_LOST, result.target, result.source,
							result.damage.hp_lost), controller)
			EffectData.Type.LOSE_HP:
				if result.amount > 0:
					fire(BattleEvent.create(TriggerData.Event.HP_LOST, result.target, result.source,
							result.amount), controller)


## Thực thi hàng đợi theo thứ tự FIFO cho tới khi rỗng. Vượt giới hạn: dừng, ghi lỗi, xóa hàng đợi.
func drain(controller: BattleController) -> void:
	var executed := 0
	while not _queue.is_empty():
		if executed >= MAX_ACTIONS_PER_DRAIN:
			push_error("TriggerRunner: vượt %d hành động trigger trong một lần xử lý (vòng lặp?)" % MAX_ACTIONS_PER_DRAIN)
			_queue.clear()
			overflowed = true
			return
		executed += 1
		var action := _queue.pop()
		if not action.owner.is_alive():
			continue  # chủ sở hữu đã chết trước khi trigger kịp thực thi
		var results := EffectResolver.resolve(action.effect, action.owner, action.event_source,
				_opponents_of(action.owner, controller), controller)
		if results.is_empty():
			continue
		controller.triggered.emit(action.owner, action.key, results)
		events_from_results(results, true, controller)


## Thứ tự cố định: người chơi trước (relic rồi status), rồi quái theo thứ tự trong trận.
func _collect_sources(controller: BattleController) -> Array[TriggerSource]:
	var sources: Array[TriggerSource] = []
	sources.append_array(TriggerSource.from_relics(controller.player, controller.relics))
	sources.append_array(TriggerSource.from_statuses(controller.player))
	for unit in controller.enemies:
		sources.append_array(TriggerSource.from_statuses(unit.combatant))
	return sources


func _opponents_of(owner: Combatant, controller: BattleController) -> Array[Combatant]:
	var opponents: Array[Combatant] = []
	if owner == controller.player:
		for unit in controller.enemies:
			opponents.append(unit.combatant)
	else:
		opponents.append(controller.player)
	return opponents
