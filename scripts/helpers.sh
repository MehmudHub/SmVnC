#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  SmVnc - Reusable Helper Functions
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Repo   : github.com/MehmudHub/SmVnc
#  License: MIT
#
#  ⚠️  এই ফাইলটি সরাসরি চালানোর জন্য নয়।
#      SmVnc.sh থেকে source করা হবে:
#          source "$BASE_DIR/scripts/helpers.sh"
# ═══════════════════════════════════════════════════════════

# ─────────────────────────────────────────────
#  রঙ (Colors)
# ─────────────────────────────────────────────
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m'

# ═══════════════════════════════════════════════════════════
#  1. LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════

# ─── লগ ফাইলে লেখা ───
# Usage: log_msg "START user sazid"
log_msg() {
    local msg="$1"
    [ -z "${LOG_FILE:-}" ] && return
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG_FILE"
}

# ─── টার্মিনালে সাকসেস মেসেজ ───
# Usage: ok "User created"
ok() {
    echo -e "  ${GREEN}[✓]${NC} $1"
}

# ─── টার্মিনালে ওয়ার্নিং মেসেজ ───
# Usage: warn "Port already in use"
warn() {
    echo -e "  ${YELLOW}[~]${NC} $1"
}

# ─── টার্মিনালে এরর মেসেজ ───
# Usage: err "Container failed"
err() {
    echo -e "  ${RED}[!]${NC} $1"
}

# ─── ইনফো মেসেজ ───
# Usage: info "Building image..."
info() {
    echo -e "  ${CYAN}[i]${NC} $1"
}

# ─── ধাপ সেকশন ───
# Usage: step "Step 1/6 — Checking system"
step() {
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ $1${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
}

# ─── Fatal error → exit ───
# Usage: die "Dockerfile not found"
die() {
    echo ""
    err "$1"
    echo ""
    exit 1
}

# ═══════════════════════════════════════════════════════════
#  2. SYSTEM INFORMATION
# ═══════════════════════════════════════════════════════════

# ─── লোকাল IP বের করা (VPN বাদ দিয়ে) ───
# VPN (tun/tap/ppp/wg) ইন্টারফেস বাদ দিয়ে শুধু আসল IP দেয়
get_local_ip() {
    local ip
    ip=$(ip -4 -o addr show scope global 2>/dev/null | \
         grep -Ev "tun|tap|ppp|wg" | \
         awk '{print $4}' | cut -d/ -f1 | head -n1)
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

# ─── OS ডিটেক্ট ───
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ─── কম্যান্ড আছে কি না ───
# Usage: check_command podman && echo "found"
check_command() {
    command -v "$1" &>/dev/null
}

# ─── পোর্ট ব্যবহৃত কি না ───
# Usage: is_port_in_use 5901
is_port_in_use() {
    ss -tuln 2>/dev/null | grep -q ":$1 "
}

# ─── সিস্টেম আপটাইম ───
get_uptime() {
    uptime -p 2>/dev/null | sed 's/up //' || echo "unknown"
}

# ─── ডিস্ক ইউজ ───
get_disk_usage() {
    df -h "$1" 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A"
}

# ═══════════════════════════════════════════════════════════
#  3. PACKAGE INSTALLATION (Multi-Distro)
# ═══════════════════════════════════════════════════════════

# ─── প্যাকেজ ইনস্টল (ডিস্ট্রো অটো ডিটেক্ট) ───
# Usage: install_packages podman socat qrencode
install_packages() {
    local packages=("$@")
    local distro
    distro=$(detect_distro)

    case "$distro" in
        fedora|rhel|centos)
            sudo dnf install -y "${packages[@]}"
            ;;
        ubuntu|debian|linuxmint|pop)
            sudo apt-get update -qq
            sudo apt-get install -y "${packages[@]}"
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm "${packages[@]}"
            ;;
        opensuse*|suse)
            sudo zypper install -y "${packages[@]}"
            ;;
        *)
            err "Unsupported distro: $distro"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════
#  4. USER CONFIGURATION HELPERS
# ═══════════════════════════════════════════════════════════

# ─── পোর্ট থেকে ইউজারনেম ───
# Usage: user_from_port 5901
user_from_port() {
    [ -s "${CONFIG_FILE:-}" ] && grep ":$1$" "$CONFIG_FILE" | cut -d: -f1
}

# ─── ইউজারনেম থেকে পোর্ট ───
# Usage: port_from_user sazid
port_from_user() {
    [ -s "${CONFIG_FILE:-}" ] && grep "^$1:" "$CONFIG_FILE" | cut -d: -f2
}

# ─── ইউজার আছে কি না ───
# Usage: user_exists sazid
user_exists() {
    [ -s "${CONFIG_FILE:-}" ] && grep -q "^$1:" "$CONFIG_FILE"
}

