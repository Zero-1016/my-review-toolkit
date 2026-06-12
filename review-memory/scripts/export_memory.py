#!/usr/bin/env python3
"""프로젝트의 .review-memory 폴더를 단일 아카이브로 내보낸다.

사용법:
    python3 export_memory.py <프로젝트 경로> [출력 디렉토리]

출력: <프로젝트명>-review-memory-<날짜>.tar.gz (기본: 현재 디렉토리)
"""
import datetime
import subprocess
import sys
import tarfile
from pathlib import Path


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    project = Path(sys.argv[1]).resolve()
    out_dir = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path.cwd()

    # git 루트를 기준으로 찾는다 (하위 폴더에서 실행해도 동작하도록)
    try:
        root = Path(
            subprocess.check_output(
                ["git", "rev-parse", "--show-toplevel"], cwd=project, text=True
            ).strip()
        )
    except subprocess.CalledProcessError:
        root = project

    mem = root / ".review-memory"
    if not mem.is_dir():
        print(f"오류: {mem} 가 없습니다. 아직 리뷰 메모리가 없는 프로젝트입니다.")
        sys.exit(1)

    date = datetime.date.today().isoformat()
    out_path = out_dir / f"{root.name}-review-memory-{date}.tar.gz"

    with tarfile.open(out_path, "w:gz") as tar:
        # 아카이브 안에서는 .review-memory/ 를 루트로 둔다 (import 시 프로젝트명 무관하게 병합 가능)
        tar.add(mem, arcname=".review-memory")

    count = sum(1 for p in mem.rglob("*") if p.is_file())
    print(f"내보내기 완료: {out_path} (파일 {count}개)")


if __name__ == "__main__":
    main()
