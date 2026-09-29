#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  SmVnc - Modern Multi-User VNC Manager
#  Main Dashboard Script
#
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Email  : smmehmudgm18@gmail.com
#  Repo   : github.com/MehmudHub/SmVnc
#  License: MIT
# ═══════════════════════════════════════════════════════════

set -o pipefail

# ─────────────────────────────────────────────
#  Dynamic Paths (স্ক্রিপ্ট যেখানে, ডাটাও সেখানে)
# ─────────────────────────────────────────────
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$BASE_DIR/config"
CONFIG_FILE="$CONFIG_DIR/users.conf"
DATA_DIR="$BASE_DIR/data"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/SmVnc.log"

# ─────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────
IMAGE_NAME="smvnc-modern:latest"
INTERNAL_VNC_PORT=5901
DEFAULT_PORTS=(5901 5902 5903 5904 5905)
VNC_PASSWORD="headless"
MAX_USERS=10

# ─────────────────────────────────────────────
#  Colors
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════

# ─── Initialization ───
initialize() {
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
    [ ! -f "$CONFIG_FILE" ] && touch "$CONFIG_FILE"
    [ ! -f "$LOG_FILE" ]   && touch "$LOG_FILE"
    [ ! -f "$DATA_DIR/.gitkeep" ] && touch "$DATA_DIR/.gitkeep"
    [ ! -f "$LOG_DIR/.gitkeep" ]  && touch "$LOG_DIR/.gitkeep"
}

