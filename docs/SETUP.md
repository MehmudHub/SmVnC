# 🛠️ SmVnc — Complete Setup Guide

> **Version:** 1.0.0  
> **Last Updated:** 2026  
> **Author:** Sazid Mehmud ([@SmMehmudTg18](https://t.me/SmMehmudTg18))

---

## 📋 Table of Contents

1. [System Requirements](#-system-requirements)
2. [Pre-Installation Checklist](#-pre-installation-checklist)
3. [Installation Steps](#-installation-steps)
4. [Verifying the Installation](#-verifying-the-installation)
5. [First-Time Setup](#-first-time-setup)
6. [Connecting from a Device](#-connecting-from-a-device)
7. [Advanced Configuration](#-advanced-configuration)
8. [Uninstalling SmVnc](#-uninstalling-smvnc)
9. [Troubleshooting](#-troubleshooting)

---

## 💻 System Requirements

### Minimum Requirements

| Component | Minimum | Recommended |
| :--- | :--- | :--- |
| **OS** | Linux (Fedora 38+) | Fedora 41 / Ubuntu 24.04 |
| **RAM** | 4 GB | 8 GB or more |
| **Disk** | 5 GB free | 20 GB free |
| **CPU** | 2 cores | 4 cores |
| **Network** | Local WiFi | Wired Ethernet |
| **Kernel** | 5.10+ | 6.0+ |

### Supported Distributions

| Distro | Status | Notes |
| :--- | :---: | :--- |
| 🟢 **Fedora** | ✅ Full Support | Primary target |
| 🟢 **Ubuntu / Debian** | ✅ Full Support | apt-based |
| 🟢 **Arch / Manjaro** | ✅ Full Support | pacman-based |
| 🟢 **openSUSE** | ✅ Full Support | zypper-based |
| 🟡 **Linux Mint / Pop!_OS** | ✅ Full Support | Ubuntu-based |
| 🔴 **Windows** | ❌ Not Supported | Use WSL2 or a Linux VM |
| 🔴 **macOS** | ❌ Not Supported | Missing `podman` + `ss` |

### Required Dependencies

`setup.sh` **অটো ইনস্টল** করবে, কিন্তু ম্যানুয়ালি লাগলে:

- **podman** `>= 4.0`
- **socat** `>= 1.7`
- **qrencode** `>= 4.0`
- **iproute** (for `ss` command)
- **bash** `>= 5.0`

---

## ✅ Pre-Installation Checklist

সেটআপ শুরু করার আগে নিচের বিষয়গুলো নিশ্চিত করো:

- [ ] **Linux OS** ইনস্টল করা আছে (Fedora/Ubuntu/Arch)
- [ ] **ইন্টারনেট কানেকশন** আছে (image build করতে লাগবে)
- [ ] **কমপক্ষে 5 GB** ফ্রি ডিস্ক স্পেস আছে
- [ ] **সুডো অ্যাক্সেস** আছে (`sudo` কমান্ড চলবে)
- [ ] একই **WiFi নেটওয়ার্কে** ফোন/ট্যাবলেট আছে (VNC কানেক্ট করতে)
- [ ] **VPN বন্ধ** করা আছে (নাহলে IP ডিটেক্ট ভুল হবে)

চেক কমান্ড:

```bash
# Free disk space
df -h $HOME

# sudo access
sudo -v

# Internet
ping -c 2 github.com
```

---

## 🚀 Installation Steps

### 📥 Step 1 — Repository Clone

টার্মিনাল খুলে (`Ctrl + Alt + T`) এই কমান্ডগুলো চালাও:

```bash
# যেখানে সেভ করতে চাও সেখানে যাও (উদাহরণ: হোম ডিরেক্টরি)
cd ~

# Repository ক্লোন করো
git clone https://github.com/MehmudHub/SmVnc.git

# ফোল্ডারে ঢুকো
cd SmVnc
```

সফল হলে ফোল্ডার স্ট্রাকচার দেখতে পাবে:

```text
SmVnc/
├── .gitignore
├── README.md
├── LICENSE
├── Dockerfile
├── SmVnc.sh
├── setup.sh
├── config/
├── scripts/
└── assets/
```

> ⚠️ **যদি Git ইনস্টল না থাকে:**
> ```bash
> sudo dnf install git        # Fedora
> sudo apt install git        # Ubuntu
> sudo pacman -S git          # Arch
> ```

---

### 🔓 Step 2 — Executable Permissions

Git ক্লোন করার পর ফাইলগুলোর এক্সিকিউট পারমিশন হারিয়ে যায়। এটা ঠিক করো:

```bash
chmod +x SmVnc.sh setup.sh scripts/*.sh
```

চেক করো:

```bash
ls -l SmVnc.sh setup.sh scripts/*.sh
```

প্রতিটি ফাইলের সামনে `-rwxr-xr-x` দেখতে পাবে — এটাই সঠিক।

---

### ⚙️ Step 3 — Run Setup Script

এবার সেই জাদুর কমান্ড — সব অটো-ইনস্টল হয়ে যাবে:

```bash
./setup.sh
```

**সেটআপ চলার সময় যা যা হবে:**

| ধাপ | কাজ |
| :---: | :--- |
| **1/6** | সিস্টেম চেক (OS, Dockerfile) |
| **2/6** | podman, socat, qrencode ইনস্টল |
| **3/6** | `data/`, `logs/`, `config/` ফোল্ডার তৈরি |
| **4/6** | Docker image build (`smvnc-modern:latest`) |
| **5/6** | সব `.sh` ফাইলে `+x` পারমিশন |
| **6/6** | গ্লোবাল কমান্ড `SmVnc` সেটআপ |

**সময় লাগবে:** প্রথমবার ৫-১০ মিনিট (image build-এর জন্য)।

**সুডো পাসওয়ার্ড চাইবে:** প্যাকেজ ইনস্টল আর সিমলিংক তৈরি করতে।

**সেটআপ সফল হলে যা দেখবে:**

```text
╔══════════════════════════════════════════════════════╗
║                                                      ║
║              ✓ SETUP COMPLETED!                      ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

---

### 🎯 Step 4 — Verify Installation

সেটআপ সঠিকভাবে হয়েছে কি না চেক করো:

#### ১. Podman চেক
```bash
podman --version
# Expected: podman version 4.x.x or 5.x.x
```

#### ২. socat চেক
```bash
socat -V | head -1
# Expected: socat version 1.7.x
```

#### ৩. qrencode চেক
```bash
qrencode --version
# Expected: qrencode version 4.x.x
```

#### ৪. Docker Image চেক
```bash
podman images | grep smvnc
# Expected: localhost/smvnc-modern   latest   <id>   <time>   ~1GB
```

#### ৫. Global Command চেক
```bash
which SmVnc
# Expected: /usr/local/bin/SmVnc

SmVnc version
# Expected: SmVnc v1.0.0
```

সব চেক পাস হলে ✅ — তুমি এখন ব্যবহারের জন্য রেডি!

---

## 🎬 First-Time Setup

### 🖥️ Launch the Dashboard

```bash
# যে কোনো ডিরেক্টরি থেকে
SmVnc

# অথবা প্রজেক্ট ফোল্ডার থেকে
cd ~/SmVnc
./SmVnc.sh
```

প্রথমবার চালু করলে ড্যাশবোর্ড দেখতে পাবে:

```text
   ███████╗███╗   ███╗██╗   ██╗███╗   ██╗ ██████╗
   ██╔════╝████╗ ████║██║   ██║████╗  ██║██╔════╝
   ███████╗██╔████╔██║██║   ██║██╔██╗ ██║██║
   ╚════██║██║╚██╔╝██║╚██╗ ██╔╝██║╚██╗██║██║
   ███████║██║ ╚═╝ ██║ ╚████╔╝ ██║ ╚████║╚██████╗
   ╚══════╝╚═╝     ╚═╝  ╚═══╝  ╚═╝  ╚═══╝ ╚═════╝

  Modern Multi-User VNC Desktop Manager
  ──────────────────────────────────────────────────
  ▸ Host IP   : 192.168.1.5
  ▸ Time      : Sunday, 29 September 2026 • 03:45 PM
  ▸ Data Dir  : /home/sazid/SmVnc/data
  ▸ Users     : 0 registered • 0 running

  ╔══════════════════════════════════════════════════════╗
  ║           VNC MANAGER - CONTROL DASHBOARD            ║
  ╠══════════════════════════════════════════════════════╣
  ║                                                      ║
  ║  [1]  View Active Ports                              ║
  ║  [2]  View All Users                                 ║
  ║  [3]  Start User Container                           ║
  ║  [4]  Stop Specific Port                             ║
  ║  [5]  Stop All Services                              ║
  ║  [6]  Add New User                                   ║
  ║  [7]  Remove User                                    ║
  ║  [8]  View Logs                                      ║
  ║  [9]  About Developer                                ║
  ║  [0]  Exit                                           ║
  ║                                                      ║
  ╚══════════════════════════════════════════════════════╝

  ➜  Select option:
```

---

### 👤 Add Your First User

**ধাপ ১:** ড্যাশবোর্ডে **`6`** প্রেস করো (Add New User)

**ধাপ ২:** ইউজারনেম দাও (যেমন: `sazid`)
```text
  ➜  Username: sazid
```

**ধাপ ৩:** স্ক্রিপ্ট অটো পোর্ট অ্যাসাইন করবে (5901):
```text
  [✓] User 'sazid' added successfully!
      Assigned Port: 5901
      Data Folder  : /home/sazid/SmVnc/data/sazid
```

**ধাপ ৪:** ড্যাশবোর্ডে ফিরে যাও, তারপর **`3`** প্রেস করে ইউজার চালু করো।

---

### 🚀 Start the Container

**ধাপ ১:** ড্যাশবোর্ডে **`3`** প্রেস করো

**ধাপ ২:** ইউজারনেম দাও:
```text
  ➜  Enter username (or 'b' to go back): sazid
```

**ধাপ ৩:** কন্টেইনার চালু হবে (৫-১০ সেকেন্ড সময় নেবে):
```text
  [~] Starting 'sazid' on port 5901...
  [✓] Container started successfully!
      Address : 192.168.1.5:5901
      Password: headless
```

**এখন তুমি কানেক্ট করার জন্য রেডি!** 🎉

---

## 📱 Connecting from a Device

### 📲 From Android Phone

**ধাপ ১:** Google Play থেকে ইনস্টল করো:
- **RealVNC Viewer** (সাজেস্টেড) — [Play Store](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android)
- অথবা **bVNC Free** — [Play Store](https://play.google.com/store/apps/details?id=com.iiordanov.freebVNC)

**ধাপ ২:** অ্যাপ খুলে **`+`** বাটনে ক্লিক করো (Add Connection)

**ধাপ ৩:** তথ্য দাও:

| Field | Value |
| :--- | :--- |
| **Name** | `SmVnc - Sazid` (যেকোনো নাম) |
| **Address** | `192.168.1.5:5901` (তোমার নিজের IP:Port) |
| **Password** | `headless` |

**ধাপ ৪:** **Connect** প্রেস করো।

**ধাপ ৫:** মডার্ন XFCE ডেস্কটপ চলে আসবে! 🎊

---

### 💻 From Another PC (Linux/Windows/macOS)

**Linux:** `remmina` ইনস্টল করো:
```bash
sudo dnf install remmina remmina-plugins-vnc
```

**Windows/macOS:** [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) ডাউনলোড করো।

**Connection Address:** `192.168.1.5:5901`  
**Password:** `headless`

---

### 📷 QR Code দিয়ে কানেক্ট

তোমার স্ক্রিপ্ট QR কোড জেনারেট করতে পারে। ড্যাশবোর্ডে **`9`** প্রেস করে ইউজারনেম দাও:

```text
  [i] Scan this QR code from your phone:

  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
  █ ▄▄▄▄▄ █▀▀▄█▀▄▀ █▀▄▀▀█ ▄▄▄▄▄ █
  █ █   █ █▀ ▄ ▀▄▀▀ █▀▄ █ █   █ █
  ...
```

RealVNC Viewer-এ QR স্ক্যানার আছে — সরাসরি স্ক্যান করে কানেক্ট করতে পারবে।

---

## 🔧 Advanced Configuration

### ⚙️ Change Idle Timeout

ডিফল্ট টাইমআউট **১০ মিনিট**। এটা বদলাতে:

```bash
# ৫ মিনিট করে দাও
SMVNC_IDLE_TIMEOUT=300 ./scripts/idle-monitor.sh start
```

বা স্থায়ীভাবে করতে `SmVnc.sh`-এ `IDLE_TIMEOUT` ভেরিয়েবল বদলাও।

---

### 🌐 Change VNC Password

ডিফল্ট পাসওয়ার্ড **`headless`**। নিজের পাসওয়ার্ড দিতে `SmVnc.sh`-এ খুঁজে বের করো:

```bash
VNC_PASSWORD="headless"
```

বদলে দাও:

```bash
VNC_PASSWORD="your-secret-password"
```

তারপর `start_container()` ফাংশনে যোগ করো:

```bash
podman run -d --name "$cname" \
    -e VNC_PW="$VNC_PASSWORD" \
    -p "${port}:${INTERNAL_VNC_PORT}" \
    ...
```

---

### 🚀 Enable Auto-Wake Feature

কেউ কানেক্ট করলেই কন্টেইনার চালু হবে — এটা পেতে:

```bash
# auto-wake daemon চালু করো
./scripts/auto-wake.sh start

# ব্যাকগ্রাউন্ডে চালাতে
nohup ./scripts/auto-wake.sh start &>/dev/null &
```

---

### 😴 Start Idle Monitor

নিষ্ক্রিয় কন্টেইনার অটো-বন্ধ করতে:

```bash
./scripts/idle-monitor.sh start
```

স্ট্যাটাস চেক:

```bash
./scripts/idle-monitor.sh status
```

---

### 🔄 Auto-Start on Boot (systemd)

Boot-এ অটো-চালু করতে `~/.config/systemd/user/smvnc-idle.service` ফাইল বানাও:

```ini
[Unit]
Description=SmVnc Idle Monitor
After=default.target

[Service]
Type=simple
ExecStart=%h/SmVnc/scripts/idle-monitor.sh run
Restart=on-failure
RestartSec=10
Environment="SMVNC_IDLE_TIMEOUT=600"

[Install]
WantedBy=default.target
```

চালু করো:

```bash
systemctl --user daemon-reload
systemctl --user enable --now smvnc-idle.service
systemctl --user status smvnc-idle.service
```

---

### 🔥 Firewall Configuration

Fedora-তে পোর্ট ওপেন করতে:

```bash
# একটি পোর্ট
sudo firewall-cmd --add-port=5901/tcp --permanent

# রেঞ্জ
sudo firewall-cmd --add-port=5901-5905/tcp --permanent

# রিলোড
sudo firewall-cmd --reload
```

---

### 🎨 Customize Desktop Theme

`Dockerfile`-এ `Arc-Dark` বদলে অন্য থিম:

```dockerfile
RUN apt-get install -y \
    arc-theme \             # বদলে: adapta-gtk-theme
    papirus-icon-theme \    # বাদ দিলে: numix-icon-theme
    plank \
```

তারপর rebuild:

```bash
podman build -t smvnc-modern:latest .
```

---

## 🗑️ Uninstalling SmVnc

সম্পূর্ণভাবে মুছতে চাইলে:

### ধাপ ১ — কন্টেইনার বন্ধ ও ডিলিট

```bash
# সব SmVnc কন্টেইনার
podman stop $(podman ps -q -f name=smvnc-) 2>/dev/null
podman rm $(podman ps -aq -f name=smvnc-) 2>/dev/null

# ইমেজ ডিলিট
podman rmi smvnc-modern:latest
```

### ধাপ ২ — Global Command সরাও

```bash
sudo rm /usr/local/bin/SmVnc
```

### ধাপ ৩ — প্রজেক্ট ফোল্ডার ডিলিট (⚠️ সব ডাটা মুছে যাবে!)

```bash
rm -rf ~/SmVnc
```

### ধাপ ৪ — Firewall Rules পরিষ্কার

```bash
sudo firewall-cmd --remove-port=5901-5905/tcp --permanent
sudo firewall-cmd --reload
```

---

## 🐛 Troubleshooting

### ❓ সমাধান: "Permission denied"

**কারণ:** ফাইলের `+x` পারমিশন নেই।

**সমাধান:**
```bash
chmod +x SmVnc.sh setup.sh scripts/*.sh
```

---

### ❓ সমাধান: "Podman not found"

**কারণ:** Podman ইনস্টল নেই।

**সমাধান:**
```bash
# Fedora
sudo dnf install podman

# Ubuntu
sudo apt install podman

# Arch
sudo pacman -S podman
```

---

### ❓ সমাধান: "Failed to build image"

**কারণসমূহ:**
1. ইন্টারনেট কানেকশন নেই
2. ডিস্ক স্পেস কম
3. Docker Hub rate limit

**সমাধান:**
```bash
# ম্যানুয়ালি বিল্ড করে দেখো
podman build -t smvnc-modern:latest .

# ডিস্ক চেক
df -h

# DNS ঠিক আছে কি না
podman run --rm alpine ping -c 2 google.com
```

---

### ❓ সমাধান: "Port already in use"

**কারণ:** পোর্ট অন্য কিছু ব্যবহার করছে।

**সমাধান:**
```bash
# কে ব্যবহার করছে দেখো
sudo ss -tuln | grep 5901
# অথবা
sudo lsof -i :5901

# প্রসেস বন্ধ করো (PID দিয়ে)
sudo kill <PID>

# অথবা অন্য পোর্ট ব্যবহার করো: 6001, 6002...
```

---

### ❓ সমাধান: "Cannot connect from phone"

**কারণসমূহ:**
1. ফোন আর PC একই WiFi-তে নেই
2. VPN চালু
3. Firewall পোর্ট ব্লক করছে
4. ভুল IP

**সমাধান:**

```bash
# ১. IP চেক করো
ip -4 addr show scope global | grep -v tun | grep inet

# ২. Firewall চেক
sudo firewall-cmd --list-ports

# ৩. কন্টেইনার পোর্ট চেক
podman port smvnc-sazid

# ৪. পিং টেস্ট (ফোন থেকে)
# ping 192.168.1.5
```

**VPN বন্ধ করো** — স্ক্রিপ্ট VPN IP বাদ দেয় কিন্তু ফোনে VPN থাকলে সেটাও বন্ধ করতে হবে।

---

### ❓ সমাধান: "VNC screen is black"

**কারণ:** VNC সার্ভার এখনো পুরোপুরি বুট হয়নি।

**সমাধান:**
```bash
# কন্টেইনারের লগ দেখো
podman logs smvnc-sazid

# ১০-১৫ সেকেন্ড অপেক্ষা করে আবার চেষ্টা করো
```

---

### ❓ সমাধান: "QR code not showing"

**কারণ:** qrencode ইনস্টল নেই।

**সমাধান:**
```bash
sudo dnf install qrencode
# অথবা
./setup.sh
```

---

### ❓ সমাধান: "Idle monitor won't start"

**কারণ:** পুরনো PID ফাইল আটকে আছে।

**সমাধান:**
```bash
# Stale PID ফাইল ডিলিট
rm -f ~/SmVnc/.run/*.pid

# আবার চালু করো
./scripts/idle-monitor.sh start
```

---

### ❓ সমাধান: "Container keeps restarting"

**কারণ:** রিসোর্স কম বা ইমেজ করাপ্টেড।

**সমাধান:**
```bash
# কন্টেইনারের লগ দেখো
podman logs --tail 50 smvnc-sazid

# ইমেজ রিবিল্ড করো
podman rmi smvnc-modern:latest
./setup.sh
```

---

## 📞 Getting Help

যদি উপরের সমাধানেও কাজ না হয়:

| Channel | Link |
| :--- | :--- |
| 🐛 **Bug Report** | [GitHub Issues](https://github.com/MehmudHub/SmVnc/issues) |
| 💬 **Telegram** | [t.me/SmMehmudTg18](https://t.me/SmMehmudTg18) |
| 📧 **Email** | [smmehmudgm18@gmail.com](mailto:smmehmudgm18@gmail.com) |

**Bug report করার সময় দাও:**
```bash
# সিস্টেম তথ্য
uname -a
cat /etc/os-release

# SmVnc log
cat ~/SmVnc/logs/SmVnc.log

# Podman তথ্য
podman version
podman ps -a
```

---

<div align="center">

**SmVnc — Setup Guide**

Made with ❤️ by [Sazid Mehmud](https://t.me/SmMehmudTg18)

⭐ [Star the repo](https://github.com/MehmudHub/SmVnc) if this helped!

</div>
