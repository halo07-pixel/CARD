extends "res://tests/test_case.gd"

const P := BattleState.Phase


func test_starts_in_setup() -> void:
	var state := BattleState.new()
	assert_eq(state.phase, P.SETUP)
	assert_false(state.is_terminal())
	assert_false(state.is_player_turn())


func test_transition_table_is_exhaustive_and_enforced() -> void:
	var allowed := {
		P.SETUP: [P.PLAYER_START],
		P.PLAYER_START: [P.PLAYER_TURN, P.VICTORY, P.DEFEAT],
		P.PLAYER_TURN: [P.ENEMY_TURN, P.VICTORY, P.DEFEAT],
		P.ENEMY_TURN: [P.CHECK_END, P.VICTORY, P.DEFEAT],
		P.CHECK_END: [P.PLAYER_START, P.VICTORY, P.DEFEAT],
		P.VICTORY: [],
		P.DEFEAT: [],
	}
	for from_phase: int in allowed:
		for to_phase: int in P.values():
			var state := BattleState.new()
			state.phase = from_phase
			assert_eq(state.can_transition(to_phase), allowed[from_phase].has(to_phase),
					"%s -> %s" % [P.keys()[from_phase], P.keys()[to_phase]])


func test_invalid_transition_is_rejected_and_keeps_phase() -> void:
	var state := BattleState.new()
	assert_false(state.transition(P.PLAYER_TURN), "không được nhảy cóc SETUP -> PLAYER_TURN")
	assert_eq(state.phase, P.SETUP)
	assert_false(state.transition(P.SETUP), "không được chuyển về chính nó")


func test_terminal_states_have_no_exit() -> void:
	for terminal: int in [P.VICTORY, P.DEFEAT]:
		var state := BattleState.new()
		state.phase = terminal
		assert_true(state.is_terminal())
		for to_phase: int in P.values():
			assert_false(state.can_transition(to_phase))


func test_signal_carries_from_and_to_and_not_emitted_on_rejection() -> void:
	var state := BattleState.new()
	var log: Array = []
	state.changed.connect(func(a: int, b: int) -> void: log.append([a, b]))
	state.transition(P.PLAYER_START)
	state.transition(P.PLAYER_TURN)
	state.transition(P.SETUP)  # bị từ chối
	assert_eq(log, [[P.SETUP, P.PLAYER_START], [P.PLAYER_START, P.PLAYER_TURN]])
	assert_true(state.is_player_turn())
