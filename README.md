# 🚀 **iSHARE — Local Network File Transfer System**

> **iSHARE** is a lightweight **Bash-based file transfer system** designed for **fast local network sharing** between devices using a direct TCP connection.

It utilizes a powerful UNIX pipeline composed of:

```
tar → pv → nc
```

This architecture allows **efficient packaging, real-time transfer monitoring, and direct socket streaming**.

📡 **Transport Protocol:** TCP
🔌 **Port:** `9999`
⚡ **Transfer Type:** Local Network (LAN / Wi-Fi)

---

# 📦 **Dependencies**

The scripts rely on several core utilities to process the data stream.

| Tool               | Purpose                                                      |
| ------------------ | ------------------------------------------------------------ |
| 📁 **tar**         | Recursively bundles files into a single stream for transport |
| 📊 **pv**          | Displays real-time transfer progress and throughput          |
| 🌐 **nc (Netcat)** | Establishes the TCP socket connection                        |

Together they create the pipeline:

```
tar → pv → nc
```

Which behaves as:

```
Package → Monitor → Transmit
```

---

# 🖥️ **PC Setup (Linux Mint / Debian Based)**

> ℹ️ **Note:** The scripts use the `-N` flag which requires **netcat-openbsd** or a compatible implementation.

Install the required packages:

```bash
sudo apt update && sudo apt install pv netcat-openbsd tar -y
```

✔ Updates package repository
✔ Installs required network and monitoring tools

---

# 📱 **Android Setup**

The `ishare_phone.sh` script relies on:

* Android filesystem paths (`/sdcard`)
* Android system utilities (`getprop`)
* Standard Linux binaries

Therefore it must run inside a **terminal emulator**.

Recommended:

> 📦 **Termux**

Install dependencies inside the terminal emulator:

```bash
pkg update && pkg install pv netcat-openbsd tar -y
```

---

## 🔓 Storage Permission (Important)

Android restricts filesystem access by default.

To allow access to **internal storage and SD cards**, run:

```bash
termux-setup-storage
```

This grants access to:

```
/sdcard
/storage
/storage/<UUID>
```

Without this step, file browsing will fail.

---

# ⚙️ **Installation**

Before executing the scripts, grant **executable permissions**.

```bash
chmod +x ishare.sh ishare_phone.sh
```

This enables direct execution from the terminal.

---

# ▶️ **Usage**

Run the appropriate script depending on the device.

### 🖥️ PC

```bash
./ishare.sh
```

### 📱 Android

```bash
./ishare_phone.sh
```

---

# 🧭 **Navigation & Selection Mechanics**

The file browser inside **iSHARE** operates with a simple command system.

| Command     | Function                                    |
| ----------- | ------------------------------------------- |
| `number`    | Enter a directory or toggle a file          |
| `s<number>` | Toggle directory selection without entering |
| `0`         | Navigate to the parent directory            |
| `D` or `d`  | Finalize file selections                    |

Example:

```
5        → Enter item 5
s3       → Select directory 3
0        → Go back
D        → Start transfer
```

---

# 🔄 **Transfer Workflow**

Follow this sequence to perform a successful transfer.

---

## 1️⃣ Start Receiver

On the **destination device**, run:

```
RECEIVE FILES
```

The script will display:

```
STATUS: LISTENING
IP ADDR: 192.168.X.X
PORT: 9999
```

The receiver is now waiting for incoming data.

---

## 2️⃣ Start Sender

On the **source device**:

```
SEND FILES
```

Then:

1. Select files or directories
2. Finalize selection (`D`)
3. Enter the **receiver IP address**

Example:

```
[*] Receiver IP: 192.168.1.45
```

---

## 3️⃣ Transfer Begins

The pipeline activates:

```
tar → pv → nc
```

You will see a real-time progress display:

```
SENDING: 45% | 23MB/s | ETA 00:12
```

---

# 💾 **External Storage Access (Android)**

Android requires **manual authentication of external SD cards**.

When selecting **External Storage**, you must provide the **Volume UUID**.

Example format:

```
DA47-D4F0
```

Which corresponds to the path:

```
/storage/DA47-D4F0
```

Example prompt:

```
[*] Enter SD Card UUID: DA47-D4F0
```

---

## 🔎 Example External Storage Paths

Different devices may have different identifiers:

```
/storage/DA47-D4F0
/storage/1234-ABCD
/storage/9C33-6F12
```

Each **SD card generates a unique UUID**.

---

# 🧠 **Design Philosophy**

iSHARE follows a **UNIX pipeline architecture**:

```
FILES
  │
  ▼
tar  →  pv  →  nc
  │       │      │
  │       │      └── Network Transmission
  │       └──────── Transfer Monitoring
  └──────────────── File Packaging
```

Benefits:

✔ Minimal dependencies
✔ Extremely fast transfers
✔ Works across Linux and Android
✔ No cloud services required
✔ Fully offline operation

---

# ⚡ **Key Features**

🔥 Direct device-to-device transfers
📡 Works on any local network
📊 Real-time progress monitoring
📁 Recursive directory transfers
📱 Android + Linux support
⚙️ Zero configuration required

---

# 🧾 **Author**

```
CREATED BY
NOCTIS NOBUNGA
