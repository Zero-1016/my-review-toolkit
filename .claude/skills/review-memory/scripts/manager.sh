#!/bin/bash
# 리뷰 메모리 통합 매니저 — 여러 프로젝트의 중앙 메모리를 한 도구에서 다룬다.
# 모든 경로 규칙은 lib.sh(SSOT)에서 가져온다.
#
# 사용법:
#   manager.sh list                      모든 프로젝트 메모리 나열
#   manager.sh path <프로젝트경로|slug>   메모리 폴더 경로 출력
#   manager.sh show <slug>               conventions + 최근 리뷰 요약 출력
#   manager.sh setup <프로젝트경로>       메모리 폴더 보장 생성
#   manager.sh export <프로젝트경로|slug> [출력디렉토리]
#   manager.sh import <아카이브.tar.gz> <프로젝트경로|slug>
#   manager.sh rm <slug> --yes           해당 프로젝트 메모리 삭제(확인 인자 필수)
set -e

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPTS/lib.sh"

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# slug 또는 프로젝트 경로를 메모리 폴더로 해석. (실제 경로를 slug보다 우선 해석)
resolve_dir() {
  local arg="$1" mem_root
  mem_root="$(rm_root)"
  if [ -d "$arg" ]; then
    rm_memory_dir "$arg"                  # 프로젝트 경로 ('.' 포함)
  elif [ -d "$mem_root/$arg" ]; then
    echo "$mem_root/$arg"                 # slug 직접 지정
  else
    echo "오류: '$arg' 는 slug도 프로젝트 경로도 아닙니다." >&2
    return 1
  fi
}

cmd_list() {
  local mem_root; mem_root="$(rm_root)"
  if [ ! -d "$mem_root" ]; then echo "(아직 메모리 없음: $mem_root)"; return; fi
  printf '%-32s %-7s %-12s %s\n' "PROJECT" "REVIEWS" "LAST" "ORIGIN"
  local d slug n last origin
  for d in "$mem_root"/*/; do
    [ -d "$d" ] || continue
    slug="$(basename "$d")"
    n=$(ls "$d"reviews/*.md 2>/dev/null | wc -l | tr -d ' ')
    last=$(ls "$d"reviews/*.md 2>/dev/null | sed 's#.*/##' | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)
    origin=$(cat "$d.origin" 2>/dev/null || echo "-")
    printf '%-32s %-7s %-12s %s\n' "$slug" "$n" "${last:--}" "$origin"
  done
}

cmd_path()  { resolve_dir "$1"; }

cmd_show() {
  local dir; dir="$(resolve_dir "$1")"
  echo "=== $dir ==="
  if [ -f "$dir/conventions.md" ]; then echo "--- conventions.md ---"; cat "$dir/conventions.md"; fi
  echo; echo "--- 최근 리뷰 ---"
  ls "$dir"/reviews/*.md 2>/dev/null | sed 's#.*/##' | sort | tail -5 || echo "(없음)"
}

cmd_setup()  { bash "$SCRIPTS/setup_memory.sh" "$1"; }
cmd_export() { python3 "$SCRIPTS/export_memory.py" "$@"; }
cmd_import() { python3 "$SCRIPTS/import_memory.py" "$@"; }

cmd_rm() {
  local slug="$1" confirm="$2" dir
  dir="$(resolve_dir "$slug")"
  if [ "$confirm" != "--yes" ]; then
    echo "삭제하려면 확인 인자가 필요합니다: manager.sh rm $slug --yes" >&2
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
