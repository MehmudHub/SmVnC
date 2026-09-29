#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  SmVnc - Auto Wake on Connect
#  On-demand container starter using socat
#
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Repo   : github.com/MehmudHub/SmVnc
#  License: MIT
#
#  ─── কীভাবে কাজ করে ───
#  ১. প্রতিটি ইউজারের জন্য socat একটি হালকা listener চালায়
#  ২. VNC client কানেক্ট করলে socat কন্টেইনার চালু করে
#  ৩. VNC server বুট হওয়ার জন্য অপেক্ষা করে
#  ৪. ট্রাফিক ফরওয়ার্ড করে
#
#  ─── পোর্ট স্কিম ───
#  External (client side)  : 5901, 5902, 5903... (users.conf এ যেভাবে আছে)
#  Internal (container side): external + 10000 = 15901, 15902...
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
WAKE_LOG="$LOG_DIR/auto-wake.log"
PID_DIR="$BASE_DIR/.run"
IMAGE_NAME="smvnc-modern:latest"
INTERNAL_VNC_PORT=5901    # ইমেজের ভেতরে VNC যেই পোর্টে চলে
IDLE_TIMEOUT=600          # ১০ মিনিট (সেকেন্ডে) — এই সময় নিষ্ক্রিয় থাকলে কন্টেইনার বন্ধ
PORT_OFFSET=10000         # External পোর্ট + 10000 = Internal পোর্ট

# ─────────────────────────────────────────────
#  Colors
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════
#  LOGGING
# ═══════════════════════════════════════════════════════════

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$WAKE_LOG"
    echo "$msg" >> "$LOG_FILE"
}

log_console() {
    echo -e "  ${CYAN}[$(date '+%H:%M:%S')]${NC} $1"
}

err() {
    echo -e "  ${RED}[!]${NC} $1" >&2
    log "ERROR: $1"
}

ok() {
    echo -e "  ${GREEN}[✓]${NC} $1"
    log "OK: $1"
}

info() {
    echo -e "  ${CYAN}[i]${NC} $1"
}

warn() {
    echo -e "  ${YELLOW}[~]${NC} $1"
    log "WARN: $1"
}

# ═══════════════════════════════════════════════════════════
#  HELPERS
# ═══════════════════════════════════════════════════════════

get_local_ip() {
    local ip
    ip=$(ip -4 -o addr show scope global 2>/dev/null | \
         grep -Ev "tun|tap|ppp|wg" | \
         awk '{print $4}' | cut -d/ -f1 | head -n1)
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

internal_port() {
    echo $(( $1 + PORT_OFFSET ))
}

container_name() {
    echo "smvnc-$1"
}

is_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -q "^$(container_name "$1")$"
}

is_created() {
    podman ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^$(container_name "$1")$"
}

# ═══════════════════════════════════════════════════════════
#  CONTAINER LIFECYCLE
# ═══════════════════════════════════════════════════════════

# ─── কন্টেইনার চালু করা (ইন্টারনাল পোর্টে) ───
wake_container() {
    local user="$1"
    local ext_port="$2"
    local int_port
    int_port=$(internal_port "$ext_port")
    local cname
    cname=$(container_name "$user")
    local data_path="$DATA_DIR/$user"

    mkdir -p "$data_path"

    if is_running "$user"; then
        log_console "Container ${BOLD}$user${NC} already running"
        return 0
    fi

    log_console "🔵 Waking container ${BOLD}$user${NC} (ext:$ext_port → int:$int_port)"

    if is_created "$user"; then
        # পুরনো কন্টেইনার আছে → পোর্ট আপডেট করে চালু করা
        podman rm -f "$cname" &>/dev/null
    fi

    podman run -d --name "$cname" \
        -p "${int_port}:${INTERNAL_VNC_PORT}" \
        -v "$data_path:/headless/Desktop" \
        --memory="1.5g" --cpus="1.0" \
        "$IMAGE_NAME" &>/dev/null

    if [ $? -ne 0 ]; then
        err "Failed to wake container: $user"
        return 1
    fi

    ok "Container $user started"
    log "AUTO-WAKE: $user started (ext:$ext_port → int:$int_port)"
    return 0
}

