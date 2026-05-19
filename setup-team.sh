#!/bin/bash
# setup-team.sh — Claude 멀티에이전트 팀 환경 자동 구성

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SESSION="team"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 모든 Claude 인스턴스를 프로젝트 루트에서 시작시켜야 CLAUDE.md / roles/ / workflows/ 를 인식한다.
WORKDIR="${WORKDIR:-$SCRIPT_DIR}"

# ── 팀원 메타: 이름 / 역할 파일 / 한 줄 설명 ───────────────
MEMBER_NAMES=("은광" "민혁" "창섭" "현식" "프니엘" "성재")
MEMBER_ROLES=("팀장" "아키텍트" "개발자" "UI/UX디자이너" "리서쳐" "QA·리뷰어")
MEMBER_ROLE_FILES=(
    "$SCRIPT_DIR/roles/eungwang.md"
    "$SCRIPT_DIR/roles/minhyuk.md"
    "$SCRIPT_DIR/roles/changseop.md"
    "$SCRIPT_DIR/roles/hyunsik.md"
    "$SCRIPT_DIR/roles/phaniel.md"
    "$SCRIPT_DIR/roles/seongjae.md"
)

# ── 유틸: 파인에 패턴이 나타날 때까지 대기 ──────────────────
wait_for_pane() {
    local pane="$1" pattern="$2" timeout="${3:-30}" waited=0
    while [ $waited -lt $timeout ]; do
        tmux capture-pane -t "$pane" -p 2>/dev/null | grep -q "$pattern" && return 0
        sleep 1; waited=$((waited + 1))
    done
    return 1
}

# ── 유틸: Claude 실행 + 다이얼로그 자동 처리 ────────────────
start_claude_in_pane() {
    local pane="$1" model="${2:-claude-sonnet-4-6}"
    local claude_bin; claude_bin="$(command -v claude)"

    tmux send-keys -t "$pane" C-c 2>/dev/null; sleep 0.3
    tmux send-keys -t "$pane" C-u 2>/dev/null; sleep 0.2

    tmux send-keys -t "$pane" \
        "cd \"$WORKDIR\" && unset CLAUDECODE && $claude_bin --model $model --dangerously-skip-permissions" Enter

    # 다이얼로그 1: trust folder → Enter
    wait_for_pane "$pane" "trust this folder" 20 && {
        tmux send-keys -t "$pane" Enter; sleep 1
    }

    # 다이얼로그 2: terms of service → Down + Enter
    wait_for_pane "$pane" "I accept" 20 && {
        tmux send-keys -t "$pane" Down; sleep 0.5
        tmux send-keys -t "$pane" Enter; sleep 1
    }

    # Claude 2.x 프롬프트 신호. 좁은 파인에서는 줄바꿈으로 긴 문자열이 잘릴 수 있어
    # 짧은 패턴을 OR로 결합. ❯ 프롬프트 + "bypass" 단어 + 모델명 중 하나라도 보이면 OK.
    local p="$pane" waited=0 timeout=60
    while [ $waited -lt $timeout ]; do
        if tmux capture-pane -t "$p" -p -S -200 2>/dev/null \
            | grep -qE "❯|bypass|Sonnet 4|Opus 4"; then
            return 0
        fi
        sleep 1; waited=$((waited + 1))
    done
    return 1
}

# ── 유틸: 부트스트랩 메시지 전송 ───────────────────────────
# 각 파인의 Claude에게 자기 정체와 따라야 할 파일을 명시적으로 주입한다.
# 이 단계가 없으면 6개 Claude가 모두 같은 CLAUDE.md를 보고도 "누가 누구"인지 모른다.
bootstrap_pane() {
    local pane="$1" name="$2" role="$3" role_file="$4"

    # 한 문장으로 짧게 — 컨텍스트 부담 줄이고 thinking 멈춤 방지.
    local msg="너는 ${name}(${role}, Pane ${pane##*.})이다. ${SCRIPT_DIR}/CLAUDE.md 와 ${role_file} 두 파일을 Read 도구로 읽고 모든 규칙을 따라라. 다 읽으면 한 줄만 출력: \"✅ 준비 완료 — ${name}(${role})\""

    # 한글 메시지 + Claude Code 입력창 동작 특성상 send-keys 한 번에 Enter가
    # 줄바꿈으로 처리되는 경우가 있다. 메시지 입력 후 sleep, Enter, sleep, Enter 추가.
    tmux send-keys -t "$pane" "$msg"
    sleep 1
    tmux send-keys -t "$pane" Enter
    sleep 0.5
    tmux send-keys -t "$pane" Enter
}