# ─── মোট ইউজার সংখ্যা ───
count_users() {
    [ ! -s "${CONFIG_FILE:-}" ] && echo 0 || wc -l < "$CONFIG_FILE"
}

# ─── ইউজারনেম ভ্যালিডেশন ───
# Usage: validate_username "sazid" && echo "valid"
validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

# ─── পোর্ট ভ্যালিডেশন ───
# Usage: validate_port 5901
validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1024 ] && [ "$1" -le 65535 ]
}

# ─── পরবর্তী ফ্রি পোর্ট খুঁজে বের করা ───
# Usage: next_free_port 5901 5902 5903 5904 5905
next_free_port() {
    for p in "$@"; do
        if [ -s "${CONFIG_FILE:-}" ]; then
            grep -q ":$p$" "$CONFIG_FILE" || { echo "$p"; return; }
        else
            echo "$p"; return
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════
#  5. PODMAN CONTAINER HELPERS
# ═══════════════════════════════════════════════════════════

# ─── কন্টেইনার নাম তৈরি ───
# Usage: container_name sazid → smvnc-sazid
container_name() {
    echo "smvnc-$1"
}

# ─── কন্টেইনার চালু আছে কি না ───
# Usage: is_running sazid
is_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -q "^$(container_name "$1")$"
}

# ─── কন্টেইনার তৈরি হয়েছে কি না (চালু বা বন্ধ) ───
# Usage: is_created sazid
is_created() {
    podman ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^$(container_name "$1")$"
}

# ─── কতগুলো কন্টেইনার চলছে ───
count_running() {
    podman ps --format '{{.Names}}' 2>/dev/null | grep -c "^smvnc-" || echo 0
}

# ─── ইমেজ আছে কি না ───
# Usage: image_exists smvnc-modern:latest
image_exists() {
    podman image exists "$1" 2>/dev/null
}

# ─── কন্টেইনারের স্ট্যাটাস ───
# Usage: container_status sazid → "running" / "exited" / "not found"
container_status() {
    podman ps -a --format '{{.Names}}|{{.Status}}' 2>/dev/null | \
        grep "^$(container_name "$1")|" | cut -d'|' -f2 || echo "not found"
}

# ─── কন্টেইনারের IP ───
container_ip() {
    podman inspect "$(container_name "$1")" 2>/dev/null | \
        grep -m1 '"IPAddress"' | cut -d'"' -f4 || echo ""
}

# ─── সব কন্টেইনার লিস্ট (JSON) ───
list_all_containers() {
    podman ps -a --filter "name=smvnc-" --format '{{.Names}}|{{.Status}}|{{.Ports}}'
}

# ═══════════════════════════════════════════════════════════
#  6. UI / DISPLAY HELPERS
# ═══════════════════════════════════════════════════════════

# ─── বক্স ড্রয়িং ───
box_top()     { echo -e "  ${CYAN}╔══════════════════════════════════════════════════════╗${NC}"; }
box_mid()     { echo -e "  ${CYAN}╠══════════════════════════════════════════════════════╣${NC}"; }
box_bottom()  { echo -e "  ${CYAN}╚══════════════════════════════════════════════════════╝${NC}"; }
box_line()    { printf "  ${CYAN}║${NC}%-54s${CYAN}║${NC}\n" " $1"; }
box_empty()   { printf "  ${CYAN}║${NC}%-54s${CYAN}║${NC}\n" ""; }

