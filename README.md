- Checks for updates on every startup
- Shows changelog and prompts to update
- Simple `git pull` integration

---

## 📦 Module Architecture

```
Scripts Opt/
├── Optimize-Windows.ps1      # Main entry point
├── Run-Optimizer.bat         # Quick launcher (Run as Admin)
├── README.md
│
├── NeuralModules/
│   ├── NeuralAI.psm1         # Q-Learning engine + 27 tweaks
│   ├── Neural-Dashboard.ps1  # Real-time AI visualization
│   ├── AI-Recommendations.ps1# Smart recommendations
│   ├── ML-Usage-Patterns.ps1 # Usage pattern analysis
│   ├── Update-Checker.ps1    # Git update system
│   ├── Lenovo-Optimization.ps1# Lenovo-specific features
│   │
│   ├── Boot-Optimization.ps1
│   ├── Debloat-Suite.ps1
│   ├── Disk-Hygiene.ps1
│   ├── Gaming-Optimization.ps1
│   ├── Advanced-Registry.ps1
│   └── ... (more modules)
│
├── Backups/                  # Registry backups
└── NeuralBrain.json          # AI learning history
```

---

## 🚀 Quick Start

### Installation

```powershell
# Clone the repository
git clone https://github.com/LiliumFra/Scripts-Opt.git
cd "Scripts-Opt"

# Run as Administrator
.\Run-Optimizer.bat
```

### Or manually

```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Optimize-Windows.ps1
```

---

## 📖 Module Usage Guide

### 🧠 Neural AI (`NeuralAI.psm1`)

The core AI engine implements Q-Learning to learn optimal tweaks for your system.

```powershell
# Import the module
Import-Module .\NeuralModules\NeuralAI.psm1

# Run a learning cycle
$hw = Get-HardwareProfile  # From Smart-Optimizer
Invoke-NeuralLearning -ProfileName "Gaming Session" -Hardware $hw -Workload "Gaming"

# Get AI recommendation
$recommendation = Get-NeuralRecommendation -Hardware $hw -Workload "General"
```

**Key Functions:**

| Function | Description |
|----------|-------------|
| `Invoke-NeuralLearning` | Main learning cycle - measures, applies tweak, evaluates |
| `Get-NeuralRecommendation` | Gets best tweak based on Q-Table |
| `Measure-SystemMetrics` | Collects DPC, Interrupt, Context Switch, Ping, Temp |
| `Get-QTable` | Returns current Q-Learning table |
| `Get-BestTweaksForState` | Lists top N tweaks for current state |

---

### 📊 Neural Dashboard (`Neural-Dashboard.ps1`)

Interactive visualization of AI learning state.

```powershell
.\NeuralModules\Neural-Dashboard.ps1
```

**Features:**

- Live system score with metrics
- Q-Learning statistics (cycles, epsilon, states)
- Q-Table insights (best/worst actions)
- ASCII trend graph of historical scores
- Time-based predictions

---

### 🔮 AI Recommendations (`AI-Recommendations.ps1`)

Smart recommendation engine with regression detection.

```powershell
.\NeuralModules\AI-Recommendations.ps1
```

**New in v6.1:**

- **Q-Learning Recommendations** - Based on learned Q-values
- **Regression Detection** - Alerts if performance is declining
- **Correlation Analysis** - Identifies which tweaks historically improved scores

---

### 🖥️ Lenovo Optimization (`Lenovo-Optimization.ps1`)

For Lenovo laptops (ThinkPad, IdeaPad, Legion, Yoga).

```powershell
.\NeuralModules\Lenovo-Optimization.ps1
```

**Features:**

- Auto-detects Lenovo systems
- Controls thermal profiles via WMI:
  - `MaximizePerformance` - Full power, higher temps
  - `Balanced` - Default mode
  - `Cool` - Quiet, lower performance
- Battery conservation mode
- View all BIOS settings

---

### 🔄 Update Checker (`Update-Checker.ps1`)

Checks for updates on startup.

```powershell
# Manual check
. .\NeuralModules\Update-Checker.ps1
$updates = Test-UpdatesAvailable
if ($updates.UpdatesAvailable) {
    Show-UpdateNotification -UpdateInfo $updates
}
```

---

## 🎮 Gaming Optimization Tweaks

The AI can explore and learn from these gaming-focused tweaks:

| Category | Tweak | Description |
|----------|-------|-------------|
| Latency | Timer Resolution | Forces 0.5ms timer |
| Latency | Disable HPET | Uses faster TSC |
| Latency | TSC Sync Policy | Enhanced synchronization |
| Gaming | Fullscreen Optimizations | Classic fullscreen mode |
| Gaming | Disable Game Bar | Removes overlay overhead |
| Gaming | Disable Game DVR | No background recording |
| Network | Disable Nagle | No packet buffering |
| Network | TCP ACK Frequency | Immediate ACKs |
| Scheduler | System Responsiveness | Prioritize foreground |
| Scheduler | Disable Core Parking | All cores active |

---

## ⚠️ Risk Levels

All tweaks are categorized by risk:

| Risk | Description | Auto-Apply |
|------|-------------|------------|
| **Low** | Safe, easily reversible | ✅ Yes |
| **Medium** | May affect some apps | ⚠️ With confirmation |
| **High** | Significant system changes | ❌ Manual only |

---

## 🔧 Troubleshooting

### Module won't import

```powershell
# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Lenovo features not working

- Ensure Lenovo Vantage is installed
- Check if WMI interface is available:

```powershell
Get-CimInstance -Namespace root\wmi -ClassName Lenovo_BiosSetting
```

### Q-Learning not learning

- Run more learning cycles (minimum 10 for patterns)
- Check `NeuralBrain.json` for history
- Reset with Dashboard option 6

---

## 🏆 Credits

- **Lead Developer**: Jose Bustamante
- **Architecture**: Neural AI with Q-Learning
- **Research Sources**: Win11Debloat, Perfect-Windows-11, facet4windows
- **License**: MIT
- **Philosophy**: *"Intelligent Performance, Zero Compromise"*

---

## 📜 Changelog

### v6.1 ULTRA (2026-01-14)

- ✅ Q-Learning AI engine with persistent learning
- ✅ Expanded tweak library (27 tweaks)
- ✅ Neural Dashboard for AI visualization
- ✅ Lenovo-specific optimizations via WMI
- ✅ Auto-update checker
- ✅ Regression detection in recommendations
- ✅ Tweak correlation analysis

### v6.0 ULTRA

- AI Recommendations engine
- ML Usage Pattern analysis
- Bilingual support (EN/ES)
- Safety & backup systems

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

```bash
git checkout -b feature/my-feature
git commit -m "Add my feature"
git push origin feature/my-feature
```
