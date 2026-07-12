#!/usr/bin/env bash
# 리뷰 스킬을 여러 에이전트에 설치한다 (정본 1개 + 링크 N개).
#   - ~/.claude/skills/<name>   → Claude Code
#   - ~/.agents/skills/<name>   → Codex · Gemini CLI · Copilot CLI 공통 발견 경로
#   - ~/.local/bin/mrt-review   → 스킬 본문이 부르는 PATH 런처
# 멱등(idempotent): 재실행해도 안전하다. 비-심링크 실파일과 충돌하면 덮어쓰지 않고 경고만 낸다.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILLS=(branch-review changelog local-code-review pr-review review-memory)

# 심링크 보장: 이미 올바른 링크면 건너뛰고, 깨졌거나 다른 링크면 교체.
# 비-심링크 실파일/디렉토리가 있으면 보존하고 경고만 낸다.
link() {  # link <target> <linkpath>
  local target="$1" linkpath="$2"
  if [ -L "$linkpath" ]; then
    [ "$(readlink "$linkpath")" = "$target" ] && return 0
    ln -sfn "$target" "$linkpath"; echo "  교체: $linkpath → $target"; return 0
  fi
  if [ -e "$linkpath" ]; then
    echo "  건너뜀(실파일 존재, 보존): $linkpath" >&2; return 0
  fi
  ln -sfn "$target" "$linkpath"; echo "  링크: $linkpath → $target"
}

echo "정본 저장소: $REPO"

for base in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  mkdir -p "$base"
  echo "[$base]"
  for s in "${SKILLS[@]}"; do link "$REPO/skills/$s" "$base/$s"; done
done

echo "[$HOME/.local/bin]"
mkdir -p "$HOME/.local/bin"
chmod +x "$REPO/skills/review-memory/scripts/mrt-review"
link "$REPO/skills/review-memory/scripts/mrt-review" "$HOME/.local/bin/mrt-review"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "주의: ~/.local/bin 이 PATH에 없다. shell rc에 추가하세요:"
     echo '  export PATH="$HOME/.local/bin:$PATH"';;
esac

echo "완료. 확인: mrt-review list"
