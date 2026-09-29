#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  SmVnc - Idle Monitor Daemon
#  Automatically stops containers after inactivity
#
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Repo   : github.com/MehmudHub/SmVnc
#  License: MIT
#
#  ─── কীভাবে কাজ করে ───
#  ১. প্রতি ৩০ সেকেন্ডে প্রতিটি কন্টেইনার চেক করে
#  ২. VNC পোর্টে কানেকশন আছে কি না দেখে
#  ৩. কানেকশন না থাকলে টাইমার শুরু করে
#  ৪. IDLE_TIMEOUT পার হলে কন্টেইনার বন্ধ করে দেয়
#
#  ─── ইউজ ───
#    ./idle-monitor.sh start     # ডেমন শুরু
#    ./idle-monitor.sh stop      # ডেমন বন্ধ
#    ./idle-monitor.sh status    # স্ট্যাটাস
#    ./idle-monitor.sh run       # ফরগ্রাউন্ডে চালাও (ডিবাগ)
#    ./idle-monitor.sh check     # একবার চেক করো (manual trigger)
# ═══════════════════════════════════════════════════════════

set -o pipefail

# ─────────────────────────────────────────────
#  Paths
# ─────────────────────────────────────────────
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$BASE_DIR/config/users.conf"
DATA_DIR="$BASE_DIR/data"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/SmVnc.log"
IDLE_LOG="$LOG_DIR/idle-monitor.log"
PID_DIR="$BASE_DIR/.run"
STATE_DIR="$PID_DIR/idle-state"

# ─────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────
IDLE_TIMEOUT="${SMVNC_IDLE_TIMEOUT:-600}"   # সেকেন্ডে (ডিফল্ট: ১০ মিনিট)
CHECK_INTERVAL="${SMVNC_CHECK_INTERVAL:-30}" # কত সেকেন্ড পরপর চেক
LOG_ROTATE_DAYS=7                            # ৭ দিন পর পুরনো লগ ডিলিট
PORT_OFFSET=10000                            # External + 10000 = Internal

# ─────────────────────────────────────────────
#  Colors
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════
#  LOGGING
# ═══════════════════════════════════════════════════════════

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$IDLE_LOG"
    echo "$msg" >> "$LOG_FILE"
}

log_console() {
    echo -e "  ${CYAN}[$(date '+%H:%M:%S')]${NC} $1"
}

ok()    { echo -e "  ${GREEN}[✓]${NC} $1"; }
err()   { echo -e "  ${RED}[!]${NC} $1" >&2; }
info()  { echo -e "  ${CYAN}[i]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[~]${NC} $1"; }

# ═══════════════════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════════════════

container_name() {
    echo "smvnc-$1"
}

internal_port() {
    echo $(( $1 + PORT_OFFSET ))
}

is_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -q "^$(container_name "$1")$"
}

# ─── পোর্টে কতগুলো কানেকশন আছে ───
# Return: connection count
count_connections() {
    local port="$1"
    ss -tn 2>/dev/null | grep -c ":${port} " || echo 0
}

# ─── কন্টেইনার বন্ধ করা ───
stop_container() {
    local user="$1"
    local cname
    cname=$(container_name "$user")

    if is_running "$user"; then
        podman stop "$cname" &>/dev/null
        return 0
    fi
    return 1
}

# ─── স্টেট ফাইল পাথ ───
state_file() {
    echo "$STATE_DIR/$1.last_active"
}

# ─── শেষ সক্রিয়তার সময় পড়া ───
get_last_active() {
    local file
    file=$(state_file "$1")
    if [ -f "$file" ]; then
        cat "$file"
    else
        echo "0"
    fi
}

# ─── শেষ সক্রিয়তার সময় সেভ করা ───
set_last_active() {
    local user="$1"
    local ts="${2:-$(date +%s)}"
    echo "$ts" > "$(state_file "$user")"
}

