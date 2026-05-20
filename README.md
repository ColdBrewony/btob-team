# btob-team

**단일 Claude 인스턴스**가 5명의 가상 팀원을 **`Agent` 도구**로 위임 호출하는 멀티에이전트 개발팀.
사용자의 한 줄 지시를 **Triple Crown 자동 워크플로우(전략 → 구조화 → 구현 → 검증 → 완료)** 로 자동 전개한다.

```
                          사용자
                            │
                            ▼
                  은광 (이 Claude 인스턴스)
                            │
              ┌─────────┬───┴───┬─────────┐
              ▼         ▼       ▼         ▼
         민혁(설계)  창섭(개발) 현식(UI)  프니엘(리서치)
                            │
                            ▼
                       성재 (리뷰·QA)
                            │
                            ▼
                       사용자 보고
```

위 다섯 명은 모두 **`Agent` 도구로 호출되는 가상 subagent**다. tmux 멀티 pane / 여러 Claude 인스턴스 동시 실행은 사용하지 않는다.

---

## 팀 구성

| 이름 | 역할 | 기본 영역 |
|------|------|-----------|
| **은광** | 팀장 (이 Claude 본인) — 지시 수령, 작업 분류, 위임, 결과 통합, 충돌 관리 | — (코드 직접 작성 안 함) |
| **민혁** | 아키텍트 — 시스템 설계, 기술 스택, API/데이터 모델 | `docs/architecture/`, `docs/adr/` |
| **창섭** | 개발자 — 기능 구현, 코드 작성, 테스트, 의존성 관리 | `src/`, `tests/`, `package.json` |
| **현식** | UI/UX 디자이너 — 화면 설계, 컴포넌트, 디자인 토큰 | `src/ui/`, `src/components/`, `design/` |
| **프니엘** | 리서쳐 — 기술 조사, 라이브러리 비교, 출처 정리 | `docs/research/` |
| **성재** | QA·리뷰어 — 코드 리뷰, 보안·성능 검토, Severity 분류 | `tests/review/`, `REVIEW.md` |

상세 역할 정의는 [`roles/`](./roles) 디렉토리 참조. 팀원 호출 시 은광이 해당 `roles/*.md` 를 읽어 `Agent` 프롬프트 머리에 주입한다.

### 보고 체인

```
사용자 → 은광 → Agent(민혁/창섭/현식/프니엘/성재) → 은광 통합 → 사용자
```

팀원(subagent)은 사용자에게 직접 응답하지 않는다. 모든 결과는 은광이 통합해서 보고한다.

---

## 왜 단일 Claude + Agent 도구인가

이 저장소는 처음에 tmux 위에 6개의 Claude Code 인스턴스를 띄우고 `tmux send-keys` 로 통신하는 구조였다. 하지만 실제 운용에서:

- `tmux send-keys` 로 주입된 메시지를 Claude Code 런타임이 **단발 태스크**로 인식해 응답 후 종료
- 자동 재시작을 붙여도 매 위임 시 부트스트랩 컨텍스트가 사라지고 5~15초 대기 발생
- 6개 인스턴스가 16GB+ 메모리를 점유

이 문제들은 Claude Code 런타임 동작이라 프롬프트로 우회 불가능하다. 따라서 **은광 하나만 Claude로 두고, 팀원 위임은 Claude 내장 `Agent` 도구로 처리**하도록 재설계했다. 결과:

- 세션 종료 문제 없음 (은광은 인터랙티브 모드로 유지)
- 위임 시점에 `Agent` 호출만 보내면 즉시 subagent 실행
- 같은 응답 안에서 여러 `Agent` 호출 → 자연스러운 병렬 위임
- 메모리·관리 부담 대폭 감소

---

## 요구 사항

- **Claude Code CLI 2.x** (Sonnet 4.6 이상 모델 권장)
- 이 저장소를 클론한 로컬 디렉토리

tmux, 셸 스크립트, 별도 플러그인은 필요하지 않다.

---

## 빠른 시작

### 1) 저장소 클론

```bash
git clone https://github.com/ColdBrewony/btob-team.git
cd btob-team
```

