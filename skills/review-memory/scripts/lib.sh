#!/bin/bash
# 리뷰 메모리 공통 코어 (Single Source of Truth).
# 경로/위치 규칙은 전부 여기 한 곳에만 둔다 — setup/export/import/manager가 source 해서 쓴다.
# 직접 실행하는 파일이 아니라 source 전용이다.
#
# 저장 모델: 모든 프로젝트의 리뷰 메모리를 mrt 저장소 안에 모은다.
#   <mrt>/.review-memory/<project-slug>/{context.md, conventions.md, reviews/, .origin}
# 대상 프로젝트에는 아무 파일도 만들지 않는다.

# mrt 저장소 루트. 설치 위치/심링크 구조와 무관하게 찾는다(에이전트 공용).
#  1) $MRT_HOME 가 있으면 최우선(명시적 override).
#  2) 없으면 이 스크립트의 물리 경로(심링크 해석)에서 위로 올라가며
#     skills/review-memory 를 품은 디렉토리(= mrt 루트)를 탐색한다.
rm_mrt_root() {
  if [ -n "${MRT_HOME:-}" ]; then echo "$MRT_HOME"; return; fi
  local d
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"  # .../skills/review-memory/scripts (물리경로)
  while [ "$d" != "/" ]; do
    [ -d "$d/skills/review-memory" ] && { echo "$d"; return; }
    d="$(dirname "$d")"
  done
  return 1
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

# scope 이름을 한 경로 세그먼트로 안전하게 만든다. '/'→'-', 허용문자[A-Za-z0-9._-] 외 제거,
# 빈 값/'.'/'..'/'..'포함은 거부(디렉토리 탈출 방지). 성공 시 새니타이즈된 이름 출력.
rm_sanitize_scope() {
  local s="${1//\//-}"                         # 슬래시 → 하이픈 (packages/ui → packages-ui)
  s="$(printf '%s' "$s" | tr -cd 'A-Za-z0-9._-')"
  case "$s" in ''|.|..|*..*) return 1;; esac
  printf '%s\n' "$s"
}

# 대상 프로젝트의 repo 공유(계층) 메모리 폴더 — scope와 무관하게 항상 <repo>.
rm_repo_dir() {
  echo "$(rm_root)/$(rm_slug "${1:-.}")"
}

# 대상 프로젝트의 중앙 메모리 폴더 절대경로.
# 두 번째 인자로 scope를 주면 모노레포 패키지 계층(<repo>/scopes/<scope>), 아니면 <repo>.
rm_memory_dir() {
  local base scope
  base="$(rm_repo_dir "${1:-.}")"
  scope="${2:-}"
  if [ -n "$scope" ]; then
    scope="$(rm_sanitize_scope "$scope")" || { echo "오류: 잘못된 scope 이름: '$2'" >&2; return 1; }
    echo "$base/scopes/$scope"
  else
    echo "$base"
  fi
}