# ─── সময় ফরম্যাট ───
format_duration() {
    local secs="$1"
    local mins=$((secs / 60))
    local hours=$((mins / 60))

    if [ "$hours" -gt 0 ]; then
        echo "${hours}h $((mins % 60))m"
    elif [ "$mins" -gt 0 ]; then
        echo "${mins}m $((secs % 60))s"
    else
        echo "${secs}s"
    fi
}

# ═══════════════════════════════════════════════════════════
#  IDLE CHECK LOGIC
# ═══════════════════════════════════════════════════════════

# ─── একটি ইউজারের নিষ্ক্রিয়তা চেক ───
check_user_idle() {
    local user="$1"
    local ext_port="$2"
    local int_port
    int_port=$(internal_port "$ext_port")

    if ! is_running "$user"; then
        # কন্টেইনার চলছে না → স্টেট ফাইল ডিলিট
        rm -f "$(state_file "$user")"
        return 0
    fi

    local connections
    connections=$(count_connections "$int_port")

    if [ "$connections" -gt 0 ]; then
        # কানেকশন আছে → টাইমার রিসেট
        set_last_active "$user" "$(date +%s)"
        return 0
    fi

    # কানেকশন নেই → টাইমার চেক
    local last_active
    last_active=$(get_last_active "$user")
    local now
    now=$(date +%s)

    if [ "$last_active" -eq 0 ]; then
        # প্রথমবার দেখা → টাইমার শুরু
        set_last_active "$user" "$now"
        return 0
    fi

    local idle_secs=$((now - last_active))

    if [ "$idle_secs" -ge "$IDLE_TIMEOUT" ]; then
        log_console "😴 ${BOLD}$user${NC} idle for ${BOLD}$(format_duration "$idle_secs")${NC} → sleeping"
        if stop_container "$user"; then
            log "IDLE-STOP: $user (idle $(format_duration "$idle_secs"))"
            rm -f "$(state_file "$user")"
        fi
    fi
}

# ─── সব ইউজার চেক ───
check_all_users() {
    if [ ! -s "$CONFIG_FILE" ]; then
        return 0
    fi

    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        check_user_idle "$user" "$port"
    done < "$CONFIG_FILE"
}

# ═══════════════════════════════════════════════════════════
#  LOG ROTATION
# ═══════════════════════════════════════════════════════════

rotate_logs() {
    [ ! -f "$IDLE_LOG" ] && return

    # লগ ফাইল কত দিন পুরনো
    local last_mod
    last_mod=$(stat -c %Y "$IDLE_LOG" 2>/dev/null || stat -f %m "$IDLE_LOG" 2>/dev/null)
    local now
    now=$(date +%s)
    local age_days=$(( (now - last_mod) / 86400 ))

    if [ "$age_days" -ge "$LOG_ROTATE_DAYS" ]; then
        local backup="$IDLE_LOG.$(date +%Y%m%d)"
        mv "$IDLE_LOG" "$backup"
        touch "$IDLE_LOG"
        log "LOG ROTATED: $backup"
    fi

    # ৭ দিনের বেশি পুরনো ব্যাকআপ ডিলিট
    find "$LOG_DIR" -name "idle-monitor.log.*" -mtime +$LOG_ROTATE_DAYS -delete 2>/dev/null
}

# ═══════════════════════════════════════════════════════════
#  CLEANUP
# ═══════════════════════════════════════════════════════════

cleanup() {
    log "DAEMON STOPPED"
    rm -f "$PID_DIR/idle-monitor.pid"
    exit 0
}

# ═══════════════════════════════════════════════════════════
#  MAIN LOOP
# ═══════════════════════════════════════════════════════════

run_loop() {
    mkdir -p "$PID_DIR" "$STATE_DIR" "$LOG_DIR"

    log "IDLE MONITOR STARTED (timeout: ${IDLE_TIMEOUT}s, interval: ${CHECK_INTERVAL}s)"

    # SIGINT/SIGTERM হ্যান্ডলিং
    trap cleanup SIGINT SIGTERM

    local loop_count=0
    local rotate_every=$((3600 / CHECK_INTERVAL))  # প্রতি ঘণ্টায় লগ রোটেট

    while true; do
        check_all_users

        loop_count=$((loop_count + 1))

        # প্রতি ঘণ্টায় লগ রোটেট
        if [ $((loop_count % rotate_every)) -eq 0 ]; then
            rotate_logs
        fi

        sleep "$CHECK_INTERVAL"
    done
}