### 2) Claude Code 시작

```bash
claude
```

또는 자동 권한 승인을 원한다면:

```bash
claude --dangerously-skip-permissions
```

`CLAUDE.md` 가 자동 로드되어 이 Claude 인스턴스가 곧 **은광(팀장)** 으로 동작한다.

### 3) 한 줄 지시

```
사용자 알림 기능 추가해줘
```

또는 입력 자료를 줬다면:

```
inputs 보고 사이트 만들어줘
```

은광이 자동으로:

1. (자료 참조 시) `inputs/` 스캔 → 자료 요약 발표
2. 규모 판정 → 워크플로우 선언 (`📥 받은 요청 / 📏 규모 / 🎯 워크플로우 / 📋 Phase`)
3. `Agent` 도구로 팀원(subagent) 위임 — 영역·브랜치·금지영역·선행 결과 포함
4. Phase 1~5 (또는 축약형) 순차/병렬 실행
5. 결과 통합 후 사용자에게 보고

### 4) 입력 자료 투입 (선택)

사용자가 디자인 시안·요구사항·데이터 파일을 주려면 `inputs/` 디렉토리에 넣는다.

```bash
cp ~/Downloads/디자인시안.png inputs/design/
cp ~/Downloads/요구사항.md inputs/requirements/
```

자세한 자료 분류 규칙은 [`inputs/README.md`](./inputs/README.md) 참조.

---

## Triple Crown 자동 워크플로우

사용자의 단일 지시를 5단계 파이프라인으로 자동 전개한다.

### 작업 규모별 분기

은광이 요청을 받으면 다음 표에 따라 워크플로우를 자동 선택한다.

| 규모 | 기준 | 자동 적용 워크플로우 | Phase |
|------|------|---------------------|-------|
| **소** (1시간 이내) | 오타·설정·1파일 수정 | `WF-DIRECT` | 직접 또는 단일 위임 |
| **중** (반나절) | 버그 수정·작은 기능·PR 리뷰 | `WF-FEATURE-DEV` 축약형 | 3+4 |
| **대** (1~3일) | 새 기능 모듈·API 추가 | `WF-FEATURE-DEV` | 1~4 |
| **특대** (1주 이상) | 신규 서비스·대규모 리팩토링 | `WF-TRIPLE-CROWN` | 1~5 풀 |

### 키워드 트리거

| 요청 키워드 | 즉시 적용 워크플로우 |
|------------|---------------------|
| "긴급", "장애", "프로덕션 오류", "hotfix" | `WF-HOTFIX` |
| "리뷰해줘", "PR #N" | `WF-PR-REVIEW` |
| "팀 현황", "오늘 작업", "데일리" | `WF-DAILY-REPORT` |
| "기능 만들어", "추가해줘" + 규모 대 이상 | `WF-FEATURE-DEV` |
| "프로젝트", "신규 서비스", "대규모" | `WF-TRIPLE-CROWN` |

### Triple Crown 5단계 (WF-TRIPLE-CROWN)

```
Phase 1 — 전략 수립
  은광 직접: 비즈니스 가치·우선순위·MVP 범위 검토
  (필요 시 Agent(프니엘) 병렬 호출로 시장/기술 조사)
                ↓
Phase 2 — 프로젝트 구조화
  Agent(민혁): 아키텍처 설계, 마일스톤 분해, Phase 계획
                ↓
Phase 3 — 구현 (한 응답 안에서 병렬 가능)
  Agent(창섭): 백엔드/로직 구현 (TDD)
  Agent(현식): UI 컴포넌트 구현
                ↓
Phase 4 — 검증
  Agent(민혁): 아키텍처 검증
  Agent(성재): 코드 리뷰 + QA
                ↓
Phase 5 — 완료
  은광 직접: 머지 조율, 사용자 보고
  Agent(창섭): 배포 PR 정리 (CHANGELOG, 변경 요약)
```

각 Phase 전환 시 은광은 다음 형식으로 보고한다.

```
✅ Phase N 완료 — {요약}
▶ Phase N+1 시작 — {담당자, 다음 액션}
```

### 자동화 OFF

