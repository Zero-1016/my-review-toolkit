#!/bin/bash
# .review-memory 폴더를 준비하고 git 추적에서 제외한다.
# .git/info/exclude는 로컬 전용이라 팀 공유 .gitignore를 건드리지 않고도
# 메모리가 절대 커밋/푸시되지 않게 보장한다.
#
# 사용법: setup_memory.sh [프로젝트 경로]   (생략 시 현재 디렉토리)
# 출력: 메모리 폴더의 절대 경로
set -e

ROOT="${1:-.}"
cd "$ROOT"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

MEM="$ROOT/.review-memory"
mkdir -p "$MEM/reviews"
[ -f "$MEM/conventions.md" ] || cat > "$MEM/conventions.md" <<'EOF'
# 리뷰 컨벤션 / 반복 패턴

이 프로젝트의 리뷰에서 반복적으로 발견되는 패턴, 팀 컨벤션, 주의할 점을 누적하는 파일.
리뷰 스킬이 시작할 때 읽고, 끝날 때 새로 발견한 패턴을 추가한다.
EOF

EXCLUDE_FILE="$ROOT/.git/info/exclude"
if [ -d "$ROOT/.git" ]; then
  mkdir -p "$ROOT/.git/info"
  if ! grep -qx '\.review-memory/' "$EXCLUDE_FILE" 2>/dev/null; then
    echo '.review-memory/' >> "$EXCLUDE_FILE"
  fi
fi

echo "$MEM"
