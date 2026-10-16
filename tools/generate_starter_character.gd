extends SceneTree
## Sinh nhân vật Warrior. Chạy: godot --headless --path . -s res://tools/generate_starter_character.gd
## KHÔNG ghi đè file đã có.

const OUT_PATH := "res://data/characters/warrior.tres"


func _initialize() -> void:
	var warrior := CharacterData.new()
	warrior.id = &"warrior"
	warrior.display_name = "Warrior"
	warrior.max_hp = 80
	warrior.max_energy = 3
	warrior.draw_per_turn = 5
	warrior.starting_gold = 99
	warrior.icon_id = &"warrior"
	var deck: Array[StringName] = []
	for i in 5:
		deck.append(&"strike")
	for i in 4:
		deck.append(&"defend")
	deck.append(&"bash")
	warrior.starting_deck = deck
	var errors := warrior.validate()
	if not errors.is_empty():
		printerr("Warrior không hợp lệ: %s" % [errors])
		quit(1)
		return
	if FileAccess.file_exists(OUT_PATH):
		print("đã có, bỏ qua warrior.tres")
		quit(0)
		return
	var err := ResourceSaver.save(warrior, OUT_PATH)
	print("đã tạo warrior.tres" if err == OK else "LỖI lưu warrior.tres (%d)" % err)
	quit(0 if err == OK else 1)
