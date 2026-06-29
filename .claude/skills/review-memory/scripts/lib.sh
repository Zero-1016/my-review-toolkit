#!/bin/bash
# 리뷰 메모리 공통 코어 (Single Source of Truth).
# 경로/위치 규칙은 전부 여기 한 곳에만 둔다 — setup/export/import/manager가 source 해서 쓴다.
# 직접 실행하는 파일이 아니라 source 전용이다.
#
# 저장 모델: 모든 프로젝트의 리뷰 메모리를 mrt 저장소 안에 모은다.
#   <mrt>/.review-memory/<project-slug>/{context.md, conventions.md, reviews/, .origin}
# 대상 프로젝트에는 아무 파일도 만들지 않는다.

# mrt 저장소 루트. 이 스크립트의 물리 경로(심링크 해석)에서 역추적한다.
# 스킬은 ~/.claude/skills/review-memory -> <mrt>/.claude/skills/review-memory 로 심링크 등록되므로,
# scripts/ 기준 4단계 상위가 mrt 루트다.
rm_mrt_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"  # .../review-memory/scripts (물리경로)
  (cd "$script_dir/../../../.." && pwd -P)
}

# 중앙 메모리 루트.
rm_root() {
  echo "$(rm_mrt_root)/.review-memory"
}

# 대상 프로젝트의 git 루트(없으면 경로 자체).
rm_project_root() {
  local p="${1:-.}"
  ( cd "$p" 2>/dev/null && (git rev-parse --show-toplevel 2>/dev/null || pwd -P) )
}

# 프로젝트 slug = git 루트 basename. basename 충돌(서로 다른 origin)이면 짧은 해시 접미사.
rm_slug() {
  local proot base mem_root candidate origin_file
  proot="$(rm_project_root "${1:-.}")"
  base="$(basename "$proot")"
  mem_root="$(rm_root)"
  candidate="$mem_root/$base"
  origin_file="$candidate/.origin"
  # 같은 이름 폴더가 있는데 origin이 다르면 = 충돌 → 경로 해시 접미사로 분리.
  if [ -d "$candidate" ] && [ -f "$origin_file" ] && [ "$(cat "$origin_file" 2>/dev/null)" != "$proot" ]; then
    local hash
    hash="$(printf '%s' "$proot" | cksum | cut -d' ' -f1)"
    echo "${base}-${hash}"
  else
    echo "$base"
  fi
}

# 대상 프로젝트의 중앙 메모리 폴더 절대경로.
rm_memory_dir() {
  echo "$(rm_root)/$(rm_slug "${1:-.}")"
}