# ─── কন্টেইনার বন্ধ করা ───
sleep_container() {
    local user="$1"
    local cname
    cname=$(container_name "$user")

    if is_running "$user"; then
        podman stop "$cname" &>/dev/null
        ok "Container $user stopped (idle)"
        log "AUTO-SLEEP: $user stopped after idle timeout"
    fi
}

# ─── VNC সার্ভার বুট হওয়ার জন্য অপেক্ষা ───
wait_for_vnc() {
    local user="$1"
    local int_port="$2"
    local max_wait=30
    local waited=0

    log_console "⏳ Waiting for VNC server on port $int_port..."

    while [ $waited -lt $max_wait ]; do
        if ss -tuln 2>/dev/null | grep -q ":${int_port} "; then
            log_console "✅ VNC server is ready (${waited}s)"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done

    err "VNC server did not start within ${max_wait}s"
    return 1
}

# ═══════════════════════════════════════════════════════════
#  WAKE HANDLER (socat যাকে কল করবে)
# ═══════════════════════════════════════════════════════════

# ─── এটি socat EXEC দিয়ে কল হয় যখন কেউ কানেক্ট করে ───
handle_connection() {
    local user="$1"
    local ext_port="$2"
    local int_port
    int_port=$(internal_port "$ext_port")

    log "CONNECT: $user from client (ext:$ext_port)"

    # কন্টেইনার চালু করো
    wake_container "$user" "$ext_port" || exit 1

    # VNC বুট হওয়ার জন্য অপেক্ষা
    wait_for_vnc "$user" "$int_port" || exit 1

    # ট্রাফিক ফরওয়ার্ড করো
    log_console "🔀 Forwarding connection to container"
    exec socat - TCP:127.0.0.1:$int_port
}

# ═══════════════════════════════════════════════════════════
#  IDLE MONITOR (ব্যাকগ্রাউন্ড ডেমন)
# ═══════════════════════════════════════════════════════════

# ─── নিষ্ক্রিয় কন্টেইনার চেক করে বন্ধ করা ───
idle_monitor() {
    log "Idle monitor started (timeout: ${IDLE_TIMEOUT}s)"

    while true; do
        sleep 60   # প্রতি মিনিটে চেক

        [ ! -s "$CONFIG_FILE" ] && continue

        while IFS=: read -r user port; do
            [ -z "$user" ] && continue

            if is_running "$user"; then
                local int_port
                int_port=$(internal_port "$port")

                # কন্টেইনারে কতগুলো কানেকশন আছে চেক করো
                local connections
                connections=$(ss -tn 2>/dev/null | grep -c ":${int_port} " || echo 0)

                if [ "$connections" -eq 0 ]; then
                    # শেষ কানেকশন থেকে কত সময় হয়েছে সেটা চেক করো
                    local last_active_file="$PID_DIR/${user}.last_active"
                    local now
                    now=$(date +%s)

                    if [ ! -f "$last_active_file" ]; then
                        echo "$now" > "$last_active_file"
                    else
                        local last_active
                        last_active=$(cat "$last_active_file")
                        local diff=$((now - last_active))

                        if [ "$diff" -ge "$IDLE_TIMEOUT" ]; then
                            log_console "😴 $user idle for $((diff/60))m — sleeping"
                            sleep_container "$user"
                            rm -f "$last_active_file"
                        fi
                    fi
                else
                    # কানেকশন আছে → last_active আপডেট করো
                    date +%s > "$PID_DIR/${user}.last_active"
                fi
            fi
        done < "$CONFIG_FILE"
    done
}

# ═══════════════════════════════════════════════════════════
#  LISTENER MANAGEMENT
# ═══════════════════════════════════════════════════════════

