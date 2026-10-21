class_name ActionQueue
extends RefCounted
## Hàng đợi FIFO các hiệu ứng do trigger sinh ra. Xử lý theo thứ tự xếp hàng, KHÔNG đệ quy
## (giống Slay the Spire): hành động sinh ra hành động mới thì chúng xếp ở cuối hàng.

var _items: Array[QueuedAction] = []


func push(action: QueuedAction) -> void:
	_items.append(action)


## Lấy hành động ở đầu hàng; null nếu rỗng.
func pop() -> QueuedAction:
	return _items.pop_front() if not _items.is_empty() else null


func is_empty() -> bool:
	return _items.is_empty()


func size() -> int:
	return _items.size()


func clear() -> void:
	_items.clear()
