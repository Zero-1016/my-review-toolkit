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
# CLAUDE.local.md(개인용, gitignored)가 없으면 = 이 프로젝트 첫 리뷰 신호.
# 이 파일은 매 세션 Claude 컨텍스트에 자동 로드되어 "리뷰 메모리 있음 + 먼저 읽으라"는 포인터가 된다.
LOCAL_MD="$ROOT/CLAUDE.local.md"
# 첫 리뷰 = CLAUDE.local.md도 없고, 과거 리뷰 기록(reviews/*.md)도 없을 때.
# (CLAUDE.local.md 도입 이전부터 쓰던 기존 프로젝트가 첫 리뷰로 오인되지 않게 reviews도 함께 본다.)
if [ -f "$LOCAL_MD" ] || ls "$MEM"/reviews/*.md >/dev/null 2>&1; then
  FIRST_REVIEW=0
else
  FIRST_REVIEW=1
fi

mkdir -p "$MEM/reviews"
[ -f "$MEM/conventions.md" ] || cat > "$MEM/conventions.md" <<'EOF'
# 리뷰 컨벤션 / 반복 패턴

이 프로젝트의 리뷰에서 반복적으로 발견되는 패턴, 팀 컨벤션, 주의할 점을 누적하는 파일.
리뷰 스킬이 시작할 때 읽고, 끝날 때 새로 발견한 패턴을 추가한다.
EOF

[ -f "$MEM/context.md" ] || cat > "$MEM/context.md" <<'EOF'
# 리뷰 컨텍스트 (사용자 제공)

리뷰 전에 미리 알아두어야 할 배경을 사용자가 직접 등록하는 파일.
리뷰 스킬이 시작할 때 conventions.md와 함께 읽는다.

## 프로젝트 배경
(도메인, 아키텍처, 기술적 제약 등 — 비어 있으면 무시)

## 리뷰 시 중점 사항
(예: 성능에 민감한 모듈, 이번 마일스톤의 우선순위)

## 팀 규칙
(코드 컨벤션 문서 링크, 리뷰 톤, 머지 기준 등)

## 리뷰 필수 체크리스트 (놓치면 안 되는 것)
<!-- 비어 있으면 첫 리뷰 때 스킬이 "이 프로젝트에서 특히 중요한 게 뭔지" 물어보고 채운다. -->
<!-- 유형별로 핵심이 다르다: 디자인시스템/라이브러리 = 공개 API·버저닝(changeset)·a11y / 서비스 = 기존 동작 회귀·런타임 에러·로딩/에러 상태·데이터 정합성. -->
<!-- 모노레포면 경로별(packages/* vs apps/*)로 나눠 적는다. 각 항목은 매 리뷰마다 PR과 대조해 통과 검사하는 하드 게이트다. -->
EOF

# CLAUDE.local.md 포인터 생성(없을 때만). 체크리스트 본문은 .review-memory가 SSOT이고 여기엔 포인터만 둔다.
[ -f "$LOCAL_MD" ] || cat > "$LOCAL_MD" <<'EOF'
# 리뷰용 로컬 메모 (개인용 · gitignored)

이 프로젝트는 리뷰 메모리를 사용합니다.
PR·코드 리뷰 전에 다음을 먼저 읽으세요 (셸 cat 말고 Read 도구로):
- `.review-memory/context.md` — 프로젝트 배경 + **리뷰 필수 체크리스트(하드 게이트)**
- `.review-memory/conventions.md` — 반복 패턴/컨벤션
EOF

EXCLUDE_FILE="$ROOT/.git/info/exclude"
if [ -d "$ROOT/.git" ]; then
  mkdir -p "$ROOT/.git/info"
  for pat in '\.review-memory/' 'CLAUDE\.local\.md'; do
    grep -qx "$pat" "$EXCLUDE_FILE" 2>/dev/null || echo "${pat//\\/}" >> "$EXCLUDE_FILE"
  done
fi

# 첫 줄에 첫-리뷰 신호, 마지막 줄에 메모리 경로(스킬이 경로로 사용).
echo "FIRST_REVIEW=$FIRST_REVIEW"
echo "$MEM"
