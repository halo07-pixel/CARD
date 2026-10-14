extends ResolverContext
## Context giả cho test EffectResolver: ghi lại yêu cầu rút bài/năng lượng, tra status thật từ data/.

var registry: StatusRegistry
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var draw_requests: Array[int] = []
var draw_result: int = -1  ## -1 = trả về đúng số được yêu cầu
var energy_gained: int = 0


func _init(p_registry: StatusRegistry = null, seed_value: int = 1) -> void:
	registry = p_registry if p_registry != null else StatusRegistry.load_from_dir("res://data/statuses")
	rng.seed = seed_value


func draw_cards(count: int) -> int:
	draw_requests.append(count)
	return count if draw_result < 0 else draw_result


func gain_energy(amount: int) -> void:
	energy_gained += amount


func get_status_data(status_id: StringName) -> StatusData:
	return registry.get_status(status_id)


func get_rng() -> RandomNumberGenerator:
	return rng
