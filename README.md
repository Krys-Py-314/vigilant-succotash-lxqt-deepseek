# Minimal LXQt Environment for Raspberry Pi 5

This repository contains a shell script that transforms a headless Raspberry Pi OS Lite 64-bit installation (based on **Debian Trixie**) into a lightweight desktop environment with LXQt and Openbox, focusing on **minimal memory usage** while providing essential GUI and development tools.

![Raspberry Pi 5](https://img.shields.io/badge/Raspberry%20Pi-5-red) ![OS](https://img.shields.io/badge/OS-Raspberry%20Pi%20OS%20Lite%2064--bit-green) ![Debian](https://img.shields.io/badge/Debian-Trixie-purple) ![License](https://img.shields.io/badge/License-MIT-blue)

## Overview

The script installs a carefully selected set of packages and configurations to create a fast, low‑memory desktop environment. It is intended for users who need a graphical interface for development or lightweight tasks on the Raspberry Pi 5 without the overhead of a full desktop distribution.

## Features

- **Window Manager**: Openbox with square window decorations (no rounded corners) – ultra‑lightweight.
- **Desktop Environment**: Minimal LXQt components (panel, session, runner, notification daemon, power management, etc.).
- **Lightweight Applications**:
  - Terminal: `sakura`
  - Text editor: `l3afpad` (lightweight fork of Leafpad; the original is not in the Trixie repos)
  - Web browser: `links2` (graphical mode, text‑oriented)
  - File manager: `pcmanfm-qt`
  - Image viewer: `feh`
  - PDF viewer: `mupdf`
  - Video player: `mpv`
  - Screen recorder: `recordmydesktop` (command‑line only; no GUI frontend to save memory)
- **Development Tools**:
  - GCC, G++, Make, pkg-config
  - GPIO libraries for C: `libgpiod-dev`, `pigpio`
  - Git, Curl, Wget
- **System Utilities**:
  - `dropbear` SSH server (replaces `openssh-server` for lower memory)
  - `fastfetch` system information
- **Pi‑Apps Integration**:
  - Installs Pi‑Apps from the official script.
  - Installs “Min” and “Geany Dark Mode” via Pi‑Apps.
- **Shell Enhancements**:
  - Oh My Posh prompt for Bash.
  - Ubuntu Nerd Font (regular) installed and applied system‑wide at size 11.
- **Visual Customization**:
  - No wallpaper; solid desktop background colour `#383C48` (R:56, G:60, B:72).
  - Numix‑Circle icon theme applied system‑wide.
- **X11 Configuration**:
  - Correct Xorg configuration for the Raspberry Pi 5’s VC4 driver.
- **Auto‑start**: GUI starts automatically on tty1 after login (optional).

## Prerequisites

- Raspberry Pi 5 board.
- Raspberry Pi OS Lite (64‑bit) based on **Debian Trixie** (latest as of 2025).
- A normal user account with `sudo` privileges.
- Stable internet connection.

## Installation

1. **Download the script** (or clone this repository):

   ```bash
   wget https://raw.githubusercontent.com/yourusername/yourrepo/main/install-minimal-lxqt-rpi5.sh