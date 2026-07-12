#!/bin/bash
# 리뷰 메모리 통합 매니저 — 여러 프로젝트의 중앙 메모리를 한 도구에서 다룬다.
# 모든 경로 규칙은 lib.sh(SSOT)에서 가져온다.
#
# 사용법:
#   manager.sh list                              모든 프로젝트 메모리 나열(모노레포 scope는 들여쓰기)
#   manager.sh path <프로젝트경로|slug> [--scope <s>]   메모리 폴더 경로 출력
#   manager.sh show <slug> [--scope <s>]         conventions + 최근 리뷰 요약 출력
#   manager.sh setup <프로젝트경로> [--scope <s>] 메모리 폴더 보장 생성
#   manager.sh export <프로젝트경로|slug> [출력디렉토리]
#   manager.sh import <아카이브.tar.gz> <프로젝트경로|slug>
#   manager.sh rm <slug> [--scope <s>] --yes     메모리 삭제(--scope면 그 패키지만; 확인 인자 필수)
set -e

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPTS/lib.sh"

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# slug 또는 프로젝트 경로를 (repo 계층) 메모리 폴더로 해석. (실제 경로를 slug보다 우선 해석)
# 두 번째 인자로 scope를 주면 그 패키지 폴더(<repo>/scopes/<scope>)를 돌려준다.
resolve_dir() {
  local arg="$1" scope="${2:-}" mem_root base
  mem_root="$(rm_root)"
  if [ -d "$arg" ]; then
    base="$(rm_repo_dir "$arg")"          # 프로젝트 경로 ('.' 포함)
  elif [ -d "$mem_root/$arg" ]; then
    base="$mem_root/$arg"                 # slug 직접 지정
  else
    echo "오류: '$arg' 는 slug도 프로젝트 경로도 아닙니다." >&2
    return 1
  fi
  if [ -n "$scope" ]; then
    local s; s="$(rm_sanitize_scope "$scope")" || { echo "오류: 잘못된 scope 이름: '$scope'" >&2; return 1; }
    echo "$base/scopes/$s"
  else
    echo "$base"
  fi
}

# 인자에서 --scope <s> / --scope=<s> 를 뽑아 SCOPE_ARG 에 담고, 나머지를 REST_ARGS 배열에 남긴다.
extract_scope() {
  SCOPE_ARG=""; REST_ARGS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --scope)   SCOPE_ARG="${2:-}"; shift 2;;
      --scope=*) SCOPE_ARG="${1#--scope=}"; shift;;
      *)         REST_ARGS+=("$1"); shift;;
    esac
  done
}

cmd_list() {
  local mem_root; mem_root="$(rm_root)"
  if [ ! -d "$mem_root" ]; then echo "(아직 메모리 없음: $mem_root)"; return; fi
  printf '%-32s %-7s %-12s %s\n' "PROJECT" "REVIEWS" "LAST" "ORIGIN"
  local d slug n last origin sd sslug sn slast
  for d in "$mem_root"/*/; do
    [ -d "$d" ] || continue
    slug="$(basename "$d")"
    n=$(ls "$d"reviews/*.md 2>/dev/null | wc -l | tr -d ' ')
    last=$(ls "$d"reviews/*.md 2>/dev/null | sed 's#.*/##' | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
    origin=$(cat "$d.origin" 2>/dev/null || echo "-")
    printf '%-32s %-7s %-12s %s\n' "$slug" "$n" "${last:--}" "$origin"
    # 모노레포 scope(패키지)는 들여쓰기해서 하위에 표시.
    [ -d "${d}scopes" ] || continue
    for sd in "${d}scopes"/*/; do
      [ -d "$sd" ] || continue
      sslug="$(basename "$sd")"
      sn=$(ls "$sd"reviews/*.md 2>/dev/null | wc -l | tr -d ' ')
      slast=$(ls "$sd"reviews/*.md 2>/dev/null | sed 's#.*/##' | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
      printf '%-32s %-7s %-12s %s\n' "  └ $sslug" "$sn" "${slast:--}" "(scope)"
    done
  done
}

cmd_path()  { extract_scope "$@"; resolve_dir "${REST_ARGS[0]:-.}" "$SCOPE_ARG"; }

cmd_show() {
  extract_scope "$@"
  local dir; dir="$(resolve_dir "${REST_ARGS[0]:-.}" "$SCOPE_ARG")"
  echo "=== $dir ==="
  if [ -f "$dir/conventions.md" ]; then echo "--- conventions.md ---"; cat "$dir/conventions.md"; fi
  echo; echo "--- 최근 리뷰 ---"
  ls "$dir"/reviews/*.md 2>/dev/null | sed 's#.*/##' | sort | tail -5 || echo "(없음)"
}

cmd_setup()  { bash "$SCRIPTS/setup_memory.sh" "$@"; }
cmd_export() { python3 "$SCRIPTS/export_memory.py" "$@"; }
cmd_import() { python3 "$SCRIPTS/import_memory.py" "$@"; }

cmd_rm() {
  extract_scope "$@"
  local slug="${REST_ARGS[0]:-}" confirm="${REST_ARGS[1]:-}" dir
  dir="$(resolve_dir "$slug" "$SCOPE_ARG")"
  if [ "$confirm" != "--yes" ]; then
    echo "삭제하려면 확인 인자가 필요합니다: manager.sh rm $slug ${SCOPE_ARG:+--scope $SCOPE_ARG }--yes" >&2
    echo "대상: $dir" >&2
    return 1
  fi
  rm -rf "$dir"
  echo "삭제 완료: $dir"
}

case "${1:-}" in
  list)   shift; cmd_list "$@";;
  path)   shift; cmd_path "$@";;
  show)   shift; cmd_show "$@";;
  setup)  shift; cmd_setup "$@";;
  export) shift; cmd_export "$@";;
  import) shift; cmd_import "$@";;
  rm)     shift; cmd_rm "$@";;
  ""|-h|--help|help) usage;;
  *) echo "알 수 없는 명령: $1" >&2; usage; exit 1;;
esac