분류 없이 단순 위임만 하려면 메시지 앞에 `[수동]` 또는 `[manual]` 접두사:

```
[수동] src/utils.ts 의 이 함수만 단순화해줘
```

---

## 위임 프로토콜 (Agent 도구 호출 패턴)

은광이 팀원을 호출할 때 사용하는 표준 패턴:

```
Agent({
  description: "{팀원} {작업 요약}",
  subagent_type: "general-purpose",
  prompt: <ROLE-PROMPT> + <TASK-PROMPT>
})
```

- **`subagent_type`** 은 모든 팀원이 `general-purpose` 로 통일. 역할은 프롬프트로 구분.
- **ROLE-PROMPT**: 호출 직전 `Read` 도구로 `roles/{이름}.md` 를 읽어 프롬프트 머리에 주입.
- **TASK-PROMPT**: 작업 영역·금지 영역·브랜치·선행 결과·결과 보고 형식 포함.
- **병렬 위임**: 서로 독립적인 작업은 한 응답 안에서 여러 `Agent` 호출을 동시에 보냄.

상세 내용은 [`CLAUDE.md`](./CLAUDE.md#위임-프로토콜-agent-도구-사용) 및 [`roles/eungwang.md`](./roles/eungwang.md) 참조.

---

## 충돌 방지 규칙

여러 subagent가 같은 코드베이스에서 일할 수 있으므로, 은광이 위임 단계에서 다음을 강제한다.

| ID | 규칙 |
|----|------|
| **R1** | 영역 분리 — 위임 프롬프트에 항상 작업 영역과 금지 영역 명시 |
| **R2** | 브랜치 분리 — 각 작업은 자기 브랜치(`feature/{이름}-{기능}`)에서만 커밋, `main` 직접 푸시 금지 |
| **R3** | 공유 파일 순차 처리 — `routes.ts`, `types/`, `package.json` 등은 한 번에 한 subagent만 |
| **R4** | 의존성 변경 — `npm install` 등은 창섭에게만, 위임 프롬프트에 은광 사전 승인 명시 |
| **R5** | 충돌 감지 — 위임 보고에 변경 파일·브랜치·커밋 해시·테스트 결과 동봉 |

상세 내용은 [`CLAUDE.md`](./CLAUDE.md#충돌-방지-규칙) 참조.

---

## 디렉토리 구조

```
btob-team/
├── README.md                    # 본 파일
├── CLAUDE.md                    # 팀 공통 규칙 + Triple Crown + 입력 처리
├── .gitignore
│
├── roles/                       # 6명 역할 정의 (은광이 Agent 호출 시 주입)
│   ├── eungwang.md              #   팀장 (이 Claude 본인)
│   ├── minhyuk.md               #   아키텍트
│   ├── changseop.md             #   개발자
│   ├── hyunsik.md               #   UI/UX 디자이너
│   ├── phaniel.md               #   리서쳐
│   └── seongjae.md              #   QA·리뷰어
│
└── inputs/                      # 사용자 자료 투입 디렉토리
    ├── README.md
    ├── design/                  #   디자인 시안 → 현식
    ├── requirements/            #   요구사항 → 민혁 + 프니엘
    ├── data/                    #   데이터 → 프니엘 + 창섭
    ├── code/                    #   기존 코드 → 창섭 + 민혁
    └── reference/               #   참고 자료 → 프니엘 + 현식
```

---

## 라이선스 / 크레딧

- 본 팀 구조의 6인 역할 분배 콘셉트는 [클로드 코드로 팀 자동화 완성: 에이전트와 원격 제어 실전 가이드](https://wikidocs.net/347753) 의 6인 팀 패턴을 참고했다.
- 원본은 tmux 멀티 pane + 6개 Claude 인스턴스 구조였으나, 본 저장소는 **단일 Claude + 가상 subagent** 구조로 재설계됨.
- Triple Crown 전략(전략 → 구조화 → 구현 → 검증 → 완료)의 단계 개념도 같은 출처에서 가져왔다.
- 팀원 이름·역할 분배·디렉토리 영역은 운영자에 맞게 커스터마이즈됨.
