---
name: changelog
description: 이 저장소의 CHANGELOG.md를 관리하는 스킬 — 새 커밋을 개발자가 아니어도 이해할 수 있는 쉬운 문장으로 기록하고(add), 릴리스 시 버전을 확정해 태그를 만든다(release). 사용자가 "체인지로그 갱신해줘", "변경 이력 정리해줘", "changelog 써줘", "버전 올려줘/릴리스 해줘", "이번 릴리스 노트 만들어줘" 처럼 말하거나, 커밋 직후 훅이 갱신을 요청하면 반드시 이 스킬을 사용한다. Keep a Changelog + SemVer 포맷을 정본 템플릿으로 강제한다.
---

# CHANGELOG 관리

`CHANGELOG.md`를 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) + [SemVer](https://semver.org/lang/ko/)
포맷으로 유지한다. **불릿 내용은 커밋 원문이 아니라, 개발자가 아니어도 이해할 수 있는
쉬운 한 줄 문장**으로 쓰는 것이 이 스킬의 핵심이다.

두 가지 모드가 있다:
- **`add`** (기본) — 마지막으로 기록한 커밋 이후의 변경을 `[Unreleased]`에 반영한다.
- **`release`** — `[Unreleased]`를 정식 버전으로 확정하고 git 태그를 만든다.

> 파일 읽기/쓰기는 셸(`cat`/`echo`) 대신 에이전트의 파일 읽기/쓰기 도구를 쓴다.

---

## 모드 판별

- 사용자가 "릴리스/버전 올려/배포" 를 말하면 → **release**.
- 그 외(커밋 반영, 훅 요청, "체인지로그 갱신") → **add**.

---

## add — 새 변경을 [Unreleased]에 반영

### 1단계: 어디까지 기록됐는지 확인

`CHANGELOG.md`를 읽고 `[Unreleased]` 바로 아래의 마커를 찾는다:

```
## [Unreleased]
<!-- last-processed: <sha> -->
```

이 `<sha>`가 **마지막으로 기록한 커밋**이다. 이후의 새 커밋 목록을 뽑는다:

```bash
git log <sha>..HEAD --format='%h%x09%s%x09%b' --reverse
```

- 새 커밋이 없으면(= HEAD가 마커와 같으면) 조용히 종료한다. 아무것도 쓰지 않는다.
- 커밋이 여럿이면 한 번에 모두 처리한다(훅이 못 돈 에이전트에서 밀린 것도 여기서 따라잡는다).

### 2단계: 커밋을 쉬운 문장으로 변환

각 커밋을 아래 규칙으로 옮긴다:

- **카테고리 분류** — 커밋 타입/내용을 보고 배치한다:
  - `feat` → **Added** (새 동작이면), 기존 동작을 바꾼 거면 **Changed**
  - `fix` → **Fixed**
  - `refactor`/`perf`/`chore`/`style` → 사용자가 체감하는 변화가 있으면 **Changed**, 없으면 **기록하지 않는다**
  - 보안 수정 → **Security**, 기능 제거 → **Removed**, 폐기 예고 → **Deprecated**
- **제외 대상** — 아래는 항목으로 만들지 않는다(단, 마커는 HEAD까지 전진시킨다):
  - `docs(changelog)` · `chore(release)` 커밋 (= 체인지로그 자신의 변경 → 무한루프 방지)
  - 순수 내부 정리(빌드/포맷/오타 등 사용자 눈에 안 보이는 것)
- **문장 쓰기** — "이 커밋 덕분에 **뭐가 좋아졌는지/뭐가 달라졌는지**"를 한 줄로. 필요하면 커밋 본문(`%b`)이나 diff를 봐서 의도를 파악한다.
  - 좋음: `- PR 리뷰 코멘트를 문단으로 나눠 읽기 편해졌습니다.`
  - 나쁨: `- feat(pr-review): 추천/게시 코멘트 본문 가독성 레시피 추가` (← 커밋 원문 복붙 금지)
- 애매한 커밋(카테고리/문구가 불확실)은 사용자에게 한 줄로 확인한다.

### 3단계: [Unreleased]에 병합하고 마커 전진

- 해당 카테고리 소제목(`### Added` 등)이 없으면 **표준 순서**(Added → Changed → Deprecated → Removed → Fixed → Security)를 지켜 새로 만든다.
- 새 불릿을 카테고리 맨 아래에 추가한다. 이미 있는 항목과 의미가 겹치면 중복으로 넣지 않는다.
- 마커를 처리한 마지막 커밋(= 현재 HEAD)으로 갱신한다:

```bash
git rev-parse --short HEAD   # 이 값을 <!-- last-processed: … --> 에 기록
```

### 4단계: 보고

무엇을 추가했는지 카테고리별로 짧게 요약해 보여준다. **CHANGELOG.md를 커밋하지는 않는다** —
다음 일반 커밋에 자연스럽게 포함되거나, 사용자가 원할 때 커밋한다.

---

## release — 버전 확정 + 태그

### 1단계: 버전 결정 (SemVer)

사용자가 `major`/`minor`/`patch` 또는 명시 버전을 줬으면 그대로. 아니면 `[Unreleased]` 내용으로 추론한다:

- **MAJOR** — 리뷰 메모리 포맷이나 `mrt-review` 명령 인터페이스가 **깨지는 변경**(기존 사용자가 손봐야 함). Removed 항목이 계약을 깨면 여기.
- **MINOR** — 새 스킬/새 기능/동작 변경 (Added, 또는 하위호환되는 Changed).
- **PATCH** — 버그 수정·문구 수정만 (Fixed 위주).

현재 최신 버전은 `git tag --list 'v*'` 또는 CHANGELOG의 최상단 released 버전에서 읽는다.
추론한 버전을 **사용자에게 한 번 확인**받고 진행한다.

### 2단계: [Unreleased] → 버전 섹션으로 확정

- `## [Unreleased]` 아래 내용을 새 `## [x.y.z] - YYYY-MM-DD`(오늘 날짜) 섹션으로 옮긴다.
- `[Unreleased]`는 빈 상태로 남기되 `<!-- last-processed: <현재 HEAD sha> -->` 마커는 유지한다.
- 하단 링크를 갱신한다:
  ```
  [Unreleased]: https://github.com/Zero-1016/my-review-toolkit/compare/vX.Y.Z...HEAD
  [X.Y.Z]: https://github.com/Zero-1016/my-review-toolkit/releases/tag/vX.Y.Z
  ```
  (이전 버전이 있으면 `compare/vPREV...vX.Y.Z` 형태로도 링크한다.)

### 3단계: 커밋 + 태그

```bash
git add CHANGELOG.md
git commit -m "chore(release): vX.Y.Z"
git tag -a "vX.Y.Z" -m "vX.Y.Z"
```

- **푸시(`git push`, `git push --tags`)는 사용자가 명시적으로 요청할 때만** 한다.
- 커밋 메시지 `chore(release):` 접두사 덕분에 체인지로그 훅이 이 커밋을 건너뛴다(루프 방지).

### 4단계: 보고

확정한 버전·태그, 무엇이 릴리스됐는지 요약, 그리고 "푸시하려면 `git push && git push --tags`" 안내를 보여준다.

---

## 자동 훅과의 관계

이 저장소에는 커밋 성공 시 이 스킬(`add`)을 부르는 PostToolUse 훅(`.claude/settings.json`)이 걸려 있다.
훅은 **Claude Code 전용**이므로, 다른 에이전트에서 작업했다면 훅이 안 돈다 — 그 경우
`add`가 마커 기준으로 **밀린 커밋을 다음 실행에서 한꺼번에 따라잡는다**. 그래서 훅이 없어도 결과는 같다.
