---
name: review-memory
description: 프로젝트별 리뷰 메모리(.review-memory/)를 관리한다 — 내보내기(export), 가져오기(import), 조회, 초기화. 사용자가 리뷰 메모리/리뷰 기록을 백업하거나, 다른 머신·프로젝트로 옮기거나, "리뷰 메모리 내보내줘/가져와줘", "리뷰 기록 보여줘", "지금까지 리뷰에서 발견된 패턴 정리해줘" 같은 요청을 하면 반드시 이 스킬을 사용한다. pr-review와 local-code-review 스킬이 사용하는 공용 스크립트도 여기에 있다.
---

# Review Memory 관리

각 프로젝트의 `.review-memory/` 폴더에 쌓인 리뷰 기록을 관리하는 스킬.
이 폴더는 `pr-review`, `local-code-review` 스킬이 자동으로 만들고 채운다.

## 메모리 구조

```
<프로젝트>/.review-memory/      # .git/info/exclude에 등록됨 → 절대 커밋되지 않음
├── conventions.md              # 반복 패턴, 팀 컨벤션, 주의점 누적
└── reviews/
    └── <날짜>-<대상>.md        # 예: 2026-06-12-pr-123.md, 2026-06-12-local-feat-login.md
```

## 작업별 방법

모든 스크립트는 이 스킬의 `scripts/` 폴더에 있다.

> 환경 주의: 이 머신의 rtk 훅이 셸 명령을 재작성하므로, 이 스킬의 모든 셸 명령에는
> `RTK_SKIP=1` 접두어를 붙인다 — 훅 래퍼가 마커를 인식해 원본 명령을 그대로 실행한다.

### 초기화 / 폴더 보장

```bash
RTK_SKIP=1 bash ~/.claude/skills/review-memory/scripts/setup_memory.sh <프로젝트경로>
```

폴더 생성 + `.git/info/exclude` 등록까지 한 번에 처리한다. 이미 있으면 그대로 둔다.

### 내보내기 (export)

```bash
RTK_SKIP=1 python3 ~/.claude/skills/review-memory/scripts/export_memory.py <프로젝트경로> [출력디렉토리]
```

`<프로젝트명>-review-memory-<날짜>.tar.gz` 하나로 묶인다. 백업, 머신 이전, 동료 공유 용도.

### 가져오기 (import)

```bash
RTK_SKIP=1 python3 ~/.claude/skills/review-memory/scripts/import_memory.py <아카이브.tar.gz> <대상프로젝트경로>
```

병합 방식이라 안전하다: 이미 있는 리뷰 파일은 건너뛰고, conventions.md는 새 내용만 뒤에 추가된다. 덮어쓰지 않는다.

### 조회

사용자가 "리뷰 기록 보여줘", "이 프로젝트에서 자주 나온 이슈가 뭐였지?" 같은 요청을 하면
`conventions.md`와 `reviews/` 의 최근 파일들을 읽고 요약해서 답한다. 스크립트가 필요 없다.

## 주의

- 메모리 폴더를 직접 git에 추가하거나 `.gitignore`를 수정하지 않는다. exclude 등록은 setup 스크립트가 처리하며, 로컬 전용(`.git/info/exclude`)이라 팀에 영향이 없다.
- import 시 기존 기록을 덮어쓰지 말 것. 충돌이 의심되면 사용자에게 보여주고 결정을 맡긴다.
