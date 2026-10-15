class_name BattleState
extends RefCounted
## Máy trạng thái của trận đấu với bảng chuyển hợp lệ DUY NHẤT. Chuyển sai bị từ chối.
## Thắng/thua được phép xảy ra từ mọi pha đang diễn ra (ví dụ hạ quái cuối bằng một thẻ).

signal changed(from_phase: Phase, to_phase: Phase)

enum Phase { SETUP, PLAYER_START, PLAYER_TURN, ENEMY_TURN, CHECK_END, VICTORY, DEFEAT }

const TRANSITIONS := {
	Phase.SETUP: [Phase.PLAYER_START],
	Phase.PLAYER_START: [Phase.PLAYER_TURN, Phase.VICTORY, Phase.DEFEAT],
	Phase.PLAYER_TURN: [Phase.ENEMY_TURN, Phase.VICTORY, Phase.DEFEAT],
	Phase.ENEMY_TURN: [Phase.CHECK_END, Phase.VICTORY, Phase.DEFEAT],
	Phase.CHECK_END: [Phase.PLAYER_START, Phase.VICTORY, Phase.DEFEAT],
	Phase.VICTORY: [],
	Phase.DEFEAT: [],
}

var phase: Phase = Phase.SETUP


func can_transition(to_phase: Phase) -> bool:
	return TRANSITIONS[phase].has(to_phase)


## Trả về false (và giữ nguyên trạng thái) nếu chuyển không hợp lệ.
func transition(to_phase: Phase) -> bool:
	if not can_transition(to_phase):
		push_error("BattleState: chuyển %s -> %s không hợp lệ" % [Phase.keys()[phase], Phase.keys()[to_phase]])
		return false
	var from_phase := phase
	phase = to_phase
	changed.emit(from_phase, to_phase)
	return true


func is_terminal() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT


func is_player_turn() -> bool:
	return phase == Phase.PLAYER_TURN
