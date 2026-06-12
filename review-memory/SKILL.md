---
name: review-memory
description: 프로젝트별 리뷰 메모리(.review-memory/)를 관리한다 — 내보내기(export), 가져오기(import), 조회, 초기화, 리뷰 컨텍스트 등록. 사용자가 리뷰 메모리/리뷰 기록을 백업하거나, 다른 머신·프로젝트로 옮기거나, "리뷰 메모리 내보내줘/가져와줘", "리뷰 기록 보여줘", "지금까지 리뷰에서 발견된 패턴 정리해줘" 같은 요청을 하거나, "리뷰할 때 이런 점을 고려해줘", "리뷰 컨텍스트 등록해줘" 처럼 앞으로의 리뷰에 반영할 배경 정보를 미리 알려주면 반드시 이 스킬을 사용한다. pr-review와 local-code-review 스킬이 사용하는 공용 스크립트도 여기에 있다.
---

# Review Memory 관리

각 프로젝트의 `.review-memory/` 폴더에 쌓인 리뷰 기록을 관리하는 스킬.
이 폴더는 `pr-review`, `local-code-review` 스킬이 자동으로 만들고 채운다.

## 메모리 구조

```
<프로젝트>/.review-memory/      # .git/info/exclude에 등록됨 → 절대 커밋되지 않음
├── conventions.md              # 반복 패턴, 팀 컨벤션, 주의점 누적 (리뷰 스킬이 자동 관리)
├── context.md                  # 사용자가 직접 등록하는 사전 컨텍스트 (배경/중점 사항/팀 규칙)
└── reviews/
    └── <날짜>-<대상>.md        # 예: 2026-06-12-pr-123.md, 2026-06-12-local-feat-login.md
```

conventions.md는 리뷰 결과에서 **자동으로 누적**되는 학습 파일이고, context.md는 사용자가
**미리 알려주는** 입력 파일이다. 둘 다 리뷰 시작 시 읽힌다.

## 작업별 방법

모든 스크립트는 이 스킬의 `scripts/` 폴더에 있다.

> 환경 주의: 이 머신의 rtk 훅이 셸 명령을 재작성하므로, 이 스킬의 모든 셸 명령에는
> `RTK_SKIP=1` 접두어를 붙인다 — 훅 래퍼가 마커를 인식해 원본 명령을 그대로 실행한다.
> 그래도 `_safe_eval` 오류가 나면 해당 명령을 절대경로로 재시도한다(예: `/usr/bin/git`, `/opt/homebrew/bin/gh`).

### 초기화 / 폴더 보장

```bash
RTK_SKIP=1 bash ~/.claude/skills/review-memory/scripts/setup_memory.sh <프로젝트경로>
```

폴더 생성 + `.git/info/exclude` 등록까지 한 번에 처리한다. 이미 있으면 그대로 둔다.

### 리뷰 컨텍스트 등록 / 수정

사용자가 "리뷰할 때 X를 고려해줘", "이 프로젝트는 ~한 배경이 있어", "다음 리뷰부터 성능 위주로 봐줘"
처럼 앞으로의 리뷰에 반영할 정보를 주면:

1. 위 초기화 스크립트로 폴더를 보장한다 (context.md 템플릿이 함께 생성된다).
2. `context.md`를 Read로 읽고, 사용자가 준 내용을 알맞은 섹션(프로젝트 배경 / 리뷰 시 중점 사항 / 팀 규칙)에
   Edit로 추가·갱신한다. 템플릿의 괄호 안내문은 실제 내용으로 교체한다.
3. 저장 후 현재 context.md 전체를 사용자에게 보여주고 맞는지 확인한다.

"이번 리뷰에서만" 고려할 일회성 정보는 context.md에 쓰지 않는다 — 그 리뷰에서만 반영하고 버린다.
영구 등록은 사용자가 "앞으로", "항상", "등록해줘" 같이 지속성을 표현할 때만 한다.

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
