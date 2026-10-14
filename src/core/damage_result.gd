class_name DamageResult
extends RefCounted
## Kết quả của một lần nhận sát thương (UI dùng để hiện số, relic dùng làm điều kiện).

var accepted: bool = false  ## false nếu bị từ chối (mục tiêu đã chết, số âm...)
var incoming: int = 0       ## sát thương đã tính xong, trước khi trừ giáp
var blocked: int = 0        ## phần giáp hấp thụ
var hp_lost: int = 0        ## máu thực sự mất
var killed: bool = false    ## đòn này làm mục tiêu chết
