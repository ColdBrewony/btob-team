#!/bin/bash
# workflows/lib/common.sh — 워크플로우 공통 헬퍼
#
# 다른 워크플로우 스크립트에서 다음과 같이 source 한다.
#   source "$(dirname "$0")/lib/common.sh"

SESSION="${TEAM_SESSION:-team}"

# 팀원 → 파인 매핑
declare -A PANE=(
    [은광]=0   [팀장]=0
    [민혁]=1   [아키텍트]=1
    [창섭]=2   [개발자]=2
    [현식]=3   [디자이너]=3   [UI]=3
    [프니엘]=4 [리서쳐]=4
    [성재]=5   [리뷰어]=5    [QA]=5
)

# 컬러
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── 세션 점검 ──────────────────────────────────────
ensure_session() {
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo -e "${RED}❌ tmux 세션 '$SESSION' 없음. setup-team.sh 먼저 실행.${NC}" >&2
        exit 1
    fi
}

# ── 메시지 송신 ────────────────────────────────────
# 사용: team-send 창섭 "[TASK-12] 로그인 함수 구현 — 영역: src/auth/"
team-send() {
    local who="$1"
    shift
    local pane="${PANE[$who]:-}"
    if [ -z "$pane" ]; then
        echo -e "${RED}❌ 알 수 없는 팀원: $who${NC}" >&2
        return 1
    fi
    echo -e "${CYAN}▶ $who (Pane $pane)${NC}: $*"
    tmux send-keys -t "$SESSION:0.$pane" "$who, $*" Enter
}

# ── 모든 팀원에게 브로드캐스트 ─────────────────────
broadcast() {
    local msg="$*"
    for who in 민혁 창섭 현식 프니엘 성재; do
        team-send "$who" "$msg"
        sleep 0.3
    done
}

# ── 팀원 파인 출력 캡처 (마지막 N줄) ──────────────
capture-pane() {
    local who="$1"
    local lines="${2:-20}"
    local pane="${PANE[$who]:-}"
    [ -n "$pane" ] && tmux capture-pane -t "$SESSION:0.$pane" -p | tail -n "$lines"
}

# ── 패턴이 나타날 때까지 대기 ──────────────────────
# 사용: wait-pane 창섭 "구현 완료" 600
wait-pane() {
    local who="$1" pattern="$2" timeout="${3:-300}" waited=0
    local pane="${PANE[$who]:-}"
    [ -z "$pane" ] && return 1
    while [ $waited -lt $timeout ]; do
        tmux capture-pane -t "$SESSION:0.$pane" -p 2>/dev/null \
            | grep -q "$pattern" && return 0
        sleep 2
        waited=$((waited + 2))
    done
    return 1
}

# ── Phase 헤더 ────────────────────────────────────
phase-header() {
    local n="$1" name="$2"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Phase $n — $name${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
}

# ── 사용자 요약 헤더 ──────────────────────────────
wf-header() {
    local wf_id="$1" payload="$2"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Workflow: $wf_id${NC}"
    echo -e "${YELLOW}║  Payload : $payload${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
}
