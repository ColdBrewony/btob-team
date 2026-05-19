#!/bin/bash
# verify-roles.sh — 부트스트랩 후 각 팀원이 자기 역할을 제대로 인식했는지 점검
#
# 사용:
#   bash verify-roles.sh           # 자동 점검 (각 파인의 최근 출력에서 "✅ 준비 완료" 확인)
#   bash verify-roles.sh --ask     # 대화식 점검 (각 팀원에게 "너는 누구야?" 질문)

set -u

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SESSION="${TEAM_SESSION:-team}"
MODE="${1:-auto}"

NAMES=("은광" "민혁" "창섭" "현식" "프니엘" "성재")
ROLES=("팀장" "아키텍트" "개발자" "UI/UX디자이너" "리서쳐" "QA·리뷰어")

# ── 사전 점검 ────────────────────────────────────────────────
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo -e "${RED}❌ 세션 '$SESSION' 없음. setup-team.sh 먼저 실행.${NC}"
    exit 1
fi

PANE_COUNT=$(tmux list-panes -t "$SESSION:0" | wc -l | tr -d ' ')
if [ "$PANE_COUNT" -ne 6 ]; then
    echo -e "${RED}❌ 파인 수 이상: $PANE_COUNT / 6${NC}"
    exit 1
fi

echo -e "${CYAN}=== 역할 인식 점검 (mode=$MODE) ===${NC}\n"

# ── 모드 1: 자동 점검 (부트스트랩 응답 확인) ───────────────
auto_check() {
    local pass=0 fail=0

    for i in 0 1 2 3 4 5; do
        local name="${NAMES[$i]}" role="${ROLES[$i]}"
        local out
        out=$(tmux capture-pane -t "$SESSION:0.$i" -p -S -200 2>/dev/null || true)

        if echo "$out" | grep -q "✅ 준비 완료.*${name}"; then
            echo -e "  ${GREEN}✅${NC} Pane $i — $name ($role): 부트스트랩 응답 확인됨"
            pass=$((pass + 1))
        elif echo "$out" | grep -qi "준비.*${name}\|${name}.*준비"; then
            echo -e "  ${YELLOW}⚠️${NC}  Pane $i — $name ($role): 응답 형식 다름 (수동 확인 권장)"
            pass=$((pass + 1))
        else
            echo -e "  ${RED}❌${NC} Pane $i — $name ($role): 부트스트랩 응답 미확인"
            fail=$((fail + 1))
        fi
    done

    echo ""
    if [ "$fail" -eq 0 ]; then
        echo -e "${GREEN}✅ 전원 부트스트랩 응답 확인 — 팀 준비 완료${NC}"
        return 0
    else
        echo -e "${RED}❌ $fail 명 미응답. \`bash verify-roles.sh --ask\` 로 재점검 권장.${NC}"
        return 1
    fi
}

# ── 모드 2: 대화식 점검 (직접 질문) ──────────────────────────
ask_check() {
    echo "각 팀원에게 자기소개 요청 — 응답 대기 30초"
    echo ""

    for i in 0 1 2 3 4 5; do
        local name="${NAMES[$i]}" role="${ROLES[$i]}"
        echo -e "  ${CYAN}▶ Pane $i — $name 에게 자기소개 요청...${NC}"
        tmux send-keys -t "$SESSION:0.$i" \
            "한 줄로 자기소개해라. 형식: '나는 {이름}({역할}, Pane N) — 영역: {기본 영역}'" Enter
    done

    echo ""
    echo "응답 수집 중 (30초 대기)..."
    sleep 30

    echo ""
    echo -e "${CYAN}── 응답 결과 ──${NC}"
    local pass=0 fail=0

    for i in 0 1 2 3 4 5; do
        local name="${NAMES[$i]}" role="${ROLES[$i]}"
        local out
        out=$(tmux capture-pane -t "$SESSION:0.$i" -p -S -50 2>/dev/null || true)

        # 마지막 응답 영역에서 자기 이름과 역할 키워드 확인
        if echo "$out" | tail -30 | grep -q "$name" \
           && echo "$out" | tail -30 | grep -q "$role"; then
            echo -e "  ${GREEN}✅${NC} Pane $i — $name: 이름·역할 자기 인식 확인"
            pass=$((pass + 1))
        else
            echo -e "  ${RED}❌${NC} Pane $i — $name: 자기 인식 실패"
            echo "    최근 출력:"
            echo "$out" | tail -10 | sed 's/^/      /'
            fail=$((fail + 1))
        fi
    done

    echo ""
    if [ "$fail" -eq 0 ]; then
        echo -e "${GREEN}✅ 전원 자기 인식 정상${NC}"
        return 0
    else
        echo -e "${RED}❌ $fail 명 인식 실패. roles/ 파일 경로와 부트스트랩 메시지 점검 필요.${NC}"
        return 1
    fi
}

case "$MODE" in
    --ask|ask)
        ask_check
        ;;
    auto|*)
        auto_check
        ;;
esac
