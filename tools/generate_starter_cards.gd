extends SceneTree
## Sinh thẻ khởi đầu của Warrior. Chạy: godot --headless --path . -s res://tools/generate_starter_cards.gd
## Sau khi sinh, các file .tres là nguồn dữ liệu chính (sửa tay hoặc trong editor đều được).

const OUT_DIR := "res://data/cards/"


func _initialize() -> void:
	var ok := true
	ok = _save(_make(&"strike", "Strike", "Deal {damage} damage.", CardData.CardType.ATTACK,
			[EffectData.create(EffectData.Type.DAMAGE, 6, EffectData.Target.TARGET_ENEMY)],
			CardData.TargetMode.SINGLE_ENEMY, &"strike+")) and ok
	ok = _save(_make(&"strike+", "Strike+", "Deal {damage} damage.", CardData.CardType.ATTACK,
			[EffectData.create(EffectData.Type.DAMAGE, 9, EffectData.Target.TARGET_ENEMY)],
			CardData.TargetMode.SINGLE_ENEMY, &"")) and ok
	ok = _save(_make(&"defend", "Defend", "Gain {block} Block.", CardData.CardType.SKILL,
			[EffectData.create(EffectData.Type.BLOCK, 5, EffectData.Target.SELF)],
			CardData.TargetMode.SELF, &"defend+")) and ok
	ok = _save(_make(&"defend+", "Defend+", "Gain {block} Block.", CardData.CardType.SKILL,
			[EffectData.create(EffectData.Type.BLOCK, 8, EffectData.Target.SELF)],
			CardData.TargetMode.SELF, &"")) and ok
	quit(0 if ok else 1)


func _make(id: StringName, display_name: String, description: String, card_type: CardData.CardType,
		effects: Array[EffectData], target_mode: CardData.TargetMode, upgraded_id: StringName) -> CardData:
	var card := CardData.new()
	card.id = id
	card.display_name = display_name
	card.description = description
	card.card_type = card_type
	card.rarity = CardData.Rarity.STARTER
	card.character_id = &"warrior"
	card.cost = 1
	card.target_mode = target_mode
	card.effects = effects
	card.upgraded_id = upgraded_id
	card.icon_id = StringName(String(id).trim_suffix("+"))
	return card


func _save(card: CardData) -> bool:
	var errors := card.validate()
	if not errors.is_empty():
		printerr("Thẻ %s không hợp lệ: %s" % [card.id, errors])
		return false
	var file_name := String(card.id).replace("+", "_plus") + ".tres"
	var err := ResourceSaver.save(card, OUT_DIR + file_name)
	if err != OK:
		printerr("Lưu %s thất bại (lỗi %d)" % [file_name, err])
		return false
	print("đã tạo ", file_name)
	return true
