<div align="center">

# 🖥️ SmVnc

### A Modern Multi-User VNC Desktop Manager for Linux

*Run a beautiful XFCE desktop environment for multiple users, controlled from a single CLI dashboard — powered by Podman.*

[![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Podman](https://img.shields.io/badge/Podman-Container-892CA0.svg)](https://podman.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fedora](https://img.shields.io/badge/Fedora-Ready-51A2DA.svg)](https://getfedora.org/)

</div>

---

## 📖 About

**SmVnc** is an open-source CLI tool that lets you spin up **isolated, modern XFCE desktop environments** inside Podman containers — each on its own port, each with its own private data folder. Perfect for:

- 🧑‍💻 Testing Linux desktop apps from your phone
- 👨‍👩‍👧 Multiple users sharing one machine without mixing data
- 📱 Accessing a full Linux desktop from any VNC client (Android / iOS / PC)
- 🧪 Learning Linux in a safe sandboxed environment

No complex setup. No GUI bloat. Just a clean terminal dashboard that gets the job done.

---

## ✨ Features

- 🎨 **Modern XFCE Desktop** — Arc-Dark theme, Papirus icons, Plank dock
- 👥 **Multi-User Support** — Each user gets their own port, container, and data folder
- 🚀 **Single CLI Dashboard** — No need to remember `podman` commands
- 🔒 **Isolated Data** — Each user's files stay in `SmVnc/data/<username>/`
- 📱 **QR Code Sharing** — Generate QR codes for quick VNC connection from your phone
- 🧹 **Auto Cleanup** — Stop and remove containers with a single keypress
- 📊 **Live Status** — See which users are online and which ports are active
- 📝 **Activity Logs** — Every action is logged in `SmVnc/logs/SmVnc.log`
- 🌐 **VPN-Aware IP Detection** — Automatically skips tun/tap/wg interfaces
- 🔥 **Firewall Auto-Config** — Opens required ports in firewalld automatically

---

## 📸 Preview

```
  ╔══════════════════════════════════════════════════════╗
  ║        VNC MANAGER - CONTROL DASHBOARD               ║
  ╠══════════════════════════════════════════════════════╣
  ║   [1] View Active Ports                              ║
  ║   [2] View All Users                                 ║
  ║   [3] Start User Container                           ║
  ║   [4] Stop Specific Port                             ║
  ║   [5] Stop All Services                              ║
  ║   [6] Add New User                                   ║
  ║   [7] Remove User                                    ║
  ║   [8] View Logs                                      ║
  ║   [9] About Developer                                ║
  ║   [0] Exit                                           ║
  ╚══════════════════════════════════════════════════════╝
```

---

## 🧰 Requirements

| Requirement | Why |
| :--- | :--- |
| **Linux** (Fedora / Ubuntu / Arch) | Host OS |
| **Podman** | Container engine |
| **socat** | Port forwarding (for auto-wake feature) |
| **qrencode** | QR code generation for VNC address |
| **VNC Client** (on phone/PC) | RealVNC / bVNC / TigerVNC / VNC Viewer |

> ⚠️ **Windows users:** Use WSL2 with a Linux distro, or run it inside a Fedora VM.

---

## 🚀 Installation

### ১. ক্লোন করো

```bash
git clone https://github.com/MehmudHub/SmVnc.git
cd SmVnc
```

### ২. সেটআপ স্ক্রিপ্ট চালাও (একবারই)

```bash
chmod +x setup.sh SmVnc.sh
./setup.sh
```

`setup.sh` নিজে থেকেই নিচের কাজগুলো করবে:
- ✅ Podman, socat, qrencode ইনস্টল
- ✅ কাস্টম XFCE Docker image বিল্ড
- ✅ প্রয়োজনীয় ফোল্ডার তৈরি (`data/`, `logs/`, `config/`)
- ✅ `/usr/local/bin/SmVnc` সিমলিংক তৈরি (যাতে যেকোনো জায়গা থেকে `SmVnc` কমান্ড চলে)

### ৩. চালাও

```bash
./SmVnc.sh
```

অথবা যেকোনো ডিরেক্টরি থেকে:

```bash
SmVnc
```

---

## 📘 Usage

স্ক্রিপ্ট চালু হলে একটি ড্যাশবোর্ড আসবে:

| Key | Action |
| :---: | :--- |
| `1` | View Active Ports — কে অনলাইনে আছে দেখো |
| `2` | View All Users — সব রেজিস্টার্ড ইউজারদের লিস্ট |
| `3` | Start User Container — নির্দিষ্ট ইউজারের কন্টেইনার চালু |
| `4` | Stop Specific Port — নির্দিষ্ট পোর্ট বন্ধ করো (confirm সহ) |
| `5` | Stop All Services — সব কন্টেইনার বন্ধ করো |
| `6` | Add New User — নতুন ইউজার যোগ করো (auto port assign) |
| `7` | Remove User — ইউজার ও ডাটা সরিয়ে ফেলো |
| `8` | View Logs — শেষ ২০টি অ্যাক্টিভিটি দেখো |
| `9` | About Developer — ডেভেলপারের তথ্য |
| `0` | Exit |

---

## 📱 Connecting from Your Phone

১. কন্টেইনার চালু করার পর ড্যাশবোর্ডে address দেখাবে, যেমন:
```
VNC Address : 192.168.1.5:5901
Password    : headless
```

২. ফোনে **VNC Viewer** (RealVNC) বা **bVNC** ইনস্টল করো।

৩. নতুন কানেকশন যোগ করো:
- **Address:** `192.168.1.5:5901` (তোমার নিজের IP বসাও)
- **Port:** `5901`
- **Password:** `headless`

৪. Connect চাপো — মডার্ন XFCE ডেস্কটপ চলে আসবে! 🎉

---

## 🗂️ Data Storage — Where Do Files Go?

**প্রতিটি ইউজারের ডাটা আলাদা রাখা হয়।**

```text
SmVnc/
├── data/
│   ├── sazid/          ← sazid-এর ডেস্কটপ
│   ├── rahim/          ← rahim-এর ডেস্কটপ
│   └── karim/          ← karim-এর ডেস্কটপ
├── logs/
│   └── SmVnc.log       ← সব অ্যাক্টিভিটি
└── config/
    └── users.conf      ← ইউজার ও পোর্ট ম্যাপিং
```

🔒 **`data/`, `logs/`, এবং `config/users.conf` কখনো GitHub-এ পুশ হবে না** — `.gitignore` এগুলো ব্লক করে রেখেছে। তোমার ফাইল তোমার পিসিতেই থাকবে।

---

## 🛠️ Troubleshooting

### ❓ "Permission denied" এরর
```bash
chmod +x setup.sh SmVnc.sh scripts/*.sh
```

### ❓ Podman কন্টেইনার চালু হচ্ছে না
```bash
podman ps -a
podman logs vnc-<username>
```

### ❓ ফোন থেকে কানেক্ট করা যাচ্ছে না
- একই WiFi-তে আছো কিনা চেক করো
- VPN বন্ধ করো (স্ক্রিপ্ট নিজেই VPN IP বাদ দেয়, কিন্তু ফোনেও VPN থাকলে সমস্যা হবে)
- Firewall চেক করো:
```bash
sudo firewall-cmd --list-ports
```

### ❓ পোর্ট already in use
```bash
sudo ss -tuln | grep 5901
```
এরপর যে প্রসেসটা পোর্ট দখল করে আছে বন্ধ করো, অথবা অন্য পোর্ট ব্যবহার করো।

### ❓ QR কোড আসছে না
```bash
sudo dnf install qrencode
```

---

## 🧑‍💻 About the Developer

<div align="center">

|  |  |
| :--- | :--- |
| **Name** | Sazid Mehmud |
| **Age** | 18 |
| **Location** | Atulia, Kalaroa, Satkhira, Bangladesh 🇧🇩 |
| **Hobby** | Termux Tools & Script Development |
| **Telegram** | [@SmMehmudTg18](https://t.me/SmMehmudTg18) |
| **Email** | [smmehmudgm18@gmail.com](mailto:smmehmudgm18@gmail.com) |
| **GitHub** | [@MehmudHub](https://github.com/MehmudHub) |

*"Made with ❤️ from Bangladesh — for the open-source community."*

</div>

---

## 🤝 Contributing

Pull requests are welcome! If you find a bug or have a feature idea:

১. Fork করো
২. নতুন ব্রাঞ্চ বানাও (`git checkout -b feature/amazing-feature`)
৩. Commit করো (`git commit -m "Add amazing feature"`)
৪. Push করো (`git push origin feature/amazing-feature`)
৫. Pull Request খোলো

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## ⭐ Show Your Support

যদি **SmVnc** তোমার কাজে আসে, তাহলে রেপোতে একটা ⭐ **Star** দাও। এটা ডেভেলপারকে আরও ফিচার যোগ করতে উৎসাহ দেয়! 🚀

---

<div align="center">

**SmVnc** • Made with 🐧 by [Sazid Mehmud](https://t.me/SmMehmudTg18)

</div>
