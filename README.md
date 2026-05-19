# btob-team

6명의 Claude Code 에이전트로 구성된 멀티에이전트 개발팀.
`tmux` 위에서 각자 다른 역할을 맡은 6개의 Claude 인스턴스를 동시 운용하고,
사용자의 한 줄 지시를 **Triple Crown 자동 워크플로우(gstack → GSD → Superpowers)** 로 전개한다.

```
                          사용자
                            │
                            ▼
                       팀장 (은광)
                            │
        ┌────────────┬──────┴──────┬────────────┐
        ▼            ▼             ▼            ▼
   민혁(설계)   창섭(개발)    현식(UI/UX)   프니엘(리서치)
                            │
                            ▼
                       성재 (리뷰·QA)
                            │
                            ▼
                       사용자 보고
```

---

## 팀 구성

| Pane | 이름 | 역할 | 모델 | 기본 영역 |
|------|------|------|------|-----------|
| 0 | **은광** | 팀장 — 지시 수령, 작업 배분, 결과 통합 보고, 충돌·세션 관리 | Sonnet 4.6 | — (코드 직접 작성 안 함) |
| 1 | **민혁** | 아키텍트 — 시스템 설계, 기술 스택, API/데이터 모델 | Opus 4.7 | `docs/architecture/`, `docs/adr/` |
| 2 | **창섭** | 개발자 — 기능 구현, 코드 작성, 테스트, 의존성 관리 | Sonnet 4.6 | `src/`, `tests/`, `package.json` |
| 3 | **현식** | UI/UX 디자이너 — 화면 설계, 컴포넌트, 디자인 토큰 | Sonnet 4.6 | `src/ui/`, `src/components/`, `design/` |
| 4 | **프니엘** | 리서쳐 — 기술 조사, 라이브러리 비교, 출처 정리 | Sonnet 4.6 | `docs/research/` |
| 5 | **성재** | QA·리뷰어 — 코드 리뷰, 보안·성능 검토, Severity 분류 | Sonnet 4.6 | `tests/review/`, `REVIEW.md` |

상세 역할 정의는 [`roles/`](./roles) 디렉토리 참조.

### 보고 체인

```
사용자 → 은광 → (민혁/창섭/현식/프니엘/성재) → 은광 → 사용자
```

팀원은 사용자에게 직접 응답하지 않는다. 모든 결과는 은광이 통합해서 보고한다.

---

## 요구 사항

- **macOS** 또는 **Linux (Ubuntu/WSL2)**
- **Bash 4+** 또는 **Zsh**
- **tmux 3+**
- **Node.js 18+** (Claude Code 실행용)
- **Claude Code CLI 2.x**
- **RAM 16GB 이상 권장** (Claude 6개 인스턴스 동시 실행)

---

## 설치

### 1. tmux

**macOS (Homebrew):**

```bash
brew install tmux
tmux -V   # tmux 3.x 확인
```

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install -y tmux
```

`tmux` 기본 키 바인딩:

| 단축키 | 동작 |
|--------|------|
| `Ctrl-b ←/→/↑/↓` | 파인 이동 |
| `Ctrl-b d` | 세션 분리(detach) |
| `Ctrl-b z` | 현재 파인 최대화/복원 |
| `tmux attach -t team` | 분리된 세션에 재접속 |

### 2. Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
claude --version    # 2.x 확인

# 최초 인증
claude
```

브라우저에서 OAuth 로그인을 마치면 인증이 저장된다.

### 3. (선택) Triple Crown 명령어용 플러그인

자동 워크플로우는 아래 플러그인이 설치되어 있을 때 `/cso`, `/autoplan`, `/gsd:*`, `/review`, `/qa`, `/ship` 같은 슬래시 명령으로 작동한다.
설치되어 있지 않으면 은광이 자동으로 **자연어 등가 지시**로 폴백한다.

#### 3-1. gstack — Claude Code 플러그인 스택

```bash
# 공식 설치 안내 확인
gh repo view garry-ut99/gstack

# 일반적 설치 (스크립트형)
curl -fsSL https://raw.githubusercontent.com/garry-ut99/gstack/main/install.sh | bash
```

설치 후 제공되는 슬래시 명령:
- `/cso` — CEO 관점 비즈니스 가치·우선순위 검토
- `/autoplan` — 자동 개발 계획 생성 (CEO/설계/엔지니어링 리뷰 포함)
- `/review` — 코드 리뷰
- `/qa` — 시나리오 기반 QA
- `/ship` — PR 준비 (CHANGELOG, 변경 요약 자동)

#### 3-2. GSD — Get Shit Done 프로젝트 관리

```bash
# GSD 설치 (gstack과 함께 배포되는 경우가 많음)
# 자세한 설치는 gstack 문서 참조
```

설치 후 제공되는 슬래시 명령:
- `/gsd:new-project`, `/gsd:new-milestone`
- `/gsd:plan-phase N`, `/gsd:execute-phase N`
- `/gsd:validate-phase N`, `/gsd:verify-work`
- `/gsd:progress`, `/gsd:complete-milestone`