# ─── Logging ───
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# ─── Get Local IP (VPN বাদ দিয়ে) ───
get_local_ip() {
    local ip
    ip=$(ip -4 -o addr show scope global 2>/dev/null | \
         grep -Ev "tun|tap|ppp|wg" | \
         awk '{print $4}' | cut -d/ -f1 | head -n1)
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

# ─── Podman চেক ───
check_podman() {
    if ! command -v podman &>/dev/null; then
        echo -e "${RED}[!] Podman ইনস্টল করা নেই।${NC}"
        echo -e "${YELLOW}[i] চালাও: ./setup.sh${NC}"
        exit 1
    fi
}

# ─── Image চেক ───
check_image() {
    if ! podman image exists "$IMAGE_NAME" &>/dev/null; then
        echo -e "${RED}[!] SmVnc ইমেজ তৈরি হয়নি।${NC}"
        echo -e "${YELLOW}[i] চালাও: ./setup.sh${NC}"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════
#  USER MANAGEMENT HELPERS
# ═══════════════════════════════════════════════════════════

user_from_port() {
    [ -s "$CONFIG_FILE" ] && grep ":$1$" "$CONFIG_FILE" | cut -d: -f1
}

port_from_user() {
    [ -s "$CONFIG_FILE" ] && grep "^$1:" "$CONFIG_FILE" | cut -d: -f2
}

user_exists() {
    grep -q "^$1:" "$CONFIG_FILE" 2>/dev/null
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

count_users() {
    [ ! -s "$CONFIG_FILE" ] && echo 0 || wc -l < "$CONFIG_FILE"
}

count_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -c "^smvnc-" || echo 0
}

# ═══════════════════════════════════════════════════════════
#  CONTAINER MANAGEMENT
# ═══════════════════════════════════════════════════════════

start_container() {
    local user=$1
    local port=$2
    local cname
    cname=$(container_name "$user")
    local data_path="$DATA_DIR/$user"
    mkdir -p "$data_path"

    if is_running "$user"; then
        return 0
    fi

    if is_created "$user"; then
        podman start "$cname" &>/dev/null
    else
        podman run -d --name "$cname" \
            -p "${port}:${INTERNAL_VNC_PORT}" \
            -v "$data_path:/headless/Desktop" \
            --memory="1.5g" --cpus="1.0" \
            "$IMAGE_NAME" &>/dev/null
    fi
    log_msg "START: $cname on port $port"
}

stop_container() {
    local user=$1
    local cname
    cname=$(container_name "$user")
    if is_running "$user"; then
        podman stop "$cname" &>/dev/null
        log_msg "STOP: $cname"
    fi
}

remove_container() {
    local user=$1
    local cname
    cname=$(container_name "$user")
    if is_created "$user"; then
        podman stop "$cname" &>/dev/null
        podman rm "$cname" &>/dev/null
        log_msg "REMOVE: $cname"
    fi
}

# ═══════════════════════════════════════════════════════════
#  UI FUNCTIONS
# ═══════════════════════════════════════════════════════════

# Box width: 56 interior characters
box_top()     { echo -e "  ${CYAN}╔══════════════════════════════════════════════════════╗${NC}"; }
box_mid()     { echo -e "  ${CYAN}╠══════════════════════════════════════════════════════╣${NC}"; }
box_bottom()  { echo -e "  ${CYAN}╚══════════════════════════════════════════════════════╝${NC}"; }
box_line()    { printf "  ${CYAN}║${NC}%-54s${CYAN}║${NC}\n" " $1"; }
box_empty()   { printf "  ${CYAN}║${NC}%-54s${CYAN}║${NC}\n" ""; }
box_center()  {
    local text="$1"
    local len=${#text}
    local pad=$(( (54 - len) / 2 ))
    local pad_r=$(( 54 - len - pad ))
    printf "  ${CYAN}║${NC}%*s${BOLD}%s${NC}%*s${CYAN}║${NC}\n" $pad "" "$text" $pad_r ""
}

# ─── Print Main Header ───
print_header() {
    clear
    echo ""
    echo -e "  ${MAGENTA}${BOLD}    ███████╗███╗   ███╗██╗   ██╗███╗   ██╗ ██████╗${NC}"
    echo -e "  ${MAGENTA}${BOLD}    ██╔════╝████╗ ████║██║   ██║████╗  ██║██╔════╝${NC}"
    echo -e "  ${MAGENTA}${BOLD}    ███████╗██╔████╔██║██║   ██║██╔██╗ ██║██║     ${NC}"
    echo -e "  ${MAGENTA}${BOLD}    ╚════██║██║╚██╔╝██║╚██╗ ██╔╝██║╚██╗██║██║     ${NC}"
    echo -e "  ${MAGENTA}${BOLD}    ███████║██║ ╚═╝ ██║ ╚████╔╝ ██║ ╚████║╚██████╗${NC}"
    echo -e "  ${MAGENTA}${BOLD}    ╚══════╝╚═╝     ╚═╝  ╚═══╝  ╚═╝  ╚═══╝ ╚═════╝${NC}"
    echo ""
    echo -e "  ${DIM}Modern Multi-User VNC Desktop Manager${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}▸ Host IP   :${NC} ${GREEN}$(get_local_ip)${NC}"
    echo -e "  ${YELLOW}▸ Time      :${NC} $(date '+%A, %d %B %Y • %I:%M %p')"
    echo -e "  ${YELLOW}▸ Data Dir  :${NC} $DATA_DIR"
    echo -e "  ${YELLOW}▸ Users     :${NC} ${GREEN}$(count_users)${NC} registered • ${GREEN}$(count_running)${NC} running"
    echo ""
}

# ─── Print Menu ───
print_menu() {
    box_top
    box_center "VNC MANAGER - CONTROL DASHBOARD"
    box_mid
    box_line ""
    box_line "${GREEN}[1]${NC}  View Active Ports"
    box_line "${GREEN}[2]${NC}  View All Users"
    box_line "${GREEN}[3]${NC}  Start User Container"
    box_line "${GREEN}[4]${NC}  Stop Specific Port"
    box_line "${GREEN}[5]${NC}  Stop All Services"
    box_line "${GREEN}[6]${NC}  Add New User"
    box_line "${GREEN}[7]${NC}  Remove User"
    box_line "${GREEN}[8]${NC}  View Logs"
    box_line "${CYAN}[9]${NC}  About Developer"
    box_line "${RED}[0]${NC}  Exit"
    box_line ""
    box_bottom
    echo ""
}

# ─── Pause ───
pause() {
    echo ""
    echo -e "  ${DIM}Press ${BOLD}[Enter]${NC}${DIM} to return to main menu...${NC}"
    read -r
}

# ═══════════════════════════════════════════════════════════
#  MENU ACTIONS
# ═══════════════════════════════════════════════════════════

# ─── [1] View Active Ports ───
action_view_active() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ ACTIVE CONTAINERS${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "  ${YELLOW}No users registered yet. Press [6] to add one.${NC}"
        pause; return
    fi

    printf "  ${BOLD}%-4s %-14s %-8s %-12s %-20s${NC}\n" "#" "USER" "PORT" "STATUS" "ADDRESS"
    echo -e "  ${DIM}─────────────────────────────────────────────────────${NC}"

    local i=1
    local found=0
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        local status="${RED}○ DOWN${NC}"
        local addr="${DIM}-${NC}"
        if is_running "$user"; then
            status="${GREEN}● UP${NC}"
            addr="$(get_local_ip):$port"
            found=$((found + 1))
        fi
        printf "  %-4s %-14s %-8s %-22b %-20s\n" "$i" "$user" "$port" "$status" "$addr"
        i=$((i + 1))
    done < "$CONFIG_FILE"

    echo ""
    echo -e "  ${DIM}Total: $((i-1)) users • $found running${NC}"
    pause
}

# ─── [2] View All Users ───
action_view_users() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ REGISTERED USERS${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "  ${YELLOW}No users registered yet.${NC}"
        pause; return
    fi

    printf "  ${BOLD}%-4s %-16s %-8s %-12s %-14s${NC}\n" "#" "USERNAME" "PORT" "STATUS" "DATA SIZE"
    echo -e "  ${DIM}─────────────────────────────────────────────────────${NC}"

    local i=1
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        local status="${RED}○ DOWN${NC}"
        is_running "$user" && status="${GREEN}● UP${NC}"
        local dsize="0"
        if [ -d "$DATA_DIR/$user" ]; then
            dsize=$(du -sh "$DATA_DIR/$user" 2>/dev/null | cut -f1)
        fi
        printf "  %-4s %-16s %-8s %-22b %-14s\n" "$i" "$user" "$port" "$status" "$dsize"
        i=$((i + 1))
    done < "$CONFIG_FILE"
    pause
}

# ─── [3] Start User Container ───
action_start_user() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ START USER CONTAINER${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "  ${YELLOW}No users registered.${NC}"
        pause; return
    fi

    echo -e "  ${BOLD}Available users:${NC}"
    local i=1
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        local mark="${RED}○${NC}"
        is_running "$user" && mark="${GREEN}●${NC}"
        echo -e "    $mark  $i) ${BOLD}$user${NC} ${DIM}(port $port)${NC}"
        i=$((i + 1))
    done < "$CONFIG_FILE"

    echo ""
    read -p "  ➜  Enter username (or 'b' to go back): " uname
    [ "$uname" = "b" ] && return

    if ! user_exists "$uname"; then
        echo -e "\n  ${RED}[!] User '$uname' not found.${NC}"
        pause; return
    fi

    local port
    port=$(port_from_user "$uname")

    if is_running "$uname"; then
        echo -e "\n  ${YELLOW}[~] '$uname' is already running on port $port${NC}"
        pause; return
    fi

    echo -e "\n  ${YELLOW}[~] Starting '$uname' on port $port...${NC}"
    start_container "$uname" "$port"
    sleep 3

    if is_running "$uname"; then
        echo -e "  ${GREEN}[✓] Container started successfully!${NC}"
        echo -e "  ${GREEN}    Address : ${NC}$(get_local_ip):$port"
        echo -e "  ${GREEN}    Password: ${NC}$VNC_PASSWORD"
    else
        echo -e "  ${RED}[!] Failed to start container.${NC}"
    fi
    pause
}

# ─── [4] Stop Specific Port ───
action_stop_specific() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ STOP SPECIFIC PORT${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    local any_running=0
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        if is_running "$user"; then
            echo -e "    ${GREEN}●${NC} ${BOLD}$user${NC}  ${DIM}(port $port)${NC}"
            any_running=$((any_running + 1))
        fi
    done < "$CONFIG_FILE"

    if [ "$any_running" -eq 0 ]; then
        echo -e "  ${YELLOW}[i] No containers are running.${NC}"
        pause; return
    fi

    echo ""
    read -p "  ➜  Enter port to stop (or 'b' to go back): " sp
    [ "$sp" = "b" ] && return

    local uname
    uname=$(user_from_port "$sp")
    if [ -z "$uname" ]; then
        echo -e "\n  ${RED}[!] No user mapped to port $sp.${NC}"
        pause; return
    fi

    if ! is_running "$uname"; then
        echo -e "\n  ${YELLOW}[i] '$uname' is already stopped.${NC}"
        pause; return
    fi

    echo ""
    echo -en "  ${YELLOW}Stop '$uname' on port $sp? (y/n): ${NC}"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop_container "$uname"
        echo -e "  ${GREEN}[✓] Stopped '$uname'.${NC}"
    else
        echo -e "  ${YELLOW}[~] Cancelled.${NC}"
    fi
    pause
}

# ─── [5] Stop All Services ───
action_stop_all() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ STOP ALL SERVICES${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    local running=0
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        is_running "$user" && running=$((running + 1))
    done < "$CONFIG_FILE"

    if [ "$running" -eq 0 ]; then
        echo -e "  ${YELLOW}[i] No containers running.${NC}"
        pause; return
    fi

    echo -e "  ${YELLOW}Total running: $running${NC}"
    echo ""
    echo -en "  ${RED}${BOLD}Stop ALL containers? (yes/no): ${NC}"
    read -r confirm

    if [ "$confirm" = "yes" ]; then
        echo ""
        while IFS=: read -r user port; do
            [ -z "$user" ] && continue
            if is_running "$user"; then
                echo -e "  ${YELLOW}[~] Stopping '$user'...${NC}"
                stop_container "$user"
            fi
        done < "$CONFIG_FILE"
        echo ""
        echo -e "  ${GREEN}[✓] All services stopped.${NC}"
    else
        echo -e "\n  ${YELLOW}[~] Cancelled.${NC}"
    fi
    pause
}

# ─── [6] Add New User ───
action_add_user() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ ADD NEW USER${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ "$(count_users)" -ge "$MAX_USERS" ]; then
        echo -e "  ${RED}[!] Maximum $MAX_USERS users reached.${NC}"
        pause; return
    fi

    read -p "  ➜  Username: " uname
    [ -z "$uname" ] && return

    # Validation
    if [[ ! "$uname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "\n  ${RED}[!] Invalid username. Use only a-z, A-Z, 0-9, _, -${NC}"
        pause; return
    fi

    if user_exists "$uname"; then
        echo -e "\n  ${RED}[!] User '$uname' already exists.${NC}"
        pause; return
    fi

    # Auto-assign port
    local next_port=""
    for p in "${DEFAULT_PORTS[@]}"; do
        if ! grep -q ":$p$" "$CONFIG_FILE"; then
            next_port=$p
            break
        fi
    done

    if [ -z "$next_port" ]; then
        echo -e "  ${YELLOW}[i] All default ports (5901-5905) taken.${NC}"
        read -p "  ➜  Enter custom port: " next_port
        if ! [[ "$next_port" =~ ^[0-9]+$ ]] || [ "$next_port" -lt 1024 ] || [ "$next_port" -gt 65535 ]; then
            echo -e "  ${RED}[!] Invalid port.${NC}"
            pause; return
        fi
    fi

    # Check if port is in use
    if ss -tuln 2>/dev/null | grep -q ":${next_port} "; then
        echo -e "\n  ${RED}[!] Port $next_port is already in use on system.${NC}"
        pause; return
    fi

    echo "$uname:$next_port" >> "$CONFIG_FILE"
    mkdir -p "$DATA_DIR/$uname"
    log_msg "ADD USER: $uname on port $next_port"

    echo ""
    echo -e "  ${GREEN}[✓] User '$uname' added successfully!${NC}"
    echo -e "  ${GREEN}    Assigned Port: ${NC}$next_port"
    echo -e "  ${GREEN}    Data Folder  : ${NC}$DATA_DIR/$uname"
    pause
}

# ─── [7] Remove User ───
action_remove_user() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ REMOVE USER${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$CONFIG_FILE" ]; then
        echo -e "  ${YELLOW}No users to remove.${NC}"
        pause; return
    fi

    local i=1
    while IFS=: read -r user port; do
        [ -z "$user" ] && continue
        echo -e "    ${BOLD}$i)${NC} $user ${DIM}(port $port)${NC}"
        i=$((i + 1))
    done < "$CONFIG_FILE"

    echo ""
    read -p "  ➜  Username to remove (or 'b' to go back): " uname
    [ "$uname" = "b" ] && return

    if ! user_exists "$uname"; then
        echo -e "\n  ${RED}[!] User '$uname' not found.${NC}"
        pause; return
    fi

    echo ""
    echo -e "  ${RED}${BOLD}⚠ WARNING: This will delete ALL data in '$DATA_DIR/$uname'!${NC}"
    echo -en "  ${YELLOW}Type 'yes' to confirm: ${NC}"
    read -r confirm

    if [ "$confirm" = "yes" ]; then
        echo ""
        echo -e "  ${YELLOW}[~] Stopping and removing container...${NC}"
        remove_container "$uname"
        echo -e "  ${YELLOW}[~] Removing user config...${NC}"
        sed -i "/^$uname:/d" "$CONFIG_FILE"
        echo -e "  ${YELLOW}[~] Deleting data folder...${NC}"
        rm -rf "$DATA_DIR/$uname"
        log_msg "REMOVE USER: $uname"
        echo ""
        echo -e "  ${GREEN}[✓] User '$uname' removed completely.${NC}"
    else
        echo -e "\n  ${YELLOW}[~] Cancelled.${NC}"
    fi
    pause
}

# ─── [8] View Logs ───
action_view_logs() {
    clear
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ RECENT LOGS${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    echo ""

    if [ ! -s "$LOG_FILE" ]; then
        echo -e "  ${YELLOW}No logs yet.${NC}"
        pause; return
    fi

    tail -n 25 "$LOG_FILE" | while IFS= read -r line; do
        # Colorize by action type
        if echo "$line" | grep -q "START"; then
            echo -e "  ${GREEN}$line${NC}"
        elif echo "$line" | grep -q "STOP\|REMOVE"; then
            echo -e "  ${RED}$line${NC}"
        elif echo "$line" | grep -q "ADD"; then
            echo -e "  ${CYAN}$line${NC}"
        else
            echo "  $line"
        fi
    done

    echo ""
    echo -e "  ${DIM}Log file: $LOG_FILE${NC}"
    pause
}

# ─── [9] About Developer ───
action_about_dev() {
    clear
    echo ""
    box_top
    box_center "ABOUT DEVELOPER"
    box_mid
    box_empty
    box_line "${BOLD}  Name      :${NC}  Sazid Mehmud"
    box_line "${BOLD}  Age       :${NC}  18"
    box_line "${BOLD}  Location  :${NC}  Atulia, Kalaroa, Satkhira"
    box_line "${BOLD}  Hobby     :${NC}  Termux Tools / Script Developer"
    box_empty
    box_line "${CYAN}  ─── Connect With Me ───${NC}"
    box_empty
    box_line "${BOLD}  Telegram  :${NC}  t.me/SmMehmudTg18"
    box_line "${BOLD}  Email     :${NC}  smmehmudgm18@gmail.com"
    box_line "${BOLD}  GitHub    :${NC}  github.com/MehmudHub"
    box_empty
    box_line "${DIM}  \"Made with love from Bangladesh\"${NC}"
    box_empty
    box_mid
    box_line "  ${CYAN}[00]${NC}  Back to Main Menu"
    box_bottom
    echo ""
    echo -en "  ➜  Type ${BOLD}'b'${NC} or ${BOLD}[Enter]${NC} to go back: "
    read -r ans
}

# ═══════════════════════════════════════════════════════════
#  MAIN LOOP
# ═══════════════════════════════════════════════════════════

main_loop() {
    while true; do
        print_header
        print_menu
        echo -en "  ${BOLD}➜  Select option:${NC} "
        read -r choice
        echo ""

        case $choice in
            1) action_view_active ;;
            2) action_view_users ;;
            3) action_start_user ;;
            4) action_stop_specific ;;
            5) action_stop_all ;;
            6) action_add_user ;;
            7) action_remove_user ;;
            8) action_view_logs ;;
            9) action_about_dev ;;
            0)
                echo -e "  ${GREEN}${BOLD}Thanks for using SmVnc! 👋${NC}"
                echo -e "  ${DIM}  - Sazid Mehmud${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "  ${RED}[!] Invalid option. Try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════
