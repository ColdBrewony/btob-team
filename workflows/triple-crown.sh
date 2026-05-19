#!/bin/bash
# triple-crown.sh — Triple Crown 5단계 풀 파이프라인 (gstack → GSD → Superpowers)
#
# 사용: bash triple-crown.sh "사용자 알림 시스템"

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_session

FEATURE="${1:?사용법: $0 \"<기능명>\"}"
SLUG=$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')

wf-header "WF-TRIPLE-CROWN" "$FEATURE"

# ── Phase 1: 전략 수립 (gstack) ───────────────────
phase-header 1 "전략 수립 (gstack: /cso → /autoplan)"
echo "  은광이 Pane 0에서 직접 실행: /cso, /autoplan"
echo "  → CEO 관점 검토 + 자동 개발 계획 생성"
echo ""
read -rp "  Phase 1 완료 후 Enter (또는 Ctrl-C로 중단): "

# ── Phase 2: 프로젝트 구조화 (GSD) ────────────────
phase-header 2 "프로젝트 구조화 (GSD)"

team-send 민혁 "[$FEATURE] /gsd:new-project 으로 '$FEATURE' 프로젝트를 생성하고, /gsd:new-milestone 으로 M1을 만든 뒤 /gsd:plan-phase 1 까지 완료해줘. 영역: docs/architecture/, .planning/ | 브랜치: feature/minhyuk-${SLUG}-plan"

team-send 프니엘 "[$FEATURE] '$FEATURE' 구현에 필요한 기술 스택을 조사하고 docs/research/${SLUG}-stack.md 에 정리해줘. 영역: docs/research/"

echo ""
read -rp "  Phase 2 완료 후 Enter: "

# ── Phase 3: 구현 (GSD + Superpowers) ────────────
phase-header 3 "구현 (GSD execute-phase + Superpowers TDD)"

team-send 창섭 "[$FEATURE] /gsd:execute-phase 1 을 실행해줘. superpowers:test-driven-development 적용 — 각 태스크마다 실패 테스트 먼저 작성. 영역: src/ + tests/ | 브랜치: feature/changseop-${SLUG}-impl | 공유파일 수정 시 은광에게 보고"

team-send 현식 "[$FEATURE] UI 컴포넌트를 구현해줘. 영역: src/components/, src/ui/ | 브랜치: feature/hyunsik-${SLUG}-ui"

echo ""
echo "  병렬 작업: 창섭(서버/로직) + 현식(UI)"
echo "  인터페이스 충돌 위험 시 민혁이 사전 조정"
read -rp "  Phase 3 완료 후 Enter: "

# ── Phase 4: 검증 (GSD + gstack) ─────────────────
phase-header 4 "검증 (GSD validate-phase + gstack /review /qa)"

team-send 민혁 "[$FEATURE] /gsd:validate-phase 1 로 Phase 1 완료 여부 확인 + /gsd:verify-work 로 목표 역방향 분석. 결과 보고: docs/architecture/${SLUG}-verify.md"

team-send 성재 "[$FEATURE] 창섭과 현식의 구현을 /review 로 코드 리뷰 + /qa 로 시나리오 검증. 발견 사항을 Severity 분류해서 보고. 영역: tests/review/, REVIEW.md"

echo ""
read -rp "  Phase 4 완료 후 Enter: "

# ── Phase 5: 완료 (gstack + GSD) ─────────────────
phase-header 5 "완료 (/ship + /gsd:complete-milestone)"

team-send 창섭 "[$FEATURE] /ship 으로 PR 준비 — CHANGELOG, 변경 요약 자동 생성. 브랜치들을 정리해서 PR을 만들어줘. 머지는 은광 승인 후"

team-send 민혁 "[$FEATURE] /gsd:progress 로 마일스톤 진행률 업데이트"

echo ""
echo -e "${GREEN}✅ Triple Crown 파이프라인 디스패치 완료 — $FEATURE${NC}"
echo "   각 팀원의 응답을 확인하고 머지 단계에서 사용자에게 보고하세요."