`.planning/` 디렉토리에 마일스톤·페이즈·태스크가 파일로 저장된다.

#### 3-3. superpowers — 스킬 기반 방법론

```bash
# Claude Code 스킬은 일반적으로 ~/.claude/skills/ 하위에 설치
# 공식 배포 또는 직접 작성
```

활용되는 핵심 스킬:
- `superpowers:test-driven-development` — TDD 강제 (Red → Green → Refactor)
- `superpowers:systematic-debugging` — 가설 기반 디버깅
- `superpowers:dispatching-parallel-agents` — 병렬 작업 분배

> 플러그인이 설치되어 있지 않아도 **팀 자체는 정상 동작한다.** 은광이 자연어 지시로 같은 절차를 수행한다.

### 4. 이 저장소 클론

```bash
git clone https://github.com/ColdBrewony/btob-team.git
cd btob-team
```

---

## 빠른 시작

### 1) 팀 환경 시작

```bash
bash setup-team.sh
```

이 한 줄이 끝나면:
- tmux 세션 `team` 생성 + 파인 6개 분할
- 각 파인에서 Claude Code 자동 실행 (적절한 모델, `--dangerously-skip-permissions`)
- 각 파인에 **부트스트랩 메시지** 자동 송신 → 각 Claude가 `CLAUDE.md` + 자기 `roles/*.md`를 읽고 `✅ 준비 완료 — {이름}` 응답
- 자동으로 `tmux attach -t team`

### 2) 부트스트랩 검증

새 터미널에서:

```bash
bash verify-roles.sh
```

전원 ✅ 가 나오면 준비 완료. 미응답자가 있으면:

```bash
bash verify-roles.sh --ask    # 대화식 재확인
```

### 3) 작업 지시

`tmux attach -t team` 한 상태에서 **Pane 0 (은광)** 으로 이동 후 한 줄 입력:

```
inputs 보고 사이트 만들어줘
```

또는 자료 없이:

```
사용자 알림 기능 추가해줘
```

은광이 자동으로:
1. (자료 참조 시) `inputs/` 스캔 → 자료 요약 발표
2. 규모 판정 → 워크플로우 선언
3. 팀원에게 `tmux send-keys`로 영역·브랜치·금지영역 포함 지시
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

사용자의 단일 지시를 **gstack(전략) → GSD(관리) → Superpowers(품질)** 의 5단계 파이프라인으로 자동 전개한다.

### 작업 규모별 분기

은광이 요청을 받으면 다음 표에 따라 워크플로우를 자동 선택한다.

| 규모 | 기준 | 자동 적용 워크플로우 | Phase |
|------|------|---------------------|-------|
| **소** (1시간 이내) | 오타·설정·1파일 수정 | `WF-DIRECT` | 직접 라우팅 |
| **중** (반나절) | 버그 수정·작은 기능·PR 리뷰 | `WF-FEATURE-DEV` 축약형 | 3+4 |
| **대** (1~3일) | 새 기능 모듈·API 추가 | `WF-FEATURE-DEV` | 1~4 |
| **특대** (1주 이상) | 신규 서비스·대규모 리팩토링 | `WF-TRIPLE-CROWN` | 1~5 풀 |

### 키워드 트리거

| 요청 키워드 | 즉시 적용 워크플로우 | 스크립트 |
|------------|---------------------|----------|
| "긴급", "장애", "프로덕션 오류", "hotfix" | `WF-HOTFIX` | [`workflows/hotfix.sh`](./workflows/hotfix.sh) |
| "리뷰해줘", "PR #N" | `WF-PR-REVIEW` | [`workflows/pr-review.sh`](./workflows/pr-review.sh) |
| "팀 현황", "오늘 작업", "데일리" | `WF-DAILY-REPORT` | [`workflows/daily-report.sh`](./workflows/daily-report.sh) |
| "기능 만들어", "추가해줘" + 규모 대 이상 | `WF-FEATURE-DEV` | [`workflows/feature-dev.sh`](./workflows/feature-dev.sh) |
| "프로젝트", "신규 서비스", "대규모" | `WF-TRIPLE-CROWN` | [`workflows/triple-crown.sh`](./workflows/triple-crown.sh) |

### Triple Crown 5단계 (WF-TRIPLE-CROWN)

```
Phase 1 — 전략 수립 (gstack)
  은광 직접: /cso → /autoplan
                ↓
Phase 2 — 프로젝트 구조화 (GSD)
  민혁 위임: /gsd:new-project → /gsd:plan-phase
                ↓
Phase 3 — 구현 (GSD + Superpowers)
  창섭: /gsd:execute-phase + superpowers:test-driven-development
  현식: UI 컴포넌트 병렬 구현
  병렬 시 superpowers:dispatching-parallel-agents
                ↓
Phase 4 — 검증 (GSD + gstack)
  민혁: /gsd:validate-phase, /gsd:verify-work
  성재: /review + /qa
                ↓
Phase 5 — 완료 (gstack + GSD)
  은광 또는 창섭: /ship → /gsd:complete-milestone
```

