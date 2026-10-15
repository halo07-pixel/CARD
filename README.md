# Spire Cards

Game thẻ bài roguelike theo lối chơi Slay the Spire, làm bằng **Godot 4.7** (GDScript, renderer Compatibility).
Mục tiêu: bản chơi được đầy đủ vòng lặp (map, chiến đấu, thưởng, cửa hàng, lửa trại, sự kiện, boss) với ~70% nội dung của Slay the Spire.

## Chạy test (headless)

```bash
# cần Godot 4.7.x trong PATH, hoặc đặt GODOT=/duong/dan/toi/godot
bash tools/run_tests.sh
```

Runner quét `tests/test_*.gd`, thoát mã `1` nếu có test lỗi. Trên máy không có màn hình vẫn chạy được.

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `src/data/` | Resource dữ liệu thuần: `CardData`, `EffectData`, `StatusData`, `EnemyData`, `EnemyMove` (không chứa logic, không giữ hình) |
| `src/core/` | Lõi chiến đấu, không dùng node/UI: `Deck`, `Combatant`, `EffectResolver`, `DamageCalculator`, `EnemyAI`, `EnemyUnit`, `BattleController`, `BattleState`, `ResourceRegistry`... |
| `src/autoload/` | `EventBus`, `RunState`, `SaveSystem`, `AudioManager`, `SceneRouter` |
| `data/` | File `.tres` của thẻ, quái, trạng thái (thêm nội dung = thêm file) |
| `tests/` | Test headless |
| `tools/` | Script chạy test, sinh dữ liệu mẫu |
| `assets/` | Asset bên thứ ba. **Mọi asset phải ghi vào `assets/CREDITS.md`** (tên, tác giả, nguồn, giấy phép) |

## Nguyên tắc code

- Call down, signal up: không dùng `get_parent().get_parent()`; node con báo lên bằng Signal.
- Tách dữ liệu thẻ (`CardData`) khỏi hiển thị (`CardUI`).
- Luôn kiểm tra state của lượt trước khi thực thi hành động.
- Test trước, mỗi tính năng đi qua: thiết kế → duyệt → code → kiểm lỗi → refactor.

## Tiến độ

- [x] **Giai đoạn 0** - Nền móng: autoload, lưu/tải, chuyển cảnh, bộ test headless
- [x] **Giai đoạn 1.1** - Thẻ và bộ bài: `CardData`, `EffectData`, `CardInstance`, `Deck`
- [x] **Giai đoạn 1.2** - Trạng thái, `Combatant`, công thức sát thương, `EffectResolver`
- [x] **Giai đoạn 1.3a** - Dữ liệu quái, AI chọn chiêu, ý định (intent), `ResourceRegistry`, 3 quái mẫu
- [x] **Giai đoạn 1.3b** - `BattleState`, `BattleController` (lượt chơi, thắng/thua, tái lập theo seed), vùng "limbo" của `Deck`
- [ ] **Giai đoạn 1.3c** - Thẻ/nhân vật mẫu (`CharacterData`, `CardRegistry`), bot tự chơi hàng nghìn trận
- [ ] **Giai đoạn 2** - Hook/trigger, relic, potion, từ khóa nâng cao (X-cost, nâng cấp)
- [ ] **Giai đoạn 3** - UI chiến đấu (tay bài, kéo thả, ý định quái)
- [ ] **Giai đoạn 4** - Cấu trúc run: map, thưởng, cửa hàng, lửa trại, sự kiện
- [ ] **Giai đoạn 5** - Menu chính, chọn nhân vật, lưu/tiếp tục run, cài đặt
- [ ] **Giai đoạn 6** - Mở rộng nội dung: Act 2-3, nhân vật thứ hai
- [ ] **Giai đoạn 7** - Asset CC0, âm thanh, hiệu ứng
- [ ] **Giai đoạn 8** - Cân bằng bằng bot, đóng gói

Số test hiện tại: 218 (đều đạt).
