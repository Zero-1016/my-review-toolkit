#!/usr/bin/env python3
"""export_memory.py 로 만든 아카이브를 중앙 저장소의 한 프로젝트로 병합한다.

메모리는 mrt 저장소 안 <mrt>/.review-memory/<project-slug>/ 에 모인다.

사용법:
    python3 import_memory.py <아카이브.tar.gz> <대상 프로젝트 경로 | slug>

병합 규칙:
- reviews/ 안의 파일: 같은 이름이 이미 있으면 건너뜀 (기존 기록 보호)
- conventions.md: 가져온 내용이 기존에 없으면 "## Imported <날짜>" 섹션으로 뒤에 추가
"""
import datetime
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

SCRIPTS = Path(__file__).parent
LIB = SCRIPTS / "lib.sh"


def _lib(func: str, *args: str) -> str:
    cmd = ["bash", "-c", f'source "{LIB}"; {func} "$@"', "_", *args]
    return subprocess.check_output(cmd, text=True).strip()


def resolve_dest(arg: str) -> Path:
    """대상(slug 또는 프로젝트 경로)의 중앙 메모리 폴더를 보장 생성하고 돌려준다."""
    mem_root = Path(_lib("rm_root"))
    if Path(arg).is_dir():
        # 실제 프로젝트 경로 → setup_memory.sh 로 폴더/템플릿/.origin 보장
        subprocess.run(
            ["bash", str(SCRIPTS / "setup_memory.sh"), arg],
            check=True, capture_output=True,
        )
        return Path(_lib("rm_memory_dir", arg))
    # slug 직접 지정 (대응하는 실제 프로젝트가 이 머신에 없을 수 있음)
    dest = mem_root / arg
    (dest / "reviews").mkdir(parents=True, exist_ok=True)
    return dest


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    archive = Path(sys.argv[1]).resolve()
    dest = resolve_dest(sys.argv[2])

    with tempfile.TemporaryDirectory() as tmp:
        with tarfile.open(archive) as tar:
            try:
                tar.extractall(tmp, filter="data")
            except TypeError:  # Python < 3.12: filter 미지원
                tar.extractall(tmp)
        src = Path(tmp) / ".review-memory"
        if not src.is_dir():
            print("오류: 아카이브 안에 .review-memory/ 가 없습니다.")
            sys.exit(1)

        copied, skipped = 0, 0
        src_reviews = src / "reviews"
        if src_reviews.is_dir():
            (dest / "reviews").mkdir(parents=True, exist_ok=True)
            for f in sorted(src_reviews.iterdir()):
                target = dest / "reviews" / f.name
                if target.exists():
                    skipped += 1
                else:
                    shutil.copy2(f, target)
                    copied += 1

        src_conv = src / "conventions.md"
        conv_merged = False
        if src_conv.is_file():
            imported = src_conv.read_text(encoding="utf-8").strip()
            dest_conv = dest / "conventions.md"
            existing = dest_conv.read_text(encoding="utf-8") if dest_conv.exists() else ""
            if imported and imported not in existing:
                date = datetime.date.today().isoformat()
                with dest_conv.open("a", encoding="utf-8") as f:
                    f.write(f"\n\n## Imported {date} ({archive.name})\n\n{imported}\n")
                conv_merged = True

    print(f"가져오기 완료: 리뷰 {copied}개 복사, {skipped}개 건너뜀 (이미 존재)"
          + (", conventions.md 병합됨" if conv_merged else ""))


if __name__ == "__main__":
    main()
