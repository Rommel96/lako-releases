# Lako Configuration Platform — Official Installers & Releases

This repository provides official pre-compiled standalone releases and 1-line automated installers for the **Lako Configuration Platform**.

The Lako Configuration Platform provides a cross-platform, declarative configuration management engine and agent-first local loopback UI for Claude Code, OpenCode, Codex, Antigravity (Agy), and Kiro.

---

## ⚡ 1-Line Quick Install (No git clone, no gh CLI, zero dependencies)

`lako` is distributed as an optimized, standalone compiled binary (under 10 MB, with the embedded React 19 SPA control center). It does NOT require Git, Go, Node.js, or the GitHub CLI (`gh`).

### 🪟 Windows (PowerShell)
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/Rommel96/lako-releases/main/install.ps1 | iex
```
> **What does this installer do on Windows?**
> 1. **Direct Download:** Downloads the pre-built native package (`lako-v1.0.0-windows-amd64.zip`) directly from GitHub Releases without requiring tokens or authentication.
> 2. **Clean Installation:** Extracts and installs into `%LOCALAPPDATA%\Programs\Lako`.
> 3. **Adds to User PATH:** Automatically adds `lako` to your User `PATH` environment variable so you can run `lako doctor` or `lako ui` from PowerShell, CMD, or Windows Terminal.
> 4. **Optional Production Mode:** Prompts to register a background task (`LakoConfigurationServer`) that starts Lako automatically on login/boot and keeps it running quietly in the background at `http://127.0.0.1:25256/`.
> 5. **1-Click Launcher:** Includes `start.bat` and `start.ps1` in the install directory to launch the UI with a double click.

To install non-interactively with Production Mode service enabled:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Rommel96/lako-releases/main/install.ps1))) -RegisterService
```

### 🍎 macOS & 🐧 Linux (Terminal)
Open your terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/Rommel96/lako-releases/main/install.sh | bash
```
> Downloads the native binary for your architecture (Apple Silicon M-series, Intel x64, or Linux), installs to `~/.local/bin/lako` (or `$INSTALL_DIR`), and validates the installation immediately.

---

## 📦 Direct Manual Downloads (GitHub Releases)

If you prefer downloading pre-packaged archives directly:

| Platform | Architecture | Direct Download Link | Format |
|---|---|---|---|
| **Windows** | x64 (Intel / AMD) | [lako-v1.0.0-windows-amd64.zip](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-windows-amd64.zip) | ZIP (includes `lako.exe`, `start.bat`, `install-service.ps1`) |
| **Windows** | ARM64 | [lako-v1.0.0-windows-arm64.zip](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-windows-arm64.zip) | ZIP |
| **macOS** | Apple Silicon (M1/M2/M3/M4) | [lako-v1.0.0-darwin-arm64.tar.gz](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-darwin-arm64.tar.gz) | TAR.GZ |
| **macOS** | Intel x64 | [lako-v1.0.0-darwin-amd64.tar.gz](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-darwin-amd64.tar.gz) | TAR.GZ |
| **Linux** | x64 (amd64) | [lako-v1.0.0-linux-amd64.tar.gz](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-linux-amd64.tar.gz) | TAR.GZ |
| **Linux** | ARM64 | [lako-v1.0.0-linux-arm64.tar.gz](https://github.com/Rommel96/lako-releases/releases/latest/download/lako-v1.0.0-linux-arm64.tar.gz) | TAR.GZ |

All SHA-256 checksums are published in [checksums.sha256](https://github.com/Rommel96/lako-releases/releases/latest/download/checksums.sha256).

---

## 🚀 Quick Start Commands

Once installed, use `lako` from any terminal:

```bash
# Check version
lako version

# Diagnose installed CLI runtimes (Claude Code, OpenCode, Codex, Antigravity, Kiro)
lako doctor

# Launch the local web UI control center (default port: 25256)
lako ui

# Or specify custom port
lako ui --port 25256
```

Then navigate to `http://127.0.0.1:25256/` to manage agents, skills, and usage telemetry.
