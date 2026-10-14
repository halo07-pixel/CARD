@abstract
class_name ResolverContext
extends RefCounted
## Giao diện mà EffectResolver cần từ trận đấu. BattleController (tính năng 3) sẽ cài đặt thật;
## test dùng bản giả. Tách ra để Resolver không phụ thuộc Deck/năng lượng/UI.

## Rút count thẻ, trả về số thẻ thực sự vào tay.
@abstract func draw_cards(count: int) -> int

@abstract func gain_energy(amount: int) -> void

## Trả null nếu id không tồn tại.
@abstract func get_status_data(status_id: StringName) -> StatusData

@abstract func get_rng() -> RandomNumberGenerator