# ═══════════════════════════════════════════════════════════
#  COMMANDS
# ═══════════════════════════════════════════════════════════

# ─── Start ───
cmd_start() {
    mkdir -p "$PID_DIR" "$STATE_DIR" "$LOG_DIR"

    # আগের ডেমন চলছে কি না
    if [ -f "$PID_DIR/idle-monitor.pid" ]; then
        local oldpid
        oldpid=$(cat "$PID_DIR/idle-monitor.pid")
        if kill -0 "$oldpid" 2>/dev/null; then
            warn "Idle monitor already running (pid $oldpid)"
            exit 0
        fi
        rm -f "$PID_DIR/idle-monitor.pid"
    fi

    # Dependency check
    if ! command -v podman &>/dev/null; then
        err "podman not found"
        exit 1
    fi

    if ! command -v ss &>/dev/null; then
        err "ss (iproute) not found"
        exit 1
    fi

    echo ""
    echo -e "  ${BOLD}${CYAN}▶ SmVnc Idle Monitor${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""

    # ব্যাকগ্রাউন্ডে চালু
    nohup "$0" run &>/dev/null &
    local pid=$!
    echo "$pid" > "$PID_DIR/idle-monitor.pid"

    sleep 1

    if kill -0 "$pid" 2>/dev/null; then
        ok "Idle monitor started (pid $pid)"
        echo -e "  ${CYAN}▸ Timeout       :${NC} $(format_duration "$IDLE_TIMEOUT")"
        echo -e "  ${CYAN}▸ Check every   :${NC} ${CHECK_INTERVAL}s"
        echo -e "  ${CYAN}▸ Log file      :${NC} $IDLE_LOG"
        echo ""
        echo -e "  ${YELLOW}[i]${NC} Stop with: ${BOLD}./idle-monitor.sh stop${NC}"
    else
        err "Failed to start idle monitor"
        exit 1
    fi
    echo ""
}

# ─── Stop ───
cmd_stop() {
    if [ ! -f "$PID_DIR/idle-monitor.pid" ]; then
        warn "Idle monitor is not running"
        exit 0
    fi

    local pid
    pid=$(cat "$PID_DIR/idle-monitor.pid")

    if ! kill -0 "$pid" 2>/dev/null; then
        warn "Process $pid is not alive (stale pid file)"
        rm -f "$PID_DIR/idle-monitor.pid"
        exit 0
    fi

    info "Stopping idle monitor (pid $pid)..."
    kill "$pid" 2>/dev/null

    local waited=0
    while [ $waited -lt 5 ]; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
        warn "Force killing..."
        kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$PID_DIR/idle-monitor.pid"
    ok "Idle monitor stopped"
    log "DAEMON STOPPED"
}

