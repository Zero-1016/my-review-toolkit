#!/usr/bin/env bash
# 문서 최신성 검사 — 스킬을 추가/변경했는데 문서(README.md·AGENTS.md)가 안 따라왔는지 본다.
# "코드가 바뀌었으니 무조건 문서 봐라"(노이즈) 대신, 실제 구조적 드리프트가 있을 때만 알린다.
#
# 두 가지로 쓴다:
#   - 훅(PostToolUse): stdin으로 tool JSON을 받아, git commit 성공 시 드리프트 있으면 신호.
#   - 수동:  doc-freshness.sh --report   → 사람이 읽게 출력, 드리프트 있으면 exit 1.
#
# 어떤 이유로든 판단이 안 서면 조용히 통과한다(커밋을 절대 막지 않는다).
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# 실제 드리프트 검사. 문제 목록을 stdout으로 내고, 드리프트가 있으면 return 1(없으면 0).
detect_drift() {
  local root="$1" issues=0 skill name count declared
  # 1) 모든 스킬이 README.md · AGENTS.md 양쪽에 언급됐는지.
  for skill in "$root"/skills/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    grep -qw "$name" "$root/README.md" 2>/dev/null || { echo "- 스킬 '$name' 이 README.md 에 없음"; issues=1; }
    grep -qw "$name" "$root/AGENTS.md"  2>/dev/null || { echo "- 스킬 '$name' 이 AGENTS.md 에 없음"; issues=1; }
  done
  # 2) AGENTS.md 의 "스킬 N종" 숫자가 실제 스킬 폴더 수와 맞는지.
  count="$(find "$root"/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  declared="$(grep -oE '스킬 [0-9]+종' "$root/AGENTS.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)"
  if [ -n "$declared" ] && [ "$declared" != "$count" ]; then
    echo "- AGENTS.md 는 '스킬 ${declared}종'이라는데 실제 스킬은 ${count}개"; issues=1
  fi
  return "$issues"
}

# --- 수동 리포트 모드 ---
if [ "${1:-}" = "--report" ]; then
  if drift="$(detect_drift "$PROJECT_DIR")"; then
    echo "문서 최신 상태 ✓ (드리프트 없음)"; exit 0
  else
    echo "문서 갱신 필요:"; echo "$drift"; exit 1
  fi
fi

# --- 훅 모드 ---
command -v jq >/dev/null 2>&1 || exit 0
INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
[ "$TOOL" = "Bash" ] || exit 0
case "$CMD" in *"git commit"*) : ;; *) exit 0 ;; esac
case "$CMD" in *"--dry-run"*) exit 0 ;; esac

cd "$PROJECT_DIR" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

if drift="$(detect_drift "$PROJECT_DIR")"; then
  exit 0   # 드리프트 없음 → 침묵
fi

CONTEXT="문서 드리프트 감지 — 코드와 문서가 어긋난다. 아래를 보고 README.md/AGENTS.md를 갱신하라(불필요하면 그냥 넘어가도 된다):
$drift"
jq -cn --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
