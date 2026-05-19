#!/bin/bash
# feature-dev.sh — 기능 개발 파이프라인 (책 7-5 워크플로우 1)
#
# Phase 1: 조사(프니엘) + UI 설계(현식) 병렬
# Phase 2: 아키텍처 설계 (민혁)
# Phase 3: 구현 (창섭)
# Phase 4: 리뷰 (성재)
#
# 사용: bash feature-dev.sh "사용자 알림 시스템"

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_session

FEATURE="${1:?사용법: $0 \"<기능명>\"}"
SLUG=$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')

wf-header "WF-FEATURE-DEV" "$FEATURE"

# ── Phase 1: 조사 + 디자인 (병렬) ──────────────────
phase-header 1 "조사 + 디자인 (병렬)"

team-send 프니엘 "[$FEATURE] 기술 스택을 조사해줘. 후보 라이브러리·서비스 비교 분석, 출처 포함. 영역: docs/research/ | 산출물: docs/research/${SLUG}-stack.md"

team-send 현식 "[$FEATURE] UI를 설계해줘. 사용자 플로우, 컴포넌트 분해, 상태(빈/로딩/에러/성공) 포함. 영역: docs/design/ | 산출물: docs/design/${SLUG}-ui.md"

echo ""
read -rp "  Phase 1 완료 (프니엘 + 현식 결과 확인) 후 Enter: "

# ── Phase 2: 아키텍처 설계 ──────────────────────────
phase-header 2 "아키텍처 설계 (민혁)"

team-send 민혁 "[$FEATURE] 프니엘의 조사(docs/research/${SLUG}-stack.md)와 현식의 UI(docs/design/${SLUG}-ui.md)를 참고해서 아키텍처 설계: API 엔드포인트, 데이터 모델, 플로우. 영역: docs/architecture/ | 산출물: docs/architecture/${SLUG}-system.md | 브랜치: feature/minhyuk-${SLUG}-arch"

echo ""
read -rp "  Phase 2 완료 후 Enter: "

# ── Phase 3: 구현 ───────────────────────────────────
phase-header 3 "구현 (창섭) — TDD 적용"

team-send 창섭 "[$FEATURE] 민혁의 설계(docs/architecture/${SLUG}-system.md)에 따라 구현. superpowers:test-driven-development 적용 — 테스트 먼저 작성. 1)서비스 모듈 2)어댑터 3)API 엔드포인트 4)UI 컴포넌트 결합. 영역: src/ + tests/ | 브랜치: feature/changseop-${SLUG}-impl | 공유파일(routes/types) 수정 시 은광 보고"

echo ""
read -rp "  Phase 3 완료 후 Enter: "

# ── Phase 4: 리뷰 ───────────────────────────────────
phase-header 4 "리뷰 (성재)"

team-send 성재 "[$FEATURE] 창섭의 구현 리뷰. 중점: 보안(인젝션·인증), 성능, 에러 핸들링. /review 또는 자연어 리뷰. Severity(P0~P3) 분류. 영역: tests/review/, REVIEW.md"

echo ""
echo -e "${GREEN}✅ Feature 개발 파이프라인 디스패치 완료 — $FEATURE${NC}"
echo "   머지는 은광 검토 후 진행."
