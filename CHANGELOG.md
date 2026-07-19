# 변경 이력 (Changelog)

이 저장소(코드 리뷰 스킬 모음)의 주요 변경사항을 기록합니다.
형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를,
버전 규칙은 [유의적 버전(SemVer)](https://semver.org/lang/ko/)을 따릅니다.

> 각 항목은 **개발자가 아니어도 이해할 수 있는 쉬운 한 줄 문장**으로 씁니다.
> (커밋 메시지 원문을 그대로 붙이지 않습니다.)
>
> 카테고리: **Added**(새로 생김) · **Changed**(바뀜) · **Deprecated**(곧 없어질 예정) ·
> **Removed**(없어짐) · **Fixed**(고침) · **Security**(보안).

## [Unreleased]
<!-- last-processed: 71ab3d0 -->

## [0.2.0] - 2026-07-13

### Added
- 모노레포를 리뷰할 때, 리뷰 기록을 패키지별로 나눠 저장할 수 있게 됐습니다. 여러 패키지에 공통인 규칙은 한곳에, 특정 패키지에만 해당하는 규칙은 그 패키지 폴더에 쌓여 메모리가 뒤섞이지 않습니다.
- 리뷰 스킬이 바뀐 파일 위치를 보고 어느 패키지인지 스스로 알아내서, 그 패키지의 과거 기록을 함께 참고합니다.
- 스킬을 새로 추가했는데 안내 문서(README·AGENTS)에 빠뜨리면, 커밋할 때 문서를 갱신하라고 알려주는 검사 훅을 추가했습니다.

## [0.1.0] - 2026-07-12

### Added
- 코드 리뷰를 도와주는 스킬 4종(PR 리뷰·로컬 변경 리뷰·브랜치 리뷰·리뷰 메모리)을 한곳에서 관리합니다.
- 같은 리뷰 스킬을 Claude Code뿐 아니라 Codex·Gemini CLI·Copilot CLI에서도 쓸 수 있게 했습니다.
- 복잡한 경로를 외울 필요 없이 `mrt-review` 명령 하나로 리뷰 기록을 다룰 수 있는 런처를 넣었습니다.
- `install.sh` 한 번이면 모든 에이전트에 스킬이 한꺼번에 설치됩니다.
- PR 리뷰 코멘트를 문단과 줄바꿈으로 나눠 읽기 쉽게 쓰는 규칙을 추가했습니다.
- 변경 이력을 자동으로 쉬운 문장으로 기록해 주는 체인지로그 스킬과 훅을 넣었습니다.

### Changed
- 흩어져 있던 리뷰 메모리 스크립트를 한 폴더로 모아 정리했습니다.
- 리뷰에서 발견한 규칙을 자동으로 쌓지 않고, 사용자가 확인한 뒤에만 기록하도록 바꿨습니다.

[Unreleased]: https://github.com/Zero-1016/my-review-toolkit/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Zero-1016/my-review-toolkit/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Zero-1016/my-review-toolkit/releases/tag/v0.1.0