# ─── Status ───
cmd_status() {
    echo ""
    echo -e "  ${BOLD}${CYAN}▶ Idle Monitor Status${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""

    if [ -f "$PID_DIR/idle-monitor.pid" ]; then
        local pid
        pid=$(cat "$PID_DIR/idle-monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            ok "Daemon is ${GREEN}RUNNING${NC} (pid $pid)"
        else
            warn "Daemon is ${RED}STOPPED${NC} (stale pid file)"
        fi
    else
        warn "Daemon is ${RED}NOT RUNNING${NC}"
    fi

    echo ""
    echo -e "  ${BOLD}Configuration:${NC}"
    echo -e "    Timeout      : $(format_duration "$IDLE_TIMEOUT")"
    echo -e "    Check every  : ${CHECK_INTERVAL}s"
    echo -e "    Log file     : $IDLE_LOG"
    echo ""

    # প্রতিটি ইউজারের অবস্থা
    echo -e "  ${BOLD}User Status:${NC}"

    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "    ${DIM}No users registered${NC}"
    else
        while IFS=: read -r user port; do
            [ -z "$user" ] && continue

            if is_running "$user"; then
                local last_active
                last_active=$(get_last_active "$user")
                local idle_info=""

                if [ "$last_active" -gt 0 ]; then
                    local idle_secs=$(( $(date +%s) - last_active ))
                    idle_info=" ${DIM}(idle $(format_duration "$idle_secs"))${NC}"
                fi

                echo -e "    ${GREEN}●${NC} ${BOLD}$user${NC} ${DIM}(port $port)${NC}${idle_info}"
            else
                echo -e "    ${RED}○${NC} ${DIM}$user (port $port) — stopped${NC}"
            fi
        done < "$CONFIG_FILE"
    fi

    echo ""
}

# ─── Run (foreground, for debug) ───
cmd_run() {
    run_loop
}

# ─── Check (one-time, manual trigger) ───
cmd_check() {
    echo ""
    echo -e "  ${BOLD}${CYAN}▶ One-time Idle Check${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        warn "No users registered"
        exit 0
    fi

    while IFS=: read -r user port; do
        [ -z "$user" ] && continue

        local int_port
        int_port=$(internal_port "$port")

        if ! is_running "$user"; then
            echo -e "    ${RED}○${NC} $user ${DIM}— not running${NC}"
            continue
        fi

        local connections
        connections=$(count_connections "$int_port")
        local last_active
        last_active=$(get_last_active "$user")
        local idle_secs=0

        if [ "$last_active" -gt 0 ]; then
            idle_secs=$(( $(date +%s) - last_active ))
        fi

        echo -e "    ${GREEN}●${NC} ${BOLD}$user${NC}"
        echo -e "       ${DIM}Connections : $connections${NC}"
        echo -e "       ${DIM}Idle time   : $(format_duration "$idle_secs")${NC}"
        echo -e "       ${DIM}Timeout     : $(format_duration "$IDLE_TIMEOUT")${NC}"

        if [ "$connections" -eq 0 ] && [ "$idle_secs" -ge "$IDLE_TIMEOUT" ]; then
            echo -e "       ${YELLOW}→ Would stop (idle >= timeout)${NC}"
        fi
    done < "$CONFIG_FILE"

    echo ""
    read -p "  Run actual check now? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo ""
        check_all_users
        ok "Check completed"
    fi
    echo ""
}

# ─── Help ───
cmd_help() {
    echo ""
    echo -e "  ${BOLD}${CYAN}SmVnc Idle Monitor${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${BOLD}Usage:${NC} ./idle-monitor.sh <command>"
    echo ""
    echo -e "  ${GREEN}start${NC}     Start daemon in background"
    echo -e "  ${GREEN}stop${NC}      Stop daemon"
    echo -e "  ${GREEN}status${NC}    Show daemon and user status"
    echo -e "  ${GREEN}check${NC}     Interactive one-time check"
    echo -e "  ${GREEN}run${NC}       Run in foreground (debug)"
    echo -e "  ${GREEN}help${NC}      Show this help"
    echo ""
    echo -e "  ${BOLD}Environment Variables:${NC}"
    echo -e "    SMVNC_IDLE_TIMEOUT    Seconds of inactivity (default: 600)"
    echo -e "    SMVNC_CHECK_INTERVAL  Check interval in seconds (default: 30)"
    echo ""
    echo -e "  ${BOLD}Example:${NC}"
    echo -e "    SMVNC_IDLE_TIMEOUT=300 ./idle-monitor.sh start"
    echo ""
}

# ═══════════════════════════════════════════════════════════
#  MAIN ENTRYPOINT
# ═══════════════════════════════════════════════════════════

if [ $# -eq 0 ]; then
    cmd_help
    exit 0
fi

case "$1" in
    start)      cmd_start ;;
    stop)       cmd_stop ;;
    status)     cmd_status ;;
    check)      cmd_check ;;
    run)        cmd_run ;;
    help|--help|-h) cmd_help ;;
    *)
        err "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