# ─── বক্সের মাঝখানে টেক্সট ───
box_center() {
    local text="$1"
    local len=${#text}
    local pad=$(( (54 - len) / 2 ))
    local pad_r=$(( 54 - len - pad ))
    printf "  ${CYAN}║${NC}%*s${BOLD}%s${NC}%*s${CYAN}║${NC}\n" $pad "" "$text" $pad_r ""
}

# ─── Enter চাপার জন্য অপেক্ষা ───
pause() {
    echo ""
    echo -e "  ${DIM}Press ${BOLD}[Enter]${NC}${DIM} to return to main menu...${NC}"
    read -r
}

# ─── স্ক্রিন ক্লিয়ার + হেডার ───
clear_screen() {
    clear
    echo ""
}

# ─── লাইন সেপারেটর ───
separator() {
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
}

# ═══════════════════════════════════════════════════════════
#  7. VALIDATION HELPERS
# ═══════════════════════════════════════════════════════════

# ─── Yes/No প্রশ্ন ───
# Usage: confirm "Delete everything?" && echo "yes"
confirm() {
    local prompt="${1:-Are you sure?}"
    echo -en "  ${YELLOW}${prompt} (y/N): ${NC}"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ─── Yes/No প্রশ্ন (টাইপ করতে হয় "yes") ───
# Usage: confirm_strict "Delete ALL data?" && echo "yes"
confirm_strict() {
    local prompt="${1:-Are you sure?}"
    echo -en "  ${RED}${BOLD}${prompt} (type 'yes'): ${NC}"
    read -r ans
    [ "$ans" = "yes" ]
}

# ─── ইউজার থেকে ইনপুট নেওয়া ───
# Usage: name=$(prompt "Enter name")
prompt() {
    echo -en "  ${BOLD}➜${NC}  $1: " >&2
    read -r ans
    echo "$ans"
}

# ─── ফাইল পারমিশন চেক ───
is_executable() {
    [ -x "$1" ]
}

# ─── Empty string চেক ───
is_empty() {
    [ -z "$1" ]
}

# ═══════════════════════════════════════════════════════════
#  8. STRING UTILITIES
# ═══════════════════════════════════════════════════════════

# ─── স্ট্রিং ছোট করা ───
# Usage: truncate "very long string here" 20
truncate() {
    local str="$1"
    local max="$2"
    if [ ${#str} -gt "$max" ]; then
        echo "${str:0:$((max-3))}..."
    else
        echo "$str"
    fi
}

# ─── স্ট্রিং প্যাডিং (ডান দিকে) ───
# Usage: pad_right "abc" 10 → "abc       "
pad_right() {
    printf "%-${2}s" "$1"
}

# ─── স্ট্রিং প্যাডিং (বাম দিকে) ───
pad_left() {
    printf "%${2}s" "$1"
}

# ─── Human-readable file size ───
# Usage: human_size 1048576 → "1.0M"
human_size() {
    numfmt --to=iec "$1" 2>/dev/null || echo "$1 B"
}

# ═══════════════════════════════════════════════════════════
#  9. TIME / DATE HELPERS
# ═══════════════════════════════════════════════════════════

# ─── বর্তমান টাইম স্ট্যাম্প ───
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ─── ফ্রেন্ডলি টাইম ───
friendly_time() {
    date '+%A, %d %B %Y • %I:%M %p'
}

# ─── ফাইলের বয়স (দিনে) ───
# Usage: file_age_days /path/to/file
file_age_days() {
    if [ -f "$1" ]; then
        local now file_time
        now=$(date +%s)
        file_time=$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null)
        echo $(( (now - file_time) / 86400 ))
    else
        echo "-1"
    fi
}

# ═══════════════════════════════════════════════════════════
#  10. FILE / FOLDER HELPERS
# ═══════════════════════════════════════════════════════════

# ─── ফোল্ডার সাইজ (human readable) ───
# Usage: folder_size /path/to/folder
folder_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# ─── ফাইল কপি (ব্যাকআপসহ) ───
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak.$(date +%s)"
        return 0
    fi
    return 1
}

# ─── নিরাপদে ফাইল তৈরি ───
ensure_file() {
    [ ! -f "$1" ] && touch "$1"
}

# ─── নিরাপদে ফোল্ডার তৈরি ───
ensure_dir() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

# ═══════════════════════════════════════════════════════════
#  11. FIREWALL HELPERS (Fedora/firewalld)
# ═══════════════════════════════════════════════════════════

# ─── পোর্ট ওপেন করা ───
# Usage: open_firewall_port 5901
open_firewall_port() {
    local port="$1"
    if check_command firewall-cmd; then
        if ! sudo firewall-cmd --query-port="${port}/tcp" &>/dev/null; then
            sudo firewall-cmd --add-port="${port}/tcp" --permanent &>/dev/null
            sudo firewall-cmd --reload &>/dev/null
            return 0
        fi
    fi
    return 1
}

# ─── পোর্ট বন্ধ করা ───
# Usage: close_firewall_port 5901
close_firewall_port() {
    local port="$1"
    if check_command firewall-cmd; then
        if sudo firewall-cmd --query-port="${port}/tcp" &>/dev/null; then
            sudo firewall-cmd --remove-port="${port}/tcp" --permanent &>/dev/null
            sudo firewall-cmd --reload &>/dev/null
            return 0
        fi
    fi
    return 1
}

# ═══════════════════════════════════════════════════════════
#  12. QR CODE HELPER
# ═══════════════════════════════════════════════════════════

# ─── QR কোড প্রিন্ট ───
# Usage: show_qr "192.168.1.5" 5901
show_qr() {
    local ip="$1"
    local port="$2"
    if check_command qrencode; then
        echo ""
        qrencode -t ANSIUTF8 "vnc://$ip:$port"
        echo ""
    else
        warn "qrencode not installed — cannot generate QR"
    fi
}

# ═══════════════════════════════════════════════════════════
#  END OF HELPERS
# ═══════════════════════════════════════════════════════════

# ─── Version ───
SMVNC_HELPERS_VERSION="1.0.0"
export SMVNC_HELPERS_VERSION
