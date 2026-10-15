class_name EnemyRegistry
extends ResourceRegistry
## Tra cứu EnemyData theo id.


static func load_from_dir(dir_path: String) -> EnemyRegistry:
	var registry := EnemyRegistry.new()
	registry._load_dir(dir_path)
	return registry


func get_enemy(enemy_id: StringName) -> EnemyData:
	return _find(enemy_id) as EnemyData


func has_enemy(enemy_id: StringName) -> bool:
	return has_id(enemy_id)


func _id_of(resource: Resource) -> StringName:
	return (resource as EnemyData).id


func _validate(resource: Resource) -> Array[String]:
	var data := resource as EnemyData
	if data == null:
		var wrong_type: Array[String] = ["không phải EnemyData"]
		return wrong_type
	return data.validate()
