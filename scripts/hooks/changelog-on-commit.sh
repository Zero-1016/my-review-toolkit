#!/usr/bin/env bash
# PostToolUse 훅: git commit 성공 직후 changelog 스킬(add)을 호출하도록 에이전트에 신호를 준다.
#
# 동작:
#   - Bash 도구로 `git commit` 이 실행됐고, 그 결과 새 커밋이 생겼을 때만 신호를 낸다.
#   - CHANGELOG.md의 last-processed 마커와 HEAD를 비교해, 이미 반영됐거나 커밋이 실패한
#     경우(마커 == HEAD)는 조용히 넘어간다.
#   - 체인지로그 자신의 커밋(docs(changelog)/chore(release))은 건너뛴다(무한루프 방지).
#
# 신호 방식: stdout 에 hookSpecificOutput.additionalContext 를 실어 에이전트가 스킬을 부르게 한다.
# 어떤 이유로든 판단이 안 서면 exit 0 으로 조용히 통과한다(커밋을 절대 막지 않는다).
set -euo pipefail

# jq 없으면 조용히 통과 (훅은 편의 기능이지 필수가 아니다)
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

[ "$TOOL" = "Bash" ] || exit 0
# `git commit` 호출이 아니면 무시 (--dry-run 은 커밋을 안 만드니 제외)
case "$CMD" in
  *"git commit"*) : ;;
  *) exit 0 ;;
esac
case "$CMD" in *"--dry-run"*) exit 0 ;; esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CHANGELOG="$PROJECT_DIR/CHANGELOG.md"
[ -f "$CHANGELOG" ] || exit 0

cd "$PROJECT_DIR" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || true)"
[ -n "$HEAD_SHA" ] || exit 0

# 이미 기록된 커밋이거나 커밋이 실패해 HEAD가 안 움직였으면 통과
MARKER="$(grep -oE 'last-processed: [0-9a-f]+' "$CHANGELOG" | awk '{print $2}' | head -1 || true)"
[ "$MARKER" = "$HEAD_SHA" ] && exit 0

# 체인지로그 자신의 커밋이면 통과 (무한루프 방지)
SUBJECT="$(git log -1 --format='%s' 2>/dev/null || true)"
case "$SUBJECT" in
  "docs(changelog)"*|"chore(release)"*) exit 0 ;;
esac

CONTEXT="방금 커밋($HEAD_SHA)이 생성됐다. changelog 스킬을 호출해 CHANGELOG.md의 [Unreleased]에 이 변경을 개발자가 아니어도 이해할 수 있는 쉬운 한 줄 문장으로 추가하고 last-processed 마커를 갱신하라. (내부 정리 커밋이라 기록할 게 없으면 마커만 전진시키면 된다.)"

jq -cn --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
