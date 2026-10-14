class_name DamageCalculator
extends RefCounted
## Công thức sát thương/giáp, đặt DUY NHẤT ở đây (thuần hàm, dễ test).
##   sát thương = floor((base + Strength) x Weak x Vulnerable), tối thiểu 0
##   giáp       = floor((base + Dexterity) x Frail), tối thiểu 0

const EPSILON := 0.000001  ## chống sai số float trước khi làm tròn xuống


static func compute_damage(base: int, attacker: Combatant, defender: Combatant) -> int:
	var value := (float(base) + attacker.damage_dealt_add()) \
			* attacker.damage_dealt_mult() * defender.damage_taken_mult()
	return maxi(floori(value + EPSILON), 0)


static func compute_block(base: int, owner: Combatant) -> int:
	var value := (float(base) + owner.block_gain_add()) * owner.block_gain_mult()
	return maxi(floori(value + EPSILON), 0)
