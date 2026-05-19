#!/bin/bash
# check-team.sh — 팀 세션 상태 점검 및 자동 복구
#
# 사용:
#   bash check-team.sh           # 일회성 점검
#   crontab:  */10 * * * * /Users/n3n/Desktop/jiwon/kjw/check-team.sh >> /tmp/team-check.log 2>&1

set -u

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SESSION="team"
EXPECTED_PANES=6
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/setup-team.sh"

TITLES=(
    "은광"
    "민혁 아키텍트"
    "창섭 개발자"
    "현식 UI/UX디자이너"
    "프니엘 리서쳐"
    "성재 QA·리뷰어"
)

MODELS=(
    "claude-sonnet-4-6"
    "claude-opus-4-7"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
)

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

echo -e "\n=== [$(timestamp)] 팀 세션 점검 시작 ==="

# ── 1. 세션 존재 여부 ────────────────────────────────────────
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${YELLOW}세션 '$SESSION' 없음 — setup-team.sh 재실행${NC}"
    if [ -x "$SETUP_SCRIPT" ] || [ -f "$SETUP_SCRIPT" ]; then
        bash "$SETUP_SCRIPT"
        exit $?
    else
        echo -e "${RED}❌ setup 스크립트를 찾지 못함: $SETUP_SCRIPT${NC}"
        exit 1
    fi
fi

# ── 2. 파인 수 점검 ──────────────────────────────────────────
CURRENT_PANES=$(tmux list-panes -t "$SESSION:0" 2>/dev/null | wc -l | tr -d ' ')

if [ "$CURRENT_PANES" -ne "$EXPECTED_PANES" ]; then
    echo -e "${RED}⚠️  파인 수 불일치: $CURRENT_PANES / $EXPECTED_PANES${NC}"
    echo "수동 복구 또는 setup-team.sh 재실행 권장"
    echo "현재 파인 상태:"
    tmux list-panes -t "$SESSION:0" -F "  Pane #{pane_index}: #{pane_title} (#{pane_current_command})"
    exit 1
fi

# ── 3. 파인별 Claude 실행 상태 ─────────────────────────────
NEEDS_FIX=0

for i in 0 1 2 3 4 5; do
    PANE_CMD=$(tmux list-panes -t "$SESSION:0" \
        -F "#{pane_index} #{pane_current_command}" 2>/dev/null \
        | awk -v idx="$i" '$1==idx {print $2}')

    NAME="${TITLES[$i]}"

    case "$PANE_CMD" in
        claude|node)
            echo -e "  ${GREEN}✅${NC} Pane $i ($NAME): 정상 ($PANE_CMD)"
            ;;
        "")
            echo -e "  ${RED}❌${NC} Pane $i ($NAME): 응답 없음 — 수동 확인 필요"
            NEEDS_FIX=1
            ;;
        *)
            echo -e "  ${YELLOW}⚠️${NC}  Pane $i ($NAME): Claude 미실행 ($PANE_CMD) — 재시작"
            tmux send-keys -t "$SESSION:0.$i" \
                "claude --model ${MODELS[$i]} --dangerously-skip-permissions" Enter
            NEEDS_FIX=1
            ;;
    esac
done

# ── 4. 결과 ──────────────────────────────────────────────────
if [ "$NEEDS_FIX" -eq 0 ]; then
    echo -e "${GREEN}=== 점검 완료: 모든 파인 정상 ===${NC}"
else
    echo -e "${YELLOW}=== 점검 완료: 일부 파인 복구 시도 — 다음 실행에서 재확인 ===${NC}"
fi

# ── 5. 메모리 사용량 (참고) ─────────────────────────────────
if command -v ps >/dev/null 2>&1; then
    TOTAL_MB=$(ps aux | grep -E '[c]laude' | awk '{sum += $6} END {printf "%.0f", sum/1024}')
    [ -n "$TOTAL_MB" ] && [ "$TOTAL_MB" -gt 0 ] && \
        echo "Claude 프로세스 총 메모리: ${TOTAL_MB} MB"
fi
