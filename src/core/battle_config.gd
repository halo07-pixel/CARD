class_name BattleConfig
extends RefCounted
## Thông số một trận đấu. Mặc định theo Slay the Spire; CharacterData (1.3c) sẽ cung cấp giá trị
## theo nhân vật.

var max_energy: int = 3
var draw_per_turn: int = 5
## 0 = không giới hạn. Bot/test đặt giới hạn để trận bế tắc không chạy vô hạn (kết thúc = thua).
var turn_cap: int = 0


## Trả về danh sách lỗi (rỗng = hợp lệ).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if max_energy < 1:
		errors.append("max_energy phải >= 1 (hiện %d)" % max_energy)
	if draw_per_turn < 1:
		errors.append("draw_per_turn phải >= 1 (hiện %d)" % draw_per_turn)
	if turn_cap < 0:
		errors.append("turn_cap không được âm (hiện %d)" % turn_cap)
	return errors
