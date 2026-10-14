extends "res://tests/test_case.gd"

const T := EffectData.Type
const G := EffectData.Target


func test_valid_effects_have_no_errors() -> void:
	assert_true(EffectData.create(T.DAMAGE, 6, G.TARGET_ENEMY).validate().is_empty())
	assert_true(EffectData.create(T.DAMAGE, 3, G.ALL_ENEMIES, 2).validate().is_empty())
	assert_true(EffectData.create(T.BLOCK, 5, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.DRAW, 2, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.GAIN_ENERGY, 1, G.SELF).validate().is_empty())
	assert_true(EffectData.create(T.APPLY_STATUS, 2, G.TARGET_ENEMY, 1, &"vulnerable").validate().is_empty())


func test_non_positive_amount_is_invalid() -> void:
	assert_false(EffectData.create(T.DAMAGE, 0, G.TARGET_ENEMY).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, -3, G.SELF).validate().is_empty())


func test_hits_rules() -> void:
	assert_false(EffectData.create(T.DAMAGE, 3, G.TARGET_ENEMY, 0).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, 3, G.SELF, 2).validate().is_empty())


func test_status_id_rules() -> void:
	assert_false(EffectData.create(T.APPLY_STATUS, 1, G.TARGET_ENEMY).validate().is_empty(), "thiếu status_id")
	assert_false(EffectData.create(T.DAMAGE, 5, G.TARGET_ENEMY, 1, &"weak").validate().is_empty(), "status_id thừa")


func test_target_rules() -> void:
	assert_false(EffectData.create(T.DAMAGE, 5, G.SELF).validate().is_empty())
	assert_false(EffectData.create(T.BLOCK, 5, G.TARGET_ENEMY).validate().is_empty())
	assert_false(EffectData.create(T.DRAW, 1, G.ALL_ENEMIES).validate().is_empty())
	assert_false(EffectData.create(T.GAIN_ENERGY, 1, G.RANDOM_ENEMY).validate().is_empty())
