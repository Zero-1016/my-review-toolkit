# AGENTS.md — mrt 리뷰 스킬 저장소

이 저장소(mrt)는 코드 리뷰 스킬 5종의 **개발 저장소**이자, 모든 프로젝트의
리뷰 메모리가 모이는 **중앙 저장소**다. 스킬은 특정 에이전트 전용이 아니라
Claude Code · Codex · Gemini CLI · Copilot CLI에서 공용으로 쓰도록 만들어졌다
(`name`/`description` frontmatter는 5종 공통, 본문은 `bash`/`git`/`gh` 기반).

이 파일이 공용 지시파일 정본이며, `CLAUDE.md`·`GEMINI.md`는 여기로의 심링크다.

## 구조

- `skills/` — 정본 스킬 (`branch-review`, `changelog`, `local-code-review`, `pr-review`, `review-memory`).
- `skills/review-memory/scripts/mrt-review` — 스킬 본문이 호출하는 PATH 런처. 메모리 스크립트의 단일 진입점이며, 위임 대상 스크립트(`lib.sh`·`setup_memory.sh`·`manager.sh`)와 같은 폴더에 산다.
- `install.sh` — 정본을 각 에이전트 경로로 링크 + 런처 설치 (멱등).
- `CHANGELOG.md` — 이 저장소의 변경 이력(Keep a Changelog + SemVer). `changelog` 스킬이 관리한다.
- `scripts/hooks/` + `.claude/settings.json` — 커밋 시 도는 훅(Claude Code 한정). `changelog-on-commit.sh`(변경 이력 자동 기록), `doc-freshness.sh`(문서 갱신 필요 검사).
- `.review-memory/<project-slug>/` — 중앙 리뷰 메모리. 모노레포는 `scopes/<패키지>/`로 2층 분리. `.gitignore`로 무시된다(커밋 안 함).

## 설치 / 발견 경로

`bash install.sh` 한 번이면:

- `~/.claude/skills/<name>` → Claude Code
- `~/.agents/skills/<name>` → Codex · Gemini CLI · Copilot CLI 공통 발견 경로
- `~/.local/bin/mrt-review` → PATH 런처

런처/스크립트는 설치 위치·심링크 구조와 무관하게 동작한다(`scripts/lib.sh`가 위로
올라가며 mrt 루트를 찾고, `$MRT_HOME`로 override 가능). 위치 규칙의 SSOT는 `lib.sh` 한 곳이다.

## 메모리 호출

스킬 본문은 `~/.claude/...` 같은 절대경로를 박지 않고 런처만 부른다:

```bash
mrt-review setup <프로젝트경로> [--scope <패키지>]   # 메모리 폴더 보장 + 첫리뷰 신호 + 경로 출력
mrt-review list | show <slug> [--scope <s>] | path <…> | export <…> | import <…> | rm <slug> [--scope <s>] --yes
```

모노레포면 리뷰 스킬이 변경 경로로 패키지(scope)를 판별해 `--scope`로 setup하고,
repo 공유 계층 + 패키지 계층을 둘 다 로드한다.

## 버전 관리 (CHANGELOG)

이 저장소는 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) + SemVer를 쓴다.
`changelog` 스킬이 커밋을 **쉬운 문장**으로 `CHANGELOG.md`의 `[Unreleased]`에 기록하고(add),
릴리스 때 버전 확정 + `vX.Y.Z` 태그를 만든다(release). Claude Code에서는 커밋 훅이 `add`를
자동 호출한다. `[Unreleased]` 바로 아래 `<!-- last-processed: <sha> -->` 마커가 어디까지
기록됐는지 추적하며, 마커는 자기 sha를 담을 수 없으므로 릴리스/기록 커밋만큼 HEAD보다 한 칸
뒤처지는 게 정상이다(그 커밋은 `docs(changelog)`/`chore(release)` guard로 스킵된다).

## mrt 자신을 리뷰할 때

먼저 중앙 메모리를 읽는다(셸 `cat`이 아니라 에이전트의 파일 읽기 도구로):

- `.review-memory/mrt/context.md` — 프로젝트 배경 + **리뷰 필수 체크리스트(하드 게이트)**
- `.review-memory/mrt/conventions.md` — 반복 패턴/컨벤션

이 데이터는 per-machine 로컬 자산이라 커밋되지 않는다. 개인용 추가 메모는
`CLAUDE.local.md`(gitignored)에 둔다.
