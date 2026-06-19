# 코드 리뷰 스킬 모음

Claude Code에서 쓰는 개인 코드 리뷰 스킬 저장소. 모든 리뷰 스킬이 프로젝트별
**리뷰 메모리**(`.review-memory/`)를 공유해서, 리뷰를 거듭할수록 그 프로젝트에
특화된 리뷰어가 되는 것이 핵심이다.

## 스킬 목록

스킬은 전부 [`.claude/skills/`](.claude/skills/) 아래에 있다.

| 스킬 | 대상 | 언제 쓰나 |
|------|------|-----------|
| [`local-code-review`](.claude/skills/local-code-review/SKILL.md) | 미커밋 변경 (working diff) | 커밋/푸시 전에 "내 변경사항 봐줘", "커밋 전에 리뷰해줘" |
| [`branch-review`](.claude/skills/branch-review/SKILL.md) | 브랜치 전체 (base 브랜치의 merge-base 기준, 커밋 + 미커밋) | "main 대비 뭐가 바뀌었는지 리뷰해줘", "브랜치 전체 심각도별로 봐줘" |
| [`pr-review`](.claude/skills/pr-review/SKILL.md) | GitHub PR | PR 번호/URL로 "이 PR 리뷰해줘" — 복사해서 달 수 있는 추천 코멘트까지 생성 |
| [`review-memory`](.claude/skills/review-memory/SKILL.md) | 리뷰 메모리 관리 | 메모리 내보내기/가져오기/조회, 리뷰 컨텍스트 사전 등록. 공용 스크립트도 여기에 |

### 출력 형식

- 세 리뷰 스킬 모두 발견 사항을 **항목별 블록**(클릭 가능한 `파일:라인` 위치 + 문제 코드 + 수정 제안)으로 출력한다.
- `branch-review`는 심각도 **🔴 High / 🟡 Medium / 🟢 Low** 3단계로 분류하고 요약에 건수를 표기한다.
- `local-code-review`는 🔴 커밋 전 수정 / 🟡 권장 / 💬 확인 필요, `pr-review`는 🔴 반드시 수정 / 🟡 권장 / 💬 질문 구조를 쓴다.
- 수정 적용·GitHub 코멘트 게시는 사용자가 명시적으로 요청할 때만 한다. 기본은 보고.

## 리뷰 메모리 구조

리뷰 스킬이 각 프로젝트에 자동으로 만들고 채운다. `.git/info/exclude`에 등록되므로
절대 커밋되지 않는다 (팀에 영향 없음).

```
<프로젝트>/.review-memory/
├── conventions.md   # 반복 패턴·컨벤션 — 리뷰 결과에서 자동 누적
├── context.md       # 사용자가 미리 등록하는 배경/중점 사항 (review-memory 스킬로 관리)
└── reviews/
    └── <날짜>-<대상>.md   # 예: 2026-06-12-pr-123.md, 2026-06-12-branch-feat-login.md
```

모든 리뷰는 시작할 때 `conventions.md` + `context.md` + 최근 리뷰 2~3개를 읽고,
끝나면 결과를 저장한다. PR 리뷰에서 발견된 패턴이 로컬/브랜치 리뷰에도 반영되고,
그 반대도 마찬가지다.

## 설치

스킬 디렉토리를 `~/.claude/skills/`에 심링크하면 모든 프로젝트에서 쓸 수 있다:

```bash
for s in branch-review local-code-review pr-review review-memory; do
  ln -sfn "$(pwd)/.claude/skills/$s" ~/.claude/skills/$s
done
```

스킬 본문이 공용 스크립트를 `~/.claude/skills/review-memory/scripts/` 경로로
참조하므로, `review-memory` 심링크는 필수다.

## 기타

- [`review-skills-workspace/`](review-skills-workspace/) — 스킬 개발 시 사용한 평가(eval) 픽스처와 결과물. 스킬 동작과는 무관하다.
