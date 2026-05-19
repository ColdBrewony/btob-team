#!/bin/bash
# daily-report.sh — 일일 팀 보고 워크플로우 (책 7-5 워크플로우 4)
#
# 모든 팀원에게 현황 요청 → 일정 시간 대기 → 출력 캡처 → 종합 보고
#
# 사용: bash daily-report.sh [대기초수]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ensure_session

WAIT_SECS="${1:-60}"

wf-header "WF-DAILY-REPORT" "전 팀원 현황 수집"

# ── Phase 1: 현황 요청 (브로드캐스트) ──────────────
phase-header 1 "현황 요청"

for who in 민혁 창섭 현식 프니엘 성재; do
    team-send "$who" "오늘 작업 현황을 다음 4줄로 요약: 1)완료한 일 2)진행 중 3)막힌 점 4)내일 할 일"
    sleep 0.5
done

echo ""
echo "  ${WAIT_SECS}초 대기 (각 팀원 응답 시간)..."
sleep "$WAIT_SECS"

# ── Phase 2: 응답 캡처 + 종합 ─────────────────────
phase-header 2 "응답 캡처 + 종합 보고"

REPORT_FILE="/tmp/team-daily-$(date +%Y%m%d-%H%M).md"
{
    echo "# 일일 팀 보고 — $(date '+%Y-%m-%d %H:%M')"
    echo ""
    for who in 민혁 창섭 현식 프니엘 성재; do
        echo "## 👤 $who"
        echo '```'
        capture-pane "$who" 30
        echo '```'
        echo ""
    done
} > "$REPORT_FILE"

echo ""
echo -e "${GREEN}✅ 일일 보고 작성 완료${NC}"
echo "   파일: $REPORT_FILE"
echo ""
echo "── 미리보기 ──"
head -50 "$REPORT_FILE"
