extends SceneTree
## Sinh thẻ mẫu của Warrior. Chạy: godot --headless --path . -s res://tools/generate_starter_cards.gd
## KHÔNG ghi đè file đã có (file .tres là nguồn dữ liệu chính, đã có thể được chỉnh tay/trong editor).

const OUT_DIR := "res://data/cards/"
const T := EffectData.Type
const G := EffectData.Target
const C := CardData.CardType
const R := CardData.Rarity
const M := CardData.TargetMode


func _initialize() -> void:
	var cards: Array[CardData] = [
		_make(&"strike", "Strike", "Deal {damage} damage.", C.ATTACK, [_dmg(6)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER, "upgraded_id": &"strike+"}),
		_make(&"strike+", "Strike+", "Deal {damage} damage.", C.ATTACK, [_dmg(9)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER}),
		_make(&"defend", "Defend", "Gain {block} Block.", C.SKILL, [_block(5)], M.SELF,
				{"rarity": R.STARTER, "upgraded_id": &"defend+"}),
		_make(&"defend+", "Defend+", "Gain {block} Block.", C.SKILL, [_block(8)], M.SELF,
				{"rarity": R.STARTER}),
		_make(&"bash", "Bash", "Deal {damage} damage. Apply {vulnerable} Vulnerable.", C.ATTACK,
				[_dmg(8), _status(2, &"vulnerable", G.TARGET_ENEMY)], M.SINGLE_ENEMY,
				{"rarity": R.STARTER, "cost": 2}),
		_make(&"cleave", "Cleave", "Deal {damage} damage to ALL enemies.", C.ATTACK,
				[_dmg(8, G.ALL_ENEMIES)], M.ALL_ENEMIES, {}),
		_make(&"iron_wave", "Iron Wave", "Gain {block} Block. Deal {damage} damage.", C.ATTACK,
				[_block(5), _dmg(5)], M.SINGLE_ENEMY, {}),
		_make(&"pommel_strike", "Pommel Strike", "Deal {damage} damage. Draw {draw} card.", C.ATTACK,
				[_dmg(9), _draw(1)], M.SINGLE_ENEMY, {}),
		_make(&"shrug_it_off", "Shrug It Off", "Gain {block} Block. Draw {draw} card.", C.SKILL,
				[_block(8), _draw(1)], M.SELF, {}),
		_make(&"twin_strike", "Twin Strike", "Deal {damage} damage twice.", C.ATTACK,
				[EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY, 2)], M.SINGLE_ENEMY, {}),
		_make(&"adrenaline", "Adrenaline", "Gain {energy} Energy. Draw {draw} cards. Exhaust.", C.SKILL,
				[EffectData.create(T.GAIN_ENERGY, 1, G.SELF), _draw(2)], M.SELF,
				{"rarity": R.UNCOMMON, "cost": 0, "exhaust": true}),
		_make(&"thunderclap", "Thunderclap", "Deal {damage} damage and apply {vulnerable} Vulnerable to ALL enemies.",
				C.ATTACK, [_dmg(4, G.ALL_ENEMIES), _status(1, &"vulnerable", G.ALL_ENEMIES)],
				M.ALL_ENEMIES, {}),
	]
	var ok := true
	for card in cards:
		ok = _save(card) and ok
	quit(0 if ok else 1)


func _dmg(amount: int, target: EffectData.Target = G.TARGET_ENEMY) -> EffectData:
	return EffectData.create(T.DAMAGE, amount, target)


func _block(amount: int) -> EffectData:
	return EffectData.create(T.BLOCK, amount, G.SELF)


func _draw(amount: int) -> EffectData:
	return EffectData.create(T.DRAW, amount, G.SELF)


func _status(amount: int, status_id: StringName, target: EffectData.Target) -> EffectData:
	return EffectData.create(T.APPLY_STATUS, amount, target, 1, status_id)


func _make(id: StringName, display_name: String, description: String, card_type: CardData.CardType,
		effects: Array[EffectData], target_mode: CardData.TargetMode, props: Dictionary) -> CardData:
	var card := CardData.new()
	card.id = id
	card.display_name = display_name
	card.description = description
	card.card_type = card_type
	card.rarity = R.COMMON
	card.character_id = &"warrior"
	card.cost = 1
	card.target_mode = target_mode
	card.effects = effects
	card.icon_id = StringName(String(id).trim_suffix("+"))
	for key: String in props:
		card.set(key, props[key])
	return card


func _save(card: CardData) -> bool:
	var errors := card.validate()
	if not errors.is_empty():
		printerr("Thẻ %s không hợp lệ: %s" % [card.id, errors])
		return false
	var file_name := String(card.id).replace("+", "_plus") + ".tres"
	if FileAccess.file_exists(OUT_DIR + file_name):
		print("đã có, bỏ qua ", file_name)
		return true
	var err := ResourceSaver.save(card, OUT_DIR + file_name)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [file_name, err])
		return false
	print("đã tạo ", file_name)
	return true
