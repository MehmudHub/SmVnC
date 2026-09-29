#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  SmVnc - Automated Setup & Installer
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Repo   : github.com/MehmudHub/SmVnc
#  License: MIT
# ═══════════════════════════════════════════════════════════

set -o pipefail

# ─────────────────────────────────────────────
#  Paths
# ─────────────────────────────────────────────
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"
LOG_DIR="$BASE_DIR/logs"
DOCKERFILE="$BASE_DIR/Dockerfile"
IMAGE_NAME="smvnc-modern:latest"
SYMLINK_PATH="/usr/local/bin/SmVnc"

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

# ─────────────────────────────────────────────
#  Helper Functions
# ─────────────────────────────────────────────

print_banner() {
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
    echo -e "  ${BOLD}${CYAN}▶ Automated Setup & Installer${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
    echo ""
}

step() {
    echo ""
    echo -e "  ${CYAN}${BOLD}▶ $1${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
}

ok() {
    echo -e "  ${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "  ${YELLOW}[~]${NC} $1"
}

err() {
    echo -e "  ${RED}[!]${NC} $1"
}

info() {
    echo -e "  ${CYAN}[i]${NC} $1"
}

die() {
    echo ""
    err "$1"
    echo ""
    echo -e "  ${RED}${BOLD}Setup failed. Please fix the issue and try again.${NC}"
    exit 1
}

# ─────────────────────────────────────────────
#  Root Check
# ─────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
    die "Do NOT run setup.sh as root. Run as normal user — sudo will be used where needed."
fi

# ─────────────────────────────────────────────
#  Distro Detection
# ─────────────────────────────────────────────
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_NAME="$PRETTY_NAME"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown"
    fi
}

# ─────────────────────────────────────────────
#  Package Installation
# ─────────────────────────────────────────────
install_packages() {
    local packages=("$@")
    case "$DISTRO_ID" in
        fedora|rhel|centos)
            sudo dnf install -y "${packages[@]}" || return 1
            ;;
        ubuntu|debian|linuxmint|pop)
            sudo apt-get update -qq
            sudo apt-get install -y "${packages[@]}" || return 1
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --noconfirm "${packages[@]}" || return 1
            ;;
        opensuse*|suse)
            sudo zypper install -y "${packages[@]}" || return 1
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

check_command() {
    command -v "$1" &>/dev/null
}

# ═══════════════════════════════════════════════════════════
#  START INSTALLATION
# ═══════════════════════════════════════════════════════════

print_banner

# ─── Step 1: System Check ───
step "Step 1/6 — Checking system"

detect_distro
info "Distro : ${BOLD}$DISTRO_NAME${NC}"
info "Base   : ${BOLD}$BASE_DIR${NC}"

if [ ! -f "$DOCKERFILE" ]; then
    die "Dockerfile not found at: $DOCKERFILE"
fi
ok "Dockerfile found"

sleep 1

# ─── Step 2: Install Dependencies ───
step "Step 2/6 — Checking and installing dependencies"

MISSING=()

if check_command podman; then
    ok "podman : $(podman --version | awk '{print $3}')"
else
    warn "podman not found — will install"
    MISSING+=("podman")
fi

if check_command socat; then
    ok "socat  : installed"
else
    warn "socat not found — will install"
    MISSING+=("socat")
fi

if check_command qrencode; then
    ok "qrencode : installed"
else
    warn "qrencode not found — will install"
    MISSING+=("qrencode")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    info "Installing missing packages: ${BOLD}${MISSING[*]}${NC}"
    echo -e "  ${DIM}You may be asked for your sudo password.${NC}"
    echo ""

    if ! install_packages "${MISSING[@]}"; then
        die "Failed to install packages: ${MISSING[*]}\n  Please install them manually and re-run ./setup.sh"
    fi
    echo ""
    ok "All packages installed successfully"
else
    ok "All dependencies already installed"
fi

sleep 1

# ─── Step 3: Create Folders ───
step "Step 3/6 — Creating project folders"

