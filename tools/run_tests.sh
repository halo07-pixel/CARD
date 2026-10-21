#!/usr/bin/env bash
# Chạy test headless. Dùng: tools/run_tests.sh [--only=chuoi1,chuoi2]   (đặt GODOT=/đường/dẫn nếu cần)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Luôn import: cập nhật cache class_name (CardData, Deck...) khi có script mới.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- "$@"
