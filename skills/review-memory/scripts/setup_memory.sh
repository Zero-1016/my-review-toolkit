#!/bin/bash
# 대상 프로젝트의 중앙 리뷰 메모리 폴더를 준비한다.
# 메모리는 대상 repo가 아니라 mrt 저장소 안에 모인다:
#   <mrt>/.review-memory/<project-slug>/                 ← repo 공유 계층
#   <mrt>/.review-memory/<project-slug>/scopes/<scope>/  ← 모노레포 패키지 계층(선택)
# 따라서 대상 프로젝트에는 아무 파일도 만들지 않는다(누출 위험 없음).
#
# 사용법: setup_memory.sh [프로젝트 경로] [--scope <scope>]   (경로 생략 시 현재 디렉토리)
# 출력:
#   1줄: FIRST_REVIEW=0|1        (주 메모리에 과거 리뷰가 있는지)
#   2줄: SHARED_MEM=<repo 공유 폴더>   (scope를 줬을 때만 출력 — 스킬이 공유 계층도 로드)
#   끝줄: 주 메모리 폴더 절대경로 (scope 있으면 scope 폴더, 없으면 repo 폴더)
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

# 인자 파싱: 위치인자=프로젝트경로, --scope <s>
PROJECT="."
SCOPE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope)   SCOPE="${2:-}"; shift 2;;
    --scope=*) SCOPE="${1#--scope=}"; shift;;
    *)         PROJECT="$1"; shift;;
  esac
done

PROOT="$(rm_project_root "$PROJECT")"
REPO_MEM="$(rm_repo_dir "$PROJECT")"
if [ -n "$SCOPE" ]; then
  MEM="$(rm_memory_dir "$PROJECT" "$SCOPE")"   # 잘못된 scope면 여기서 실패
else
  MEM="$REPO_MEM"
fi

# repo 공유 계층: 항상 보장한다(scope 리뷰라도 공유 컨벤션은 여기서 로드).
mkdir -p "$REPO_MEM/reviews"
[ -f "$REPO_MEM/.origin" ] || printf '%s\n' "$PROOT" > "$REPO_MEM/.origin"

[ -f "$REPO_MEM/conventions.md" ] || cat > "$REPO_MEM/conventions.md" <<'EOF'
# 리뷰 컨벤션 / 반복 패턴 (repo 공유)

이 저장소 전반에서 반복적으로 발견되는 패턴, 팀 컨벤션, 주의할 점을 누적하는 파일.
모노레포라면 여러 패키지에 공통으로 적용되는 규칙만 여기에 두고,
특정 패키지에만 해당하는 규칙은 scopes/<패키지>/conventions.md 에 둔다.
리뷰 스킬이 시작할 때 읽고, 끝날 때 새로 발견한 패턴을 추가한다.
EOF

[ -f "$REPO_MEM/context.md" ] || cat > "$REPO_MEM/context.md" <<'EOF'
# 리뷰 컨텍스트 (사용자 제공 · repo 공유)

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
<!-- 모노레포면 repo 전반 공통 체크만 여기 두고, 패키지 고유 체크는 scopes/<패키지>/context.md 에 둔다. 각 항목은 매 리뷰마다 PR과 대조해 통과 검사하는 하드 게이트다. -->
EOF

# scope(패키지) 계층: --scope 를 줬을 때만 보장한다.
if [ -n "$SCOPE" ]; then
  SNAME="$(basename "$MEM")"
  mkdir -p "$MEM/reviews"
  [ -f "$MEM/conventions.md" ] || cat > "$MEM/conventions.md" <<EOF
# 리뷰 컨벤션 / 반복 패턴 — 패키지 '$SNAME'

이 패키지(scope)에만 해당하는 반복 패턴/컨벤션을 누적하는 파일.
여러 패키지에 공통인 규칙은 여기가 아니라 repo 공유(../../conventions.md)에 둔다.
EOF
  [ -f "$MEM/context.md" ] || cat > "$MEM/context.md" <<EOF
# 리뷰 컨텍스트 — 패키지 '$SNAME'

이 패키지 고유의 배경/중점 사항/체크리스트. repo 공유 context.md와 함께 읽힌다.

## 패키지 배경
(이 패키지의 역할·공개 API·의존 관계 — 비어 있으면 무시)

## 리뷰 시 중점 사항
(이 패키지에서 특히 조심할 것)

## 리뷰 필수 체크리스트 (이 패키지 한정, 놓치면 안 되는 것)
<!-- 비어 있으면 이 패키지 첫 리뷰 때 스킬이 물어보고 채운다. repo 공유 체크와 별개로 검사한다. -->
EOF
fi

# 첫 리뷰 = 주 메모리(scope 또는 repo)에 과거 리뷰 기록이 아직 없을 때.
if ls "$MEM"/reviews/*.md >/dev/null 2>&1; then
  FIRST_REVIEW=0
else
  FIRST_REVIEW=1
fi

echo "FIRST_REVIEW=$FIRST_REVIEW"
[ -n "$SCOPE" ] && echo "SHARED_MEM=$REPO_MEM"
echo "$MEM"
