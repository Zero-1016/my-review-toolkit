#!/bin/bash
# 대상 프로젝트의 중앙 리뷰 메모리 폴더를 준비한다.
# 메모리는 대상 repo가 아니라 mrt 저장소 안에 모인다:
#   <mrt>/.review-memory/<project-slug>/
# 따라서 대상 프로젝트에는 아무 파일도 만들지 않는다(누출 위험 없음).
#
# 사용법: setup_memory.sh [프로젝트 경로]   (생략 시 현재 디렉토리)
# 출력: 첫 줄 FIRST_REVIEW=0|1, 마지막 줄에 메모리 폴더의 절대 경로
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

PROJECT="${1:-.}"
PROOT="$(rm_project_root "$PROJECT")"
MEM="$(rm_memory_dir "$PROJECT")"

# 첫 리뷰 = 중앙 폴더가 없거나, 과거 리뷰 기록(reviews/*.md)이 아직 없을 때.
if [ -d "$MEM" ] && ls "$MEM"/reviews/*.md >/dev/null 2>&1; then
  FIRST_REVIEW=0
else
  FIRST_REVIEW=1
fi

mkdir -p "$MEM/reviews"

# .origin: 이 메모리가 어떤 실제 프로젝트의 것인지 추적/충돌 식별용.
[ -f "$MEM/.origin" ] || printf '%s\n' "$PROOT" > "$MEM/.origin"

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

# 첫 줄에 첫-리뷰 신호, 마지막 줄에 메모리 경로(스킬이 경로로 사용).
echo "FIRST_REVIEW=$FIRST_REVIEW"
echo "$MEM"
