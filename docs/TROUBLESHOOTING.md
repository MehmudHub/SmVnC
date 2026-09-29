# 🐛 SmVnc — Troubleshooting Guide

> **Version:** 1.0.0  
> **Last Updated:** 2026  
> **Author:** Sazid Mehmud ([@SmMehmudTg18](https://t.me/SmMehmudTg18))

---

## 📋 Table of Contents

1. [Quick Diagnostics](#-quick-diagnostics)
2. [Installation Issues](#-installation-issues)
3. [Podman / Container Issues](#-podman--container-issues)
4. [Dockerfile / Image Build Issues](#-dockerfile--image-build-issues)
5. [VNC Connection Issues](#-vnc-connection-issues)
6. [Firewall Issues](#-firewall-issues)
7. [Network / IP Issues](#-network--ip-issues)
8. [Auto-Wake Daemon Issues](#-auto-wake-daemon-issues)
9. [Idle Monitor Issues](#-idle-monitor-issues)
10. [Performance Issues](#-performance-issues)
11. [Data / Persistence Issues](#-data--persistence-issues)
12. [Dashboard / UI Issues](#-dashboard--ui-issues)
13. [Git / GitHub Issues](#-git--github-issues)
14. [Debug Mode & Log Collection](#-debug-mode--log-collection)
15. [Emergency Recovery](#-emergency-recovery)

---

## 🔍 Quick Diagnostics

সমস্যা হলে প্রথমে এই কমান্ডগুলো চালাও:

```bash
# ─── System Information ───
uname -a
cat /etc/os-release | head -5
echo ""

# ─── Resource Check ───
echo "=== Memory ==="
free -h
echo ""
echo "=== Disk ==="
df -h $HOME
echo ""

# ─── Dependency Check ───
echo "=== Dependencies ==="
for cmd in podman socat qrencode ss git; do
    if command -v $cmd &>/dev/null; then
        echo "✅ $cmd: $(command -v $cmd)"
    else
        echo "❌ $cmd: NOT FOUND"
    fi
done
echo ""

# ─── Podman Status ───
echo "=== Podman Containers ==="
podman ps -a --filter "name=smvnc-"
echo ""

# ─── Logs ───
echo "=== Recent Logs ==="
tail -20 ~/SmVnc/logs/SmVnc.log 2>/dev/null || echo "No logs found"
```

**এই আউটপুট কপি করে রাখো** — সমস্যা রিপোর্ট করার সময় কাজে লাগবে।

---

## 🚨 Installation Issues

### ❌ Issue 1.1 — `Permission denied` setup.sh চালাতে গেলে

**Error Message:**
```bash
bash: ./setup.sh: Permission denied
```

**কারণ:** ফাইলে executable permission নেই।

**সমাধান:**
```bash
cd ~/SmVnc
chmod +x setup.sh SmVnc.sh scripts/*.sh

# চেক করো
ls -l setup.sh
# Expected: -rwxr-xr-x ... setup.sh
```

---

### ❌ Issue 1.2 — `No such file or directory` (shebang এরর)

**Error Message:**
```bash
bash: ./setup.sh: /bin/bash^M: bad interpreter: No such file or directory
```

**কারণ:** ফাইল Windows-এ এডিট করা হয়েছে (`\r\n` লাইন এন্ডিং)।

**সমাধান:**
```bash
# dos2unix ইনস্টল করো
sudo dnf install dos2unix

# সব .sh ফাইলে কনভার্ট করো
find ~/SmVnc -name "*.sh" -exec dos2unix {} \;

# অথবা ম্যানুয়ালি
sed -i 's/\r$//' ~/SmVnc/*.sh ~/SmVnc/scripts/*.sh
```

---

### ❌ Issue 1.3 — `Missing dependencies: podman socat qrencode`

**কারণ:** প্যাকেজ ইনস্টল হয়নি (অথবা install_packages() ফেল করেছে)।

**সমাধান:**

**Fedora:**
```bash
sudo dnf install podman socat qrencode iproute
```

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install podman socat qrencode iproute2
```

**Arch:**
```bash
sudo pacman -S podman socat qrencode iproute2
```

**openSUSE:**
```bash
sudo zypper install podman socat qrencode iproute2
```

তারপর আবার:
```bash
./setup.sh
```

---

### ❌ Issue 1.4 — `Do NOT run setup.sh as root`

**Error Message:**
```bash
[!] Do NOT run setup.sh as root. Run as normal user — sudo will be used where needed.
```

**কারণ:** তুমি `sudo ./setup.sh` দিয়ে চালিয়েছ।

**সমাধান:**
```bash
# sudo ছাড়া চালাও
./setup.sh
```

স্ক্রিপ্ট নিজেই যেখানে দরকার সেখানে sudo ব্যবহার করবে।

---

### ❌ Issue 1.5 — `Dockerfile not found`

**Error Message:**
```bash
[!] Dockerfile not found at: /home/user/SmVnc/Dockerfile
```

**কারণ:** Dockerfile ডিলিট হয়েছে বা ভুল ফোল্ডারে আছো।

**সমাধান:**
```bash
# প্রজেক্ট রুটে আছো কি না চেক
pwd
ls -la Dockerfile

# না থাকলে Git থেকে আবার আনো
git fetch origin
git checkout Dockerfile
```

---

## 🐳 Podman / Container Issues

### ❌ Issue 2.1 — `podman: command not found`

**সমাধান:**
```bash
# Fedora
sudo dnf install podman

# Ubuntu
sudo apt install podman

# verify
podman --version
```

---

### ❌ Issue 2.2 — `Error: creating container storage: the container name "smvnc-sazid" is already in use`

**কারণ:** একই নামের কন্টেইনার আগে থেকেই আছে।

**সমাধান:**
```bash
# কন্টেইনার ডিলিট করো
podman rm -f smvnc-sazid

# তারপর আবার স্টার্ট করো
./SmVnc.sh
# → [3] Start User Container
```

অথবা ড্যাশবোর্ডের **[7] Remove User** → আবার **[6] Add New User**।

---

### ❌ Issue 2.3 — `Error: port is already allocated`

**Error Message:**
```bash
Error: rootlessport cannot expose privileged port 5901
```

**কারণ:** পোর্ট অন্য কেউ ব্যবহার করছে।

**সমাধান:**
```bash
# কে ব্যবহার করছে
sudo ss -tulnp | grep 5901
# অথবা
sudo lsof -i :5901

# প্রসেস বন্ধ করো
sudo kill -9 <PID>

# অথবা অন্য পোর্ট ব্যবহার করো (6001, 6002, ...)
```

**Rootless Podman-এর ক্ষেত্রে** 1024-এর নিচের পোর্ট ব্লক থাকে, কিন্তু 5901 ওপরে, তাই সমস্যা হবে না।

---

### ❌ Issue 2.4 — Container চালু হচ্ছে কিন্তু সাথে সাথে বন্ধ হয়ে যাচ্ছে

**Error Message:**
```bash
podman ps -a
# CONTAINER ID  ...  STATUS
# abc123        ...  Exited (1) 2 seconds ago
```

**কারণ:** ইমেজ বা config-এ সমস্যা।

**সমাধান:**
```bash
# লগ দেখো
podman logs smvnc-sazid

# সবশেষ ৫০ লাইন
podman logs --tail 50 smvnc-sazid

# ইমেজ ঠিক আছে কি না
podman image inspect smvnc-modern:latest

# ইমেজ রিবিল্ড করো
podman rmi smvnc-modern:latest
./setup.sh
```

---

### ❌ Issue 2.5 — `Error: image not known`

**সমাধান:**
```bash
# ইমেজ আছে কি না চেক
podman images | grep smvnc

# না থাকলে বিল্ড করো
./setup.sh

# অথবা ম্যানুয়ালি
cd ~/SmVnc
podman build -t smvnc-modern:latest .
```

---

### ❌ Issue 2.6 — Rootless Podman-এ Permission Issues

**Error Message:**
```bash
Error: cannot clone: Operation not permitted
```

**কারণ:** Rootless Podman-এ subuid/subgid ম্যাপিং ঠিক নেই।

**সমাধান:**
```bash
# subuid / subgid চেক করো
cat /etc/subuid
cat /etc/subgid

# নিজের entry আছে কি না দেখো — না থাকলে যোগ করো:
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER

# Podman reset করো
podman system reset

# Logout → Login (সবচেয়ে গুরুত্বপূর্ণ!)
```

---

## 🏗️ Dockerfile / Image Build Issues

### ❌ Issue 3.1 — Build fail: `Could not resolve host`

**কারণ:** DNS সমস্যা।

**সমাধান:**
```bash
# DNS চেক
cat /etc/resolv.conf

# Test
podman run --rm alpine ping -c 2 google.com

# DNS server যোগ করো
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
```

---

### ❌ Issue 3.2 — `No space left on device`

**সমাধান:**
```bash
# ডিস্ক চেক
df -h
podman system df

# পুরনো ইমেজ পরিষ্কার
podman system prune -a

# পুরনো volume
podman volume prune

# Build cache পরিষ্কার
podman builder prune
```

---

### ❌ Issue 3.3 — `Failed to download wallpaper`

**কারণ:** Dockerfile-এ Unsplash থেকে ওয়ালপেপার ডাউনলোড ফেল করেছে।

**সমাধান:** এটা ক্ষতিকর নয় — `|| true` দেওয়া আছে, তাই স্কিপ হয়ে যাবে। বিল্ড continue হবে।

তবে চাইলে ডকারফাইল থেকে ওয়ালপেপার সেকশন বাদ দিতে পারো:

```dockerfile
# এই লাইনগুলো মুছে দাও
# RUN mkdir -p /usr/share/backgrounds/smvnc && \
#     cd /usr/share/backgrounds/smvnc && \
#     wget -q "..." -O bg1.jpg || true && \
#     ...
```

---

### ❌ Issue 3.4 — `base image not found: accetto/ubuntu-vnc-xfce-g3:latest`

**সমাধান:**
```bash
# ম্যানুয়ালি pull করো
podman pull accetto/ubuntu-vnc-xfce-g3:latest

# না পেলে ট্যাগ ছাড়া চেষ্টা করো
podman pull accetto/ubuntu-vnc-xfce-g3
```

Dockerfile-এ ট্যাগ বদলে দাও:
```dockerfile
FROM accetto/ubuntu-vnc-xfce-g3
```

---

### ❌ Issue 3.5 — Build খুব ধীর

**কারণ:** ফন্ট, থিম, Firefox ডাউনলোড হতে সময় লাগে।

**সমাধান:**
- ধৈর্য ধরো (প্রথমবার ৫-১৫ মিনিট স্বাভাবিক)
- ইন্টারনেট স্পিড চেক করো
- VPN বন্ধ করো (কখনো DNS রেসলভ ধীর করে)
- Podman mirror ব্যবহার করো:

```bash
# /etc/containers/registries.conf
unqualified-search-registries = ["docker.io", "registry.fedoraproject.org"]
```

---

## 📺 VNC Connection Issues

### ❌ Issue 4.1 — ফোন থেকে কানেক্ট হচ্ছে না, "Connection refused"

**কারণসমূহ:**
1. কন্টেইনার চলছে না
2. পোর্ট ব্লকড
3. ভুল IP
4. Firewall

**সমাধান:**

**ধাপ ১: কন্টেইনার চলছে কি না চেক**
```bash
podman ps | grep smvnc
# কিছু না দেখালে → ./SmVnc.sh → [3] Start User
```

**ধাপ ২: পোর্ট লিসেন করছে কি না**
```bash
ss -tuln | grep 5901
# Expected: tcp LISTEN ... :5901
```

**ধাপ ৩: IP চেক**
```bash
ip -4 -o addr show scope global | grep -v tun | grep inet
# এই IP-টাই ফোনে দাও
```

**ধাপ ৪: Firewall**
```bash
sudo firewall-cmd --list-ports | grep 5901
# না থাকলে → Issue 5.1 দেখো
```

**ধাপ ৫: লোকাল টেস্ট**
```bash
# একই মেশিনে VNC দিয়ে ট্রাই করো
vncviewer localhost:5901
# (vncviewer ইনস্টল না থাকলে → sudo dnf install tigervnc)
```

---

### ❌ Issue 4.2 — "Connection timed out"

**কারণ:** প্যাকেট হারিয়ে যাচ্ছে বা ফায়ারওয়াল ড্রপ করছে।

**সমাধান:**
```bash
# ফোন আর PC একই WiFi-তে?
# ফোন থেকে PC-কে ping করো (Termux-এ):
# ping 192.168.1.5

# PC থেকে ফোনে ping:
ping <phone-ip>

# Firewall temporary বন্ধ করে টেস্ট
sudo systemctl stop firewalld
# টেস্ট শেষে আবার চালু
sudo systemctl start firewalld
```

---

### ❌ Issue 4.3 — "Authentication failed"

**কারণ:** ভুল পাসওয়ার্ড।

**সমাধান:**

ডিফল্ট পাসওয়ার্ড: **`headless`**

যদি কাস্টম পাসওয়ার্ড সেট করে থাকো, `SmVnc.sh`-এ `VNC_PASSWORD` ভেরিয়েবল চেক করো:

```bash
grep VNC_PASSWORD ~/SmVnc/SmVnc.sh
```

---

### ❌ Issue 4.4 — VNC screen কালো (Black)

**কারণ:** VNC সার্ভার এখনো পুরোপুরি লোড হয়নি।

**সমাধান:**
```bash
# কন্টেইনার লগ চেক
podman logs smvnc-sazid

# VNC পোর্ট ওপেন হয়েছে কি না
ss -tuln | grep 5901

# ১৫ সেকেন্ড অপেক্ষা করে আবার ট্রাই করো

# কন্টেইনার রিস্টার্ট করো
podman restart smvnc-sazid
```

---

### ❌ Issue 4.5 — VNC screen ধীরে চলছে, ল্যাগ

**কারণ:** ডিফল্ট compression কম, bandwidth বেশি।

**সমাধান — VNC ক্লায়েন্টে সেটিংস বদলাও:**

**RealVNC Viewer:**
- Menu → Properties → Picture Quality → **"Low"** বা **"Medium"**
- Menu → Options → Prefer Direct Connection → ON

**bVNC:**
- Preferences → Color Model → **"256 colors"**
- Preferences → Force Full → OFF

**নেটওয়ার্ক:**
- ওয়্যারড কানেকশন ব্যবহার করো
- 2.4 GHz এর বদলে 5 GHz WiFi

---

## 🔥 Firewall Issues

### ❌ Issue 5.1 — পোর্ট ওপেন করা যাচ্ছে না

**সমাধান:**
```bash
# Firewall চলছে কি না চেক
sudo systemctl status firewalld

# পোর্ট যোগ করো
sudo firewall-cmd --add-port=5901/tcp --permanent
sudo firewall-cmd --reload

# ভেরিফাই
sudo firewall-cmd --list-ports
sudo firewall-cmd --query-port=5901/tcp
```

---

### ❌ Issue 5.2 — UFW (Ubuntu)

```bash
sudo ufw allow 5901/tcp
sudo ufw allow 5901:5905/tcp
sudo ufw status
```

---

### ❌ Issue 5.3 — iptables দিয়ে ম্যানুয়াল রুল

```bash
# Temporary rule
sudo iptables -A INPUT -p tcp --dport 5901 -j ACCEPT

# Permanent করতে (Fedora-তে iptables-services)
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```

**⚠️ সতর্কতা:** এগুলো permanent নয়। firewalld সুপারিশ করা হয়।

---

## 🌐 Network / IP Issues

### ❌ Issue 6.1 — `get_local_ip` ভুল IP দেখাচ্ছে

**কারণ:** VPN / Docker / VirtualBox ইন্টারফেস।

**সমাধান:**

স্ক্রিপ্ট ইতিমধ্যে `tun|tap|ppp|wg` বাদ দেয়। কিন্তু যদি `docker0`, `virbr0`, `br-xxxxx` থাকে:

```bash
# ম্যানুয়ালি IP দেখো
ip -4 addr show scope global

# কোন ইন্টারফেস আসল
# সাধারণত: enp*, wlan*, eth*
```

স্ক্রিপ্টে ফিল্টার বাড়াও:

```bash
# SmVnc.sh-এ get_local_ip() ফাংশন
grep -Ev "tun|tap|ppp|wg|docker|virbr|br-|veth"
```

---

### ❌ Issue 6.2 — IP পরিবর্তন হয়ে যাচ্ছে (Dynamic IP)

**কারণ:** DHCP লিজ এক্সপায়ার।

**সমাধান:**

**Static IP দাও:**

**Fedora (nmcli):**
```bash
# কানেকশনের নাম দেখো
nmcli con show

# Static IP সেট করো
sudo nmcli con mod "Wired connection 1" \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8 1.1.1.1"

sudo nmcli con up "Wired connection 1"
```

---

### ❌ Issue 6.3 — ফোন অন্য subnet-এ

**কারণ:** PC `192.168.1.x`-এ, ফোন `192.168.0.x`-এ (dual-band router এ আলাদা subnet)।

**সমাধান:**
- ফোন এবং PC একই band-এ কানেক্ট করো
- রাউটারের DHCP লিজ দেখো
- অথবা router-এ "AP Isolation" বন্ধ করো

---

## 🔄 Auto-Wake Daemon Issues

### ❌ Issue 7.1 — `auto-wake.sh start` fails: `socat: command not found`

**সমাধান:**
```bash
sudo dnf install socat
```

---

### ❌ Issue 7.2 — Daemon চালু কিন্তু কানেক্ট হচ্ছে না

**কারণ:** socat listener bind করতে পারেনি।

**সমাধান:**
```bash
# ডেমন status
./scripts/auto-wake.sh status

# PID ফাইল চেক
ls -la ~/SmVnc/.run/

# ম্যানুয়ালি ফরগ্রাউন্ডে চালাও
./scripts/auto-wake.sh start
# এরর দেখো

# লিসেনিং পোর্ট চেক
ss -tuln | grep 5901
```

---

### ❌ Issue 7.3 — Container চালু হতে ৩০ সেকেন্ডের বেশি লাগছে

**সমাধান:** `wait_for_vnc()` ফাংশনে `max_wait` বাড়াও:

```bash
# auto-wake.sh-এ
local max_wait=60    # 30 থেকে 60 করো
```

---

### ❌ Issue 7.4 — পুরনো PID আটকে আছে

**Error Message:**
```bash
[~] Auto-wake daemon already running (pid 12345)
# কিন্তু আসলে চলছে না
```

**সমাধান:**
```bash
# Stale PID ফাইল ডিলিট
rm -f ~/SmVnc/.run/*.pid

# আবার চালু করো
./scripts/auto-wake.sh start
```

---

## 😴 Idle Monitor Issues

### ❌ Issue 8.1 — কন্টেইনার হঠাৎ বন্ধ হয়ে যাচ্ছে

**কারণ:** Idle timeout কম।

**সমাধান:**
```bash
# ডিফল্ট ৬০০ সেকেন্ড → ১৮০০ সেকেন্ড (৩০ মিনিট)
SMVNC_IDLE_TIMEOUT=1800 ./scripts/idle-monitor.sh start

# অথবা idle-monitor.sh-এ:
IDLE_TIMEOUT="${SMVNC_IDLE_TIMEOUT:-1800}"
```

---

### ❌ Issue 8.2 — Idle monitor কন্টেইনার বন্ধ করছে না

**কারণ:** কানেকশন ডিটেক্ট ভুল করছে।

**সমাধান:**
```bash
# ম্যানুয়াল চেক
./scripts/idle-monitor.sh check

# আউটপুট দেখো — connections কত দেখাচ্ছে

# ss -tn দিয়ে ম্যানুয়ালি চেক
ss -tn | grep 15901    # internal port
```

**সমস্যা হলে `PORT_OFFSET` চেক করো** (ডিফল্ট 10000):

```bash
grep PORT_OFFSET ~/SmVnc/scripts/idle-monitor.sh
```

---

### ❌ Issue 8.3 — Log ফাইল খুব বড় হয়ে যাচ্ছে

**সমাধান:**
```bash
# Log rotate manual
mv ~/SmVnc/logs/idle-monitor.log ~/SmVnc/logs/idle-monitor.log.old
touch ~/SmVnc/logs/idle-monitor.log

# পুরনো ফাইল ডিলিট
find ~/SmVnc/logs -name "*.log.*" -mtime +7 -delete
```

**স্থায়ীভাবে:** `LOG_ROTATE_DAYS=3` করে দাও।

---

## ⚡ Performance Issues

### ❌ Issue 9.1 — RAM শেষ হয়ে যাচ্ছে

**কারণ:** অনেক কন্টেইনার একসাথে চলছে।

**সমাধান:**

**১. কন্টেইনার লিমিট কমাও:**
```bash
# SmVnc.sh-এ
--memory="1g" --cpus="0.5"   # 1.5g থেকে 1g
```

**২. একসাথে কম কন্টেইনার চালাও:**
```bash
./SmVnc.sh
# [4] Stop Specific Port → অপ্রয়োজনীয় বন্ধ করো
```

**৩. Idle monitor ব্যবহার করো:**
```bash
SMVNC_IDLE_TIMEOUT=300 ./scripts/idle-monitor.sh start
```

**৪. সিস্টেম RAM চেক:**
```bash
free -h
# Total used কত দেখো
```

---

### ❌ Issue 9.2 — CPU 100% এ চলছে

**কারণ:** Firefox বা ভারী অ্যাপ।

**সমাধান:**
```bash
# Podman stats
podman stats --no-stream

# কন্টেইনারে ঢুকে htop চালাও
podman exec -it smvnc-sazid htop

# ভারী প্রসেস বন্ধ করো
podman exec -it smvnc-sazid pkill firefox
```

---

### ❌ Issue 9.3 — Disk ভরে যাচ্ছে

**সমাধান:**
```bash
# Container size দেখো
podman ps -a --size

# পুরনো ইমেজ ডিলিট
podman image prune -a

# Data folder size
du -sh ~/SmVnc/data/*
du -sh ~/SmVnc/data/*/*

# বড় ফাইল খুঁজে বের করো
find ~/SmVnc/data -size +100M -type f
```

---

## 💾 Data / Persistence Issues

### ❌ Issue 10.1 — Data সেভ হচ্ছে না, restart-এ সব মুছে যাচ্ছে

**কারণ:** Volume mount ভুল।

**সমাধান:**

কন্টেইনার inspect করো:
```bash
podman inspect smvnc-sazid | grep -A 5 "Mounts"
```

Expected:
```json
"Source": "/home/user/SmVnc/data/sazid",
"Destination": "/headless/Desktop",
"Type": "bind"
```

Source ঠিক না থাকলে কন্টেইনার ডিলিট করে আবার start করো।

---

### ❌ Issue 10.2 — `Permission denied` data ফোল্ডারে

**কারণ:** কন্টেইনার headless ইউজার হোস্টের ফাইল লিখতে পারছে না।

**সমাধান:**
```bash
# Ownership চেক
ls -la ~/SmVnc/data/sazid

# Ownership ঠিক করো
chown -R $USER:$USER ~/SmVnc/data/sazid
chmod -R u+rwX ~/SmVnc/data/sazid
```

Rootless Podman হলে সাধারণত সমস্যা হয় না।

---

### ❌ Issue 10.3 — Data Folder git-এ পুশ হয়ে গেছে

**সমাধান:**
```bash
# Git থেকে untrack করো
git rm -r --cached data/
git rm --cached config/users.conf

# Commit
git commit -m "Remove user data from tracking"
git push
```

`.gitignore`-এ নিচের লাইন আছে কি না চেক:
```bash
cat .gitignore | grep data
# Expected: data/*
```

---

## 🎨 Dashboard / UI Issues

### ❌ Issue 11.1 — ব্যানার রঙিন দেখাচ্ছে না

**কারণ:** টার্মিনাল True Color সাপোর্ট করছে না।

**সমাধান:**

**১. টার্মিনাল চেক:**
```bash
echo $TERM
# Expected: xterm-256color
```

না হলে:
```bash
export TERM=xterm-256color
```

**২. `.bashrc`-এ যোগ করো:**
```bash
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

**৩. টার্মিনাল বদলাও:** GNOME Terminal / Tilix / Alacritty

---

### ❌ Issue 11.2 — বাংলা টেক্সট ভাঙা দেখাচ্ছে

**কারণ:** ফন্ট সাপোর্ট নেই।

**সমাধান:**
```bash
# Noto fonts ইনস্টল
sudo dnf install google-noto-sans-bengali-fonts
# অথবা
sudo apt install fonts-noto-bengali
```

**টার্মিনাল ফন্ট চেঞ্জ করো:** Preferences → Font → **"Noto Sans Mono"**

---

### ❌ Issue 11.3 — ড্যাশবোর্ডের বক্স ভাঙা

**কারণ:** ফন্টে box-drawing characters নেই।

**সমাধান:**
```bash
sudo dnf install terminus-fonts-console
# অথবা
sudo dnf install powerline-fonts
```

---

## 📦 Git / GitHub Issues

### ❌ Issue 12.1 — `git push` reject

**Error:**
```bash
! [rejected] main -> main (fetch first)
```

**সমাধান:**
```bash
git pull --rebase origin main
# conflict হলে ঠিক করো
git push origin main
```

---

### ❌ Issue 12.2 — বড় ফাইল push হবে না

**Error:**
```bash
remote: error: File X is 105 MB; this exceeds GitHub's file size limit
```

**সমাধান:**
```bash
# কোন ফাইল বড় সেটা দেখো
find . -type f -size +50M

# Git থেকে সরাও
git rm --cached path/to/big/file
echo "path/to/big/file" >> .gitignore
git commit -m "Remove large file"
git push
```

---

## 🐞 Debug Mode & Log Collection

### 📋 Bug Report করার সময় এই তথ্য দাও

**১. System Info:**
```bash
uname -a > /tmp/smvnc-debug.txt
cat /etc/os-release >> /tmp/smvnc-debug.txt
echo "" >> /tmp/smvnc-debug.txt
```

**২. Dependencies:**
```bash
for cmd in podman socat qrencode; do
    echo "$cmd: $(command -v $cmd || echo 'NOT FOUND')" >> /tmp/smvnc-debug.txt
done
```

**৩. Podman Containers:**
```bash
podman ps -a --filter name=smvnc- >> /tmp/smvnc-debug.txt
```

**৪. Logs:**
```bash
echo "=== SmVnc.log ===" >> /tmp/smvnc-debug.txt
tail -50 ~/SmVnc/logs/SmVnc.log >> /tmp/smvnc-debug.txt

echo "=== idle-monitor.log ===" >> /tmp/smvnc-debug.txt
tail -30 ~/SmVnc/logs/idle-monitor.log >> /tmp/smvnc-debug.txt

echo "=== auto-wake.log ===" >> /tmp/smvnc-debug.txt
tail -30 ~/SmVnc/logs/auto-wake.log >> /tmp/smvnc-debug.txt
```

**৫. Container Logs:**
```bash
echo "=== container logs ===" >> /tmp/smvnc-debug.txt
for c in $(podman ps -a --format '{{.Names}}' | grep smvnc-); do
    echo "--- $c ---" >> /tmp/smvnc-debug.txt
    podman logs --tail 20 "$c" >> /tmp/smvnc-debug.txt 2>&1
done
```

**৬. Debug file:**
```bash
cat /tmp/smvnc-debug.txt
```

এই ফাইলটি Telegram-এ পাঠাও: [@SmMehmudTg18](https://t.me/SmMehmudTg18)

---

## 🆘 Emergency Recovery

### 💥 সবকিছু ভেঙে গেছে? এই কমান্ডগুলো চালাও

**ধাপ ১: সব কন্টেইনার বন্ধ**
```bash
podman stop $(podman ps -q -f name=smvnc-) 2>/dev/null
podman rm -f $(podman ps -aq -f name=smvnc-) 2>/dev/null
```

**ধাপ ২: সব লিসেনার ও ডেমন বন্ধ**
```bash
./scripts/auto-wake.sh stop 2>/dev/null
./scripts/idle-monitor.sh stop 2>/dev/null
pkill -f "socat.*smvnc" 2>/dev/null
```

**ধাপ ৩: PID ফাইল পরিষ্কার**
```bash
rm -rf ~/SmVnc/.run/*
```

**ধাপ ৪: ইমেজ রিসেট**
```bash
podman rmi smvnc-modern:latest 2>/dev/null
```

**ধাপ ৫: পুরনো ফাইল পরিষ্কার**
```bash
# ⚠️ সাবধান! এটা সব ডাটা মুছে ফেলবে
# Backup নাও আগে:
tar -czf ~/smvnc-backup-$(date +%s).tar.gz ~/SmVnc/data ~/SmVnc/config
```

**ধাপ ৬: আবার সেটআপ**
```bash
cd ~/SmVnc
./setup.sh
./SmVnc.sh
```

---

## 📞 Help & Support

**উপরের কিছুতে সমাধান হয়নি?** যোগাযোগ করো:

| Channel | Link |
| :--- | :--- |
| 🐛 **GitHub Issues** | https://github.com/MehmudHub/SmVnc/issues |
| 💬 **Telegram** | https://t.me/SmMehmudTg18 |
| 📧 **Email** | smmehmudgm18@gmail.com |

**Rিপোর্ট করার সময় অবশ্যই দাও:**
- ✅ Debug file (`/tmp/smvnc-debug.txt`)
- ✅ What you tried (কী কী চেষ্টা করেছো)
- ✅ Expected vs Actual behavior
- ✅ Screenshot (সম্ভব হলে)

---

<div align="center">

**SmVnc — Troubleshooting Guide**

Made with ❤️ by [Sazid Mehmud](https://t.me/SmMehmudTg18)

⭐ [Star the repo](https://github.com/MehmudHub/SmVnc) if this helped!

</div>
