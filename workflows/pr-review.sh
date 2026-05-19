#!/bin/bash
# pr-review.sh — PR 자동 리뷰 워크플로우 (책 7-5 워크플로우 3)
#
# Phase 1: 변경 분석(프니엘) + 코드 리뷰(성재) 병렬
# Phase 2: 종합 보고
#
# 사용: bash pr-review.sh 42

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_session

PR="${1:?사용법: $0 <PR번호>}"

wf-header "WF-PR-REVIEW" "PR #$PR"

# ── Phase 1: 변경 분석 + 코드 리뷰 (병렬) ───────────
phase-header 1 "변경 분석 + 코드 리뷰 (병렬)"

team-send 프니엘 "[PR #$PR] 변경 사항 분석. gh pr view $PR + gh pr diff $PR 로 변경 파일 목록, 변경 라인 수, 영향 모듈을 요약해서 보고."

team-send 성재 "[PR #$PR] 코드 리뷰 수행. gh pr diff $PR 로 확인 후 /review 또는 자연어 리뷰. 관점: 코드 품질, 보안(인젝션·인증), 성능, 명세 일치. Severity 분류 + 구체적 수정 제안. gh pr review $PR 로 코멘트 등록."

echo ""
echo -e "${GREEN}✅ PR #$PR 리뷰 디스패치 완료${NC}"
echo "   결과 수신 후 은광이 사용자에게 통합 보고."
