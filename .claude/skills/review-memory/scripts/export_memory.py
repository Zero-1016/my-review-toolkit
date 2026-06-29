#!/usr/bin/env python3
"""중앙 저장소에서 한 프로젝트의 리뷰 메모리를 단일 아카이브로 내보낸다.

메모리는 mrt 저장소 안 <mrt>/.review-memory/<project-slug>/ 에 모여 있다.

사용법:
    python3 export_memory.py <프로젝트 경로 | slug> [출력 디렉토리]

출력: <slug>-review-memory-<날짜>.tar.gz (기본: 현재 디렉토리)
"""
import datetime
import subprocess
import sys
import tarfile
from pathlib import Path

LIB = Path(__file__).parent / "lib.sh"


def _lib(func: str, *args: str) -> str:
    """lib.sh의 함수를 호출해 결과 문자열을 받는다 (경로 규칙 SSOT)."""
    cmd = ["bash", "-c", f'source "{LIB}"; {func} "$@"', "_", *args]
    return subprocess.check_output(cmd, text=True).strip()


def resolve_memory_dir(arg: str) -> Path:
    """인자를 slug 또는 프로젝트 경로로 받아 중앙 메모리 폴더를 돌려준다."""
    mem_root = Path(_lib("rm_root"))
    if "/" not in arg and (mem_root / arg).is_dir():
        return mem_root / arg              # slug 직접 지정
    if Path(arg).is_dir():
        return Path(_lib("rm_memory_dir", arg))  # 프로젝트 경로 → slug 해석
    raise SystemExit(f"오류: '{arg}' 는 slug도 프로젝트 경로도 아닙니다.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    mem = resolve_memory_dir(sys.argv[1])
    out_dir = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path.cwd()

    if not mem.is_dir():
        print(f"오류: {mem} 가 없습니다. 아직 리뷰 메모리가 없는 프로젝트입니다.")
        sys.exit(1)

    date = datetime.date.today().isoformat()
    out_path = out_dir / f"{mem.name}-review-memory-{date}.tar.gz"

    with tarfile.open(out_path, "w:gz") as tar:
        # 아카이브 안에서는 .review-memory/ 를 루트로 둔다 (import 시 대상명 무관하게 병합 가능)
        tar.add(mem, arcname=".review-memory")

    count = sum(1 for p in mem.rglob("*") if p.is_file())
    print(f"내보내기 완료: {out_path} (파일 {count}개)")


if __name__ == "__main__":
    main()
