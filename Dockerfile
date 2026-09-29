# ═══════════════════════════════════════════════════════════
#  SmVnc - Modern XFCE VNC Desktop
#  Author : Sazid Mehmud (t.me/SmMehmudTg18)
#  Repo   : github.com/MehmudHub/SmVnc
#  Base   : accetto/ubuntu-vnc-xfce-g3
# ═══════════════════════════════════════════════════════════

FROM accetto/ubuntu-vnc-xfce-g3:latest

# ─── Metadata ───
LABEL maintainer="Sazid Mehmud <smmehmudgm18@gmail.com>"
LABEL description="Modern XFCE VNC Desktop for SmVnc"
LABEL version="1.0"
LABEL repo="https://github.com/MehmudHub/SmVnc"

# ─── Root হিসেবে কাজ করছি যাতে প্যাকেজ ইনস্টল করা যায় ───
USER root

# ─── Environment Variables ───
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Dhaka

# ─── ১. সিস্টেম আপডেট + প্রয়োজনীয় টুল ইনস্টল ───
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ── Core Utilities ──
    curl \
    wget \
    git \
    unzip \
    zip \
    nano \
    vim \
    htop \
    neofetch \
    tree \
    net-tools \
    iputils-ping \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    # ── Language & Font Support ──
    locales \
    fonts-firacode \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    fonts-font-awesome \
    # ── XFCE Essentials ──
    xfce4-terminal \
    thunar \
    thunar-archive-plugin \
    file-roller \
    mousepad \
    ristretto \
    # ── Media & Browsing ──
    firefox \
    # ── Screenshot & Productivity ──
    xfce4-screenshooter \
    xfce4-taskmanager \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─── ২. Locale সেট ───
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# ─── ৩. মডার্ন থিম এবং আইকন ইনস্টল ───
RUN apt-get update && apt-get install -y --no-install-recommends \
    arc-theme \
    papirus-icon-theme \
    plank \
    tilix \
    gnome-icon-theme \
    hicolor-icon-theme \
    adwaita-icon-theme \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─── ৪. মডার্ন ওয়ালপেপার ডাউনলোড ───
RUN mkdir -p /usr/share/backgrounds/smvnc && \
    cd /usr/share/backgrounds/smvnc && \
    wget -q "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1920" -O bg1.jpg || true && \
    wget -q "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1920" -O bg2.jpg || true && \
    wget -q "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1920" -O bg3.jpg || true && \
    wget -q "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=1920" -O bg4.jpg || true && \
    wget -q "https://images.unsplash.com/photo-1497436072909-60f360e1d4b1?w=1920" -O bg5.jpg || true

# ─── ৫. XFCE ডিফল্ট কনফিগারেশন (নতুন ইউজারের জন্য) ───
RUN mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

# ── থিম + আইকন সেটিং ──
RUN cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="Papirus-Dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Noto Sans 10"/>
    <property name="MonospaceFontName" type="string" value="Fira Code 10"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
EOF

# ── উইন্ডো ম্যানেজার থিম ──
RUN cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_font" type="string" value="Noto Sans Bold 10"/>
    <property name="title_alignment" type="string" value="center"/>
  </property>
</channel>
EOF

# ── ডেস্কটপ ওয়ালপেপার ──
RUN cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/smvnc/bg1.jpg"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# ── প্যানেল কনফিগারেশন (নিচে প্যানেল, Plank আলাদা) ──
RUN mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="32"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
</channel>
EOF

# ─── ৬. Tilix কে ডিফল্ট টার্মিনাল করা ───
RUN update-alternatives --install /usr/bin/x-terminal-emulator \
    x-terminal-emulator /usr/bin/tilix 50 && \
    update-alternatives --set x-terminal-emulator /usr/bin/tilix

# ─── ৭. Plank Dock অটো-স্টার্ট ───
RUN mkdir -p /etc/skel/.config/autostart && \
    cat > /etc/skel/.config/autostart/plank.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Stupidly simple dock
Exec=plank
Icon=plank
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# ─── ৮. Tilix কনফিগারেশন (ডার্ক থিম) ───
RUN mkdir -p /etc/skel/.config/tilix && \
    cat > /etc/skel/.config/tilix/schemes/smvnc-dark.json <<'EOF'
{
    "name": "SmVnc Dark",
    "comment": "Custom dark theme for SmVnc",
    "use-theme-colors": false,
    "foreground-color": "#e6e6e6",
    "background-color": "#1e1e2e",
    "palette": [
        "#1e1e2e", "#f38ba8", "#a6e3a1", "#f9e2af",
        "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de",
        "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af",
        "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"
    ]
}
EOF

# ─── ৯. Bash কনফিগারেশন (সুন্দর প্রম্পট) ───
RUN cat > /etc/skel/.bashrc <<'EOF'
# SmVnc Custom Bashrc
export PS1='\[\033[01;36m\]┌──(\[\033[01;32m\]\u@\h\[\033[01;36m\])-[\[\033[01;33m\]\w\[\033[01;36m\]]\n\[\033[01;36m\]└─\$ \[\033[00m\]'

alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# Welcome message
echo ""
echo -e "\033[01;36m  ╔══════════════════════════════════════════╗"
echo -e "  ║  🖥️  Welcome to SmVnc Desktop            ║"
echo -e "  ║  Made by Sazid Mehmud (t.me/SmMehmudTg18)║"
echo -e "  ╚══════════════════════════════════════════╝\033[00m"
echo ""
EOF

# ─── ১০. Desktop ফোল্ডার তৈরি (Volume Mount এর জন্য) ───
RUN mkdir -p /headless/Desktop && \
    chown -R headless:headless /headless

# ─── ১১. Firefox ডার্ক মোড ডিফল্ট ───
RUN mkdir -p /etc/skel/.mozilla/firefox/default && \
    cat > /etc/skel/.mozilla/firefox/profiles.ini <<'EOF'
[Profile0]
Name=default
IsRelative=1
Path=default
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF

# ─── ১২. headless ইউজারে ফিরে যাওয়া ───
USER headless

# ─── ১৩. Health Check ───
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD nc -z localhost 5901 || exit 1

# ─── ১৪. ডকুমেন্টেশন ───
LABEL org.opencontainers.image.source="https://github.com/MehmudHub/SmVnc"
LABEL org.opencontainers.image.description="Modern XFCE VNC Desktop"
LABEL org.opencontainers.image.licenses="MIT"

# ─── Base image এর entrypoint ব্যবহার হবে ───
# Base image accetto/ubuntu-vnc-xfce-g3 নিজেই VNC server চালু করে