각 Phase 전환 시 은광은 다음 형식으로 보고한다.

```
✅ Phase N 완료 — {요약}
▶ Phase N+1 시작 — {담당자, 다음 액션}
```

### 자동화 OFF

분류 없이 단순 라우팅만 하려면 메시지 앞에 `[수동]` 또는 `[manual]` 접두사:

```
[수동] src/utils.ts 의 이 함수만 단순화해줘
```

### 워크플로우 수동 실행

은광 자동 트리거 외에 셸에서 직접 실행도 가능하다.

```bash
bash workflows/triple-crown.sh "쇼핑몰 신규 서비스"
bash workflows/feature-dev.sh   "사용자 알림 기능"
bash workflows/hotfix.sh        "결제 완료 후 주문 미생성"
bash workflows/pr-review.sh     42
bash workflows/daily-report.sh  60
```

---

## 충돌 방지 규칙 (R1~R6)

여러 팀원이 같은 코드베이스에서 동시에 일하므로 다음 규칙을 강제한다.

| ID | 규칙 |
|----|------|
| **R1** | 영역 분리 — 각 팀원은 배정된 디렉토리만 수정한다 |
| **R2** | 브랜치 분리 — 자기 브랜치(`feature/{이름}-{기능}`)에서만 커밋 |
| **R3** | 공유 파일 수정 프로토콜 — `routes.ts`, `types.ts` 등은 은광을 통해 순차 수정 |
| **R4** | 의존성 변경 — `npm install` 등은 창섭만, 은광 사전 승인 |
| **R5** | 잠금 컨벤션 — `.lock` 파일로 일시적 배타 표시 |
| **R6** | 충돌 감지 — 보고 시 변경 파일·브랜치·커밋 해시 동봉 |

상세 내용은 [`CLAUDE.md`](./CLAUDE.md#멀티에이전트-충돌-방지-규칙) 참조.

---

## 디렉토리 구조

```
btob-team/
├── README.md                    # 본 파일
├── CLAUDE.md                    # 팀 공통 규칙 + Triple Crown + 입력 처리
├── setup-team.sh                # 팀 환경 자동 구성 (부트스트랩 송신 포함)
├── check-team.sh                # 세션·파인 상태 점검 + 자동 복구
├── verify-roles.sh              # 부트스트랩 응답 검증
├── .gitignore
│
├── roles/                       # 6명 역할 정의
│   ├── eungwang.md              #   팀장
│   ├── minhyuk.md               #   아키텍트
│   ├── changseop.md             #   개발자
│   ├── hyunsik.md               #   UI/UX 디자이너
│   ├── phaniel.md               #   리서쳐
│   └── seongjae.md              #   QA·리뷰어
│
├── workflows/                   # 5개 자동 워크플로우
│   ├── lib/common.sh            #   공용 헬퍼 (team-send 등)
│   ├── triple-crown.sh          #   Phase 1~5 풀 파이프라인
│   ├── feature-dev.sh           #   기능 개발 (조사+UI → 설계 → 구현 → 리뷰)
│   ├── hotfix.sh                #   긴급 핫픽스
│   ├── pr-review.sh             #   PR 자동 리뷰
│   └── daily-report.sh          #   일일 팀 현황 수집
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

## 운영 가이드

### 세션 복구

| 상황 | 조치 |
|------|------|
| SSH/터미널만 끊김 | `tmux attach -t team` |
| 특정 파인의 Claude만 종료 | 해당 파인에서 `claude` 재실행 + `/resume` |
| 파인 자체가 사라짐 | 파인 재분할 + 타이틀 재설정 + Claude 실행 |
| 세션 전체 소실 | `bash setup-team.sh` 재실행 |

자동 점검:

```bash
bash check-team.sh
```

10분마다 자동 점검:

```cron
*/10 * * * * /절대경로/btob-team/check-team.sh >> /tmp/team-check.log 2>&1
```

### 메모리 사용량 확인

```bash
ps aux | grep claude | grep -v grep | awk '{print $6/1024 "MB", $11, $12, $13}' | sort -rn
```

Claude 6개 인스턴스는 8~16GB 메모리를 점유할 수 있다.

---

## 라이선스 / 크레딧

- 본 팀 구조는 [클로드 코드(Claude Code)로 팀 자동화 완성: 에이전트와 원격 제어 실전 가이드](https://wikidocs.net/347753) 의 6인 팀 패턴을 기반으로 한다.
- Triple Crown 전략(gstack + GSD + Superpowers)도 같은 출처의 개념.
- 본 저장소의 팀원 이름·역할 분배·디렉토리 영역은 운영자에 맞게 커스터마이즈됨.
