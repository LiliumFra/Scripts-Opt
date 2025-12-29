# 🚀 Windows Neural Optimizer v3.5

> **Advanced System Optimization & Debloating Suite for Windows 10/11**  
> *Developed by **Josef** | Powered by Neural Modules*

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## 🌟 Overview

**Windows Neural Optimizer** is a modular, high-performance PowerShell suite designed to reduce system latency, optimize network settings, and improve gaming performance. Unlike generic "debloaters," this tool uses **hardware-aware logic** (NeuralUtils) to adapt tweaks specifically to your CPU, RAM, and SSD.

## ✨ Key Features

### 🧠 Deep Hardware Tuning

- **Smart RAM Management**: Automatically enables `LargeSystemCache` only on systems with 16GB+ RAM.
- **CPU Intelligence**: Disables Power Throttling on Intel CPUs and adjusts `Win32PrioritySeparation` for maximum responsiveness.
- **SSD/HDD Awareness**: Applies filesystem optimizations based on your drive type.

### ⚡ Gaming & Network

- **Smart DNS Benchmark**: Tests latency to Google, Cloudflare, and OpenDNS to find the fastest server for YOUR connection.
- **Nagle's Algorithm Disable**: Reduces packet delay (TCP NoDelay) specifically on your active network adapter.
- **GPU Optimization**: Detects NVIDIA/AMD/Intel GPUs and applies specific registry tweaks.

### 🛡️ Safety First

- **Auto-Restore Points**: Automatically creates a System Restore Point before making changes.
- **Safe Debloat**: Removes bloatware with safety checks to prevent breaking essential features.

### 💾 NeuralCache (Bonus)

- Includes `NeuralCache-Diagnostic.ps1`, a self-optimizing file scanner that caches results for instant access, perfect for managing large game libraries.

## 📦 Modules

| Module | Description |
| :--- | :--- |
| `Optimize-Windows.ps1` | **Main Controller**. Run this file to start the menu. |
| `NeuralUtils.psm1` | Shared brain. Handles logging, safety, and hardware detection. |
| `Boot-Optimization.ps1` | BCD tweaks, NTFS optimization, and startup cleanup. |
| `Debloat-Suite.ps1` | Removes pre-installed apps and telemetry. |
| `Disk-Hygiene.ps1` | Deep cleaning of temp files and update caches. |
| `Gaming-Optimization.ps1` | Latency reduction, GPU tweaks, and DNS benchmarking. |

## 🚀 How to Use

1. **Download** the repository.
2. Double-click **`Run-Optimizer.bat`**.
   - *This will automatically ask for Admin permissions and launch the menu.*
3. Select an option from the menu:
   - `[1-4]`: Run individual modules.
   - `[5]`: **Run ALL (Reccomended)**.

### For NeuralCache

- Double-click **`Run-NeuralCache.bat`**.
- It will automatically detecting your Steam library or ask you to drag a folder.

## ⚠️ Disclaimer

This software makes changes to the Windows Registry and System Services.  
**ALWAYS create a backup** (the script tries to do this for you, but extra caution is good).  
*The authors are not responsible for any instability or data loss.*

## 🏆 Credits

- **Concept & Architecture**: Josef
- **Core Optimization Logic**: Josef
- **Additional Credits**: Jose Bustamante