#  ARGUMENT HANDLING
# ═══════════════════════════════════════════════════════════

case "${1:-}" in
    setup)
        if [ -f "$BASE_DIR/setup.sh" ]; then
            exec "$BASE_DIR/setup.sh"
        else
            echo -e "${RED}[!] setup.sh not found.${NC}"
            exit 1
        fi
        ;;
    start-all)
        initialize
        check_podman
        check_image
        while IFS=: read -r user port; do
            [ -z "$user" ] && continue
            echo -e "${YELLOW}[~] Starting $user...${NC}"
            start_container "$user" "$port"
        done < "$CONFIG_FILE"
        echo -e "${GREEN}[✓] All containers started.${NC}"
        ;;
    stop-all)
        initialize
        check_podman
        while IFS=: read -r user port; do
            [ -z "$user" ] && continue
            stop_container "$user"
        done < "$CONFIG_FILE"
        echo -e "${GREEN}[✓] All containers stopped.${NC}"
        ;;
    version|--version|-v)
        echo "SmVnc v1.0.0"
        echo "Author: Sazid Mehmud"
        echo "Repo  : https://github.com/MehmudHub/SmVnc"
        ;;
    help|--help|-h)
        echo ""
        echo "SmVnc - Modern Multi-User VNC Desktop Manager"
        echo ""
        echo "Usage:"
        echo "  ./SmVnc.sh              Launch interactive dashboard"
        echo "  ./SmVnc.sh setup        Run setup script"
        echo "  ./SmVnc.sh start-all    Start all user containers"
        echo "  ./SmVnc.sh stop-all     Stop all user containers"
        echo "  ./SmVnc.sh version      Show version"
        echo "  ./SmVnc.sh help         Show this help"
        echo ""
        ;;
    "")
        initialize
        check_podman
        check_image
        main_loop
        ;;
    *)
        echo -e "${RED}[!] Unknown argument: $1${NC}"
        echo -e "${YELLOW}[i] Try: ./SmVnc.sh help${NC}"
        exit 1
        ;;
esac