# ── [0/4] 사전 요구사항 확인 ────────────────────────────────
echo -e "${YELLOW}[0/4] 사전 요구사항 확인...${NC}"

MISSING=()
command -v tmux   &>/dev/null || MISSING+=("tmux (sudo apt install -y tmux)")
command -v claude &>/dev/null || MISSING+=("claude (npm install -g @anthropic-ai/claude-code)")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}❌ 누락된 의존성:${NC}"
    for m in "${MISSING[@]}"; do echo "   - $m"; done
    exit 1
fi

echo "  ✅ tmux $(tmux -V | awk '{print $2}')"
echo "  ✅ claude $(claude --version 2>/dev/null | head -1)"

# ── [1/4] 기존 세션 정리 ────────────────────────────────────
echo -e "\n${YELLOW}[1/4] 기존 세션 초기화...${NC}"
tmux has-session -t "$SESSION" 2>/dev/null && {
    tmux kill-session -t "$SESSION"
    echo "  기존 '$SESSION' 세션 종료"
}

# ── [2/4] TMUX 세션 & 레이아웃 구성 ────────────────────────
echo -e "\n${YELLOW}[2/4] TMUX 세션 & 레이아웃 구성...${NC}"

TERM_WIDTH=$(tput cols 2>/dev/null || echo 317)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 85)

tmux new-session -d -s "$SESSION" -x "$TERM_WIDTH" -y "$TERM_HEIGHT"

# 파인 5개 분할
tmux split-window -t "$SESSION:0.0" -h
tmux split-window -t "$SESSION:0.1" -h
tmux split-window -t "$SESSION:0.2" -h
tmux split-window -t "$SESSION:0.3" -h
tmux split-window -t "$SESSION:0.4" -h

# main-vertical 레이아웃 (팀장 왼쪽 넓게)
tmux select-layout -t "$SESSION:0" even-horizontal
tmux select-layout -t "$SESSION:0" main-vertical
tmux set-option -t "$SESSION" main-pane-width 158

# 파인 제목 표시 설정
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux set-option -t "$SESSION" allow-rename off

# 파인 이름 설정
tmux select-pane -t "$SESSION:0.0" -T "은광"
tmux select-pane -t "$SESSION:0.1" -T "민혁 아키텍트"
tmux select-pane -t "$SESSION:0.2" -T "창섭 개발자"
tmux select-pane -t "$SESSION:0.3" -T "현식 UI/UX디자이너"
tmux select-pane -t "$SESSION:0.4" -T "프니엘 리서쳐"
tmux select-pane -t "$SESSION:0.5" -T "성재 QA·리뷰어"

echo "  ✅ 레이아웃 구성 완료 (6 panes)"

# ── [3/4] Claude 자동 실행 + 부트스트랩 ────────────────────
echo -e "\n${YELLOW}[3/4] Claude 실행 + 역할 부트스트랩 중...${NC}"

MEMBER_MODELS=(
    "claude-sonnet-4-6"
    "claude-opus-4-7"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
    "claude-sonnet-4-6"
)

for pane in 0 1 2 3 4 5; do
    echo -n "  Pane $pane (${MEMBER_NAMES[$pane]} ${MEMBER_ROLES[$pane]}): "
    start_claude_in_pane "$SESSION:0.$pane" "${MEMBER_MODELS[$pane]}"

    if tmux capture-pane -t "$SESSION:0.$pane" -p -S -200 2>/dev/null \
        | grep -qE "❯|bypass|Sonnet 4|Opus 4"; then
        echo -ne "${GREEN}Claude 준비${NC} → 부트스트랩 송신..."
        bootstrap_pane "$SESSION:0.$pane" \
            "${MEMBER_NAMES[$pane]}" \
            "${MEMBER_ROLES[$pane]}" \
            "${MEMBER_ROLE_FILES[$pane]}"
        echo -e " ${GREEN}✅${NC}"
    else
        echo -e "${RED}⚠️  타임아웃 — 수동 확인 필요${NC}"
    fi
done

echo ""
echo -e "${CYAN}  ▶ 부트스트랩 응답(\"✅ 준비 완료 — {이름}\")을 각 파인에서 확인하세요.${NC}"
echo -e "${CYAN}  ▶ 일괄 점검: bash $SCRIPT_DIR/verify-roles.sh${NC}"

# ── [4/4] 완료 ──────────────────────────────────────────────
echo -e "\n${GREEN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║   ✅ 팀 환경 구성 완료!              ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# 터미널에서 직접 실행한 경우 자동 attach
[ -t 1 ] && tmux attach -t "$SESSION"

