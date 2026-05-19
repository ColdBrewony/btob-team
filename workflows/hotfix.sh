#!/bin/bash
# hotfix.sh — 프로덕션 핫픽스 워크플로우 (책 7-5 워크플로우 2)
#
# Phase 1: 원인 분석 (프니엘)
# Phase 2: 핫픽스 구현 (창섭)
# Phase 3: 긴급 리뷰 (성재)
#
# 사용: bash hotfix.sh "결제 완료 후 주문 미생성"

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_session

ISSUE="${1:?사용법: $0 \"<장애 설명>\"}"
SLUG=$(echo "$ISSUE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-' | cut -c1-40)
BRANCH="hotfix/${SLUG}"

wf-header "WF-HOTFIX" "$ISSUE"
echo -e "${RED}🚨 긴급 모드: 분석 → 수정 → 리뷰를 즉시 순차 실행${NC}"

# ── Phase 1: 원인 분석 ──────────────────────────────
phase-header 1 "원인 분석 (프니엘)"

team-send 프니엘 "[긴급][hotfix] '$ISSUE' 원인 분석. 1)관련 최근 커밋 확인 (git log --oneline -20) 2)에러 로그 검색 3)관련 코드 흐름 추적. 분석 결과를 docs/incidents/${SLUG}.md 에 기록하고 즉시 은광에게 보고."

echo ""
read -rp "  프니엘 분석 완료 후 Enter (원인 확인): "
read -rp "  확인된 원인을 한 줄로 입력: " ROOT_CAUSE

# ── Phase 2: 핫픽스 구현 ────────────────────────────
phase-header 2 "핫픽스 구현 (창섭)"

team-send 창섭 "[긴급][hotfix] '$ISSUE' 수정. 원인: $ROOT_CAUSE | 브랜치: $BRANCH | 수정 후 회귀 테스트 추가 필수 | 영역: 원인 코드와 직접 관련된 파일만 (리팩토링 금지)"

echo ""
read -rp "  창섭 수정 완료 후 Enter: "

# ── Phase 3: 긴급 리뷰 ──────────────────────────────
phase-header 3 "긴급 리뷰 (성재)"

team-send 성재 "[긴급][hotfix] $BRANCH 긴급 리뷰. 사이드 이펙트 집중 확인. 회귀 테스트 통과 여부 확인. P0/P1만 보고. 차단 사유 있으면 즉시 알림."

echo ""
echo -e "${GREEN}✅ 핫픽스 디스패치 완료${NC}"
echo "   리뷰 통과 후 은광이 사용자에게 배포 승인 요청."