for dir in "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        ok "Created : ${dir#$BASE_DIR/}/"
    else
        info "Exists  : ${dir#$BASE_DIR/}/"
    fi
done

# .gitkeep ফাইল তৈরি
[ ! -f "$DATA_DIR/.gitkeep" ] && touch "$DATA_DIR/.gitkeep"
[ ! -f "$LOG_DIR/.gitkeep" ]  && touch "$LOG_DIR/.gitkeep"
[ ! -f "$CONFIG_DIR/users.conf" ] && touch "$CONFIG_DIR/users.conf"

sleep 1

# ─── Step 4: Build Docker Image ───
step "Step 4/6 — Building SmVnc Docker image"

if podman image exists "$IMAGE_NAME" 2>/dev/null; then
    warn "Image '$IMAGE_NAME' already exists"
    echo ""
    echo -en "  ${YELLOW}Rebuild image? (y/N): ${NC}"
    read -r REBUILD
    if [[ "$REBUILD" =~ ^[Yy]$ ]]; then
        info "Removing old image..."
        podman rmi "$IMAGE_NAME" &>/dev/null
    else
        info "Skipping image build — using existing image"
        SKIP_BUILD=1
    fi
fi

if [ -z "${SKIP_BUILD:-}" ]; then
    echo ""
    info "Building image from Dockerfile..."
    echo -e "  ${DIM}This may take 5-10 minutes on first run.${NC}"
    echo -e "  ${DIM}Please be patient and keep your internet connected.${NC}"
    echo ""

    if podman build -t "$IMAGE_NAME" "$BASE_DIR"; then
        echo ""
        ok "Image built successfully : ${BOLD}$IMAGE_NAME${NC}"
    else
        die "Docker image build failed.\n  Check Dockerfile and internet connection."
    fi
fi

sleep 1

# ─── Step 5: Set Permissions ───
step "Step 5/6 — Setting executable permissions"

for f in "$BASE_DIR"/*.sh; do
    if [ -f "$f" ]; then
        chmod +x "$f"
        ok "chmod +x : $(basename "$f")"
    fi
done

sleep 1

# ─── Step 6: Global Command ───
step "Step 6/6 — Creating global command"

if [ -L "$SYMLINK_PATH" ] || [ -f "$SYMLINK_PATH" ]; then
    warn "Existing command found at $SYMLINK_PATH — updating..."
    sudo rm -f "$SYMLINK_PATH"
fi

sudo ln -sf "$BASE_DIR/SmVnc.sh" "$SYMLINK_PATH"

if [ -L "$SYMLINK_PATH" ]; then
    ok "Global command created : ${BOLD}SmVnc${NC}"
    info "Now you can run 'SmVnc' from any directory"
else
    warn "Failed to create symlink at $SYMLINK_PATH"
    info "You can still run it with: ./SmVnc.sh"
fi

# ═══════════════════════════════════════════════════════════
#  SUCCESS
# ═══════════════════════════════════════════════════════════

echo ""
echo ""
echo -e "  ${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}${BOLD}║                                                      ║${NC}"
echo -e "  ${GREEN}${BOLD}║              ✓ SETUP COMPLETED!                      ║${NC}"
echo -e "  ${GREEN}${BOLD}║                                                      ║${NC}"
echo -e "  ${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}${CYAN}▶ How to Use${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${YELLOW}Option 1:${NC} Run from project folder"
echo -e "    ${BOLD}cd $BASE_DIR${NC}"
echo -e "    ${BOLD}./SmVnc.sh${NC}"
echo ""
echo -e "  ${YELLOW}Option 2:${NC} Run from anywhere (global command)"
echo -e "    ${BOLD}SmVnc${NC}"
echo ""
echo -e "  ${BOLD}${CYAN}▶ Next Steps${NC}"
echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"
echo -e "   ${GREEN}1.${NC} Launch SmVnc dashboard"
echo -e "   ${GREEN}2.${NC} Press ${BOLD}[6]${NC} to add your first user"
echo -e "   ${GREEN}3.${NC} Press ${BOLD}[3]${NC} to start their container"
echo -e "   ${GREEN}4.${NC} Connect from VNC app on your phone"
echo ""
echo -e "  ${DIM}Docs    : https://github.com/MehmudHub/SmVnc${NC}"
echo -e "  ${DIM}Author  : Sazid Mehmud (t.me/SmMehmudTg18)${NC}"
echo ""
echo -e "  ${MAGENTA}Happy desktop-ing! 🖥️${NC}"
echo ""