# ─── একটি ইউজারের জন্য socat listener চালু ───
start_listener() {
    local user="$1"
    local port="$2"
    local pidfile="$PID_DIR/${user}.socat.pid"

    # আগের লিসেনার বন্ধ করো
    stop_listener "$user"

    # নতুন socat প্রসেস চালু করো (ব্যাকগ্রাউন্ডে)
    socat TCP-LISTEN:$port,fork,reuseaddr \
        EXEC:"$BASE_DIR/scripts/auto-wake.sh handle $user $port" \
        &>/dev/null &

    local pid=$!
    echo "$pid" > "$pidfile"
    log "LISTENER: $user on port $port (pid $pid)"
}

# ─── একটি ইউজারের লিসেনার বন্ধ ───
stop_listener() {
    local user="$1"
    local pidfile="$PID_DIR/${user}.socat.pid"

    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            sleep 0.5
            kill -9 "$pid" 2>/dev/null
        fi
        rm -f "$pidfile"
        log "LISTENER STOPPED: $user"
    fi
}

# ─── সব লিসেনার বন্ধ ───
stop_all_listeners() {
    if [ -d "$PID_DIR" ]; then
        for pidfile in "$PID_DIR"/*.socat.pid; do
            [ ! -f "$pidfile" ] && continue
            local pid
            pid=$(cat "$pidfile")
            kill "$pid" 2>/dev/null
            kill -9 "$pid" 2>/dev/null
            rm -f "$pidfile"
        done
    fi
    log "ALL LISTENERS STOPPED"
}

# ═══════════════════════════════════════════════════════════
#  DEPENDENCY CHECK
# ═══════════════════════════════════════════════════════════

check_dependencies() {
    local missing=()

    command -v socat &>/dev/null || missing+=("socat")
    command -v podman &>/dev/null || missing+=("podman")
    command -v ss &>/dev/null || missing+=("iproute")

    if [ ${#missing[@]} -gt 0 ]; then
        err "Missing dependencies: ${missing[*]}"
        info "Install with: sudo dnf install ${missing[*]}"
        return 1
    fi

    if ! podman image exists "$IMAGE_NAME" 2>/dev/null; then
        err "Image '$IMAGE_NAME' not found"
        info "Run: ./setup.sh"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════
#  MAIN COMMANDS
# ═══════════════════════════════════════════════════════════

# ─── ডেমন শুরু করা ───
cmd_start() {
    check_dependencies || exit 1

    mkdir -p "$PID_DIR" "$LOG_DIR"

    if [ -f "$PID_DIR/daemon.pid" ]; then
        local oldpid
        oldpid=$(cat "$PID_DIR/daemon.pid")
        if kill -0 "$oldpid" 2>/dev/null; then
            warn "Auto-wake daemon already running (pid $oldpid)"
            exit 0
        fi
        rm -f "$PID_DIR/daemon.pid"
    fi

    echo ""
    echo -e "  ${BOLD}${CYAN}▶ SmVnc Auto-Wake Daemon${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        err "No users registered. Add users first via SmVnc.sh"
        exit 1
    fi

    info "Starting listeners for each user..."
    echo ""

    local count=0
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        start_listener "$user" "$port"
        echo -e "    ${GREEN}●${NC} ${BOLD}$user${NC} ${DIM}→ port $port${NC}"
        count=$((count + 1))
    done < "$CONFIG_FILE"

    echo ""
    ok "Started $count listener(s)"
    echo ""

    # Idle monitor ব্যাকগ্রাউন্ডে চালু
    idle_monitor &>/dev/null &
    echo $! > "$PID_DIR/idle-monitor.pid"
    ok "Idle monitor started (pid $!)"

    # Daemon PID সেভ
    echo $$ > "$PID_DIR/daemon.pid"

    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}▸ Host IP       :${NC} $(get_local_ip)"
    echo -e "  ${CYAN}▸ Idle Timeout  :${NC} $((IDLE_TIMEOUT / 60)) minutes"
    echo -e "  ${CYAN}▸ Log File      :${NC} $WAKE_LOG"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${YELLOW}[i]${NC} এখন ফোনের VNC অ্যাপ দিয়ে কানেক্ট করলে কন্টেইনার চালু হবে।"
    echo -e "  ${YELLOW}[i]${NC} Stop করতে: ${BOLD}Ctrl+C${NC} অথবা ${BOLD}./auto-wake.sh stop${NC}"
    echo ""

    # Ctrl+C হ্যান্ডলিং
    trap 'cmd_stop; exit 0' SIGINT SIGTERM

    # ফরগ্রাউন্ডে অপেক্ষা
    wait
}

# ─── ডেমন বন্ধ করা ───
cmd_stop() {
    echo ""
    info "Stopping auto-wake daemon..."

    stop_all_listeners

    if [ -f "$PID_DIR/idle-monitor.pid" ]; then
        local pid
        pid=$(cat "$PID_DIR/idle-monitor.pid")
        kill "$pid" 2>/dev/null
        kill -9 "$pid" 2>/dev/null
        rm -f "$PID_DIR/idle-monitor.pid"
    fi

    rm -f "$PID_DIR/daemon.pid"

    ok "Auto-wake daemon stopped"
    log "DAEMON STOPPED"
}

# ─── স্ট্যাটাস দেখা ───
cmd_status() {
    echo ""
    echo -e "  ${BOLD}${CYAN}▶ Auto-Wake Daemon Status${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""

    if [ -f "$PID_DIR/daemon.pid" ] && kill -0 "$(cat "$PID_DIR/daemon.pid")" 2>/dev/null; then
        ok "Daemon is ${GREEN}RUNNING${NC} (pid $(cat "$PID_DIR/daemon.pid"))"
    else
        warn "Daemon is ${RED}STOPPED${NC}"
    fi

    echo ""
    echo -e "  ${BOLD}Active Listeners:${NC}"

    local found=0
    if [ -d "$PID_DIR" ]; then
        for pidfile in "$PID_DIR"/*.socat.pid; do
            [ ! -f "$pidfile" ] && continue
            local user
            user=$(basename "$pidfile" .socat.pid)
            local pid
            pid=$(cat "$pidfile")
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "    ${GREEN}●${NC} $user ${DIM}(pid $pid)${NC}"
                found=$((found + 1))
            fi
        done
    fi

    [ "$found" -eq 0 ] && echo -e "    ${DIM}No active listeners${NC}"

    echo ""
    echo -e "  ${BOLD}Running Containers:${NC}"

    local cfound=0
    if [ -s "$CONFIG_FILE" ]; then
        while IFS=: read -r user port; do
            [ -z "$user" ] && continue
            if is_running "$user"; then
                echo -e "    ${GREEN}●${NC} $user ${DIM}(port $port)${NC}"
                cfound=$((cfound + 1))
            fi
        done < "$CONFIG_FILE"
    fi

    [ "$cfound" -eq 0 ] && echo -e "    ${DIM}No containers running${NC}"
    echo ""
}

# ─── হেল্প ───
cmd_help() {
    echo ""
    echo -e "  ${BOLD}${CYAN}SmVnc Auto-Wake Daemon${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${BOLD}Usage:${NC} ./auto-wake.sh <command>"
    echo ""
    echo -e "  ${GREEN}start${NC}      Start daemon (listeners + idle monitor)"
    echo -e "  ${GREEN}stop${NC}       Stop daemon and all listeners"
    echo -e "  ${GREEN}status${NC}     Show daemon status"
    echo -e "  ${GREEN}restart${NC}    Restart daemon"
    echo -e "  ${GREEN}help${NC}       Show this help"
    echo ""
    echo -e "  ${DIM}Internal command (do not run manually):${NC}"
    echo -e "  ${DIM}handle <user> <port>${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════
#  MAIN ENTRYPOINT
# ═══════════════════════════════════════════════════════════

# আর্গুমেন্ট ছাড়া চালালে help
if [ $# -eq 0 ]; then
    cmd_help
    exit 0
fi

case "$1" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    status)
        cmd_status
        ;;
    restart)
        cmd_stop
        sleep 1
        cmd_start
        ;;
    help|--help|-h)
        cmd_help
        ;;
    handle)
        # Internal: socat EXEC থেকে কল হয়
        if [ -z "$2" ] || [ -z "$3" ]; then
            err "handle requires <user> <port>"
            exit 1
        fi
        handle_connection "$2" "$3"
        ;;
    *)
        err "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
