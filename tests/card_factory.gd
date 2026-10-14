extends RefCounted
## Tiện ích tạo dữ liệu cho test (không phải file test vì không bắt đầu bằng "test_").


## Thẻ Attack hợp lệ mặc định; ghi đè thuộc tính qua overrides, ví dụ {"retain": true}.
static func card(id: StringName, overrides: Dictionary = {}) -> CardData:
	var data := CardData.new()
	data.id = id
	data.display_name = String(id).capitalize()
	data.card_type = CardData.CardType.ATTACK
	data.cost = 1
	data.target_mode = CardData.TargetMode.SINGLE_ENEMY
	data.effects = [EffectData.create(EffectData.Type.DAMAGE, 6, EffectData.Target.TARGET_ENEMY)]
	for key: String in overrides:
		data.set(key, overrides[key])
	return data


static func instance(id: StringName, overrides: Dictionary = {}) -> CardInstance:
	return CardInstance.create(card(id, overrides))


## Danh sách instance với id "c0".."c{n-1}".
static func instances(n: int) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	for i in n:
		result.append(instance(StringName("c%d" % i)))
	return result


static func rng(seed_value: int = 1) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = seed_value
	return generator


## Danh sách id (Array thường) để so sánh bằng assert_eq.
static func ids(cards: Array[CardInstance]) -> Array:
	var result: Array = []
	for c in cards:
		result.append(String(c.data.id))
	return result
