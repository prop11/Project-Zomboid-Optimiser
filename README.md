# Project Zomboid Optimiser (PZO)

Official repository for the **Project Zomboid Optimiser (PZO)** Steam Workshop Lua mod, supporting both **Build 42** and **Build 41**.

---

## ⚡ Overview

Project Zomboid Optimiser (PZO) is an advanced in-game optimization and diagnostics suite designed to eliminate micro-stutters, manage high memory consumption, streamline high-speed vehicle driving, and gracefully handle massive horde combat.

### Key Capabilities:
* **Anti-Stutter Vehicle Road Streaming**: Dynamic chunk loading priority, parked vehicle physics sleep, auto-zoom clamping, and roadside entity throttles.
* **Smart Memory & GC Management**: Intelligent idle garbage collection cycles during sleep/reading with zero combat interruptions.
* **Corpse, Blood & Debris Management**: Safe floor decal capping (4 splats/tile), scheduled empty corpse sweeps preserving 100% of loot, and ground clutter purging (spent casings, broken glass, tins, twigs).
* **Audio Concurrency Limits**: Stops FMOD crackling and CPU stalls by capping overlapping groans, footsteps, and animal sounds.
* **Zero-pcall Hardened Architecture**: Fully hardened against Kahlua VM exception interception and red error counter triggers.
* **Comprehensive Multi-Language Support**: Fully translated across 8 languages: English (EN), Spanish (ES), French (FR), German (DE), Russian (RU), Simplified Chinese (CN), and Traditional Chinese (TC/CH).

---

## 📁 Repository Structure

```text
├── Contents/
│   └── mods/
│       └── MPOptimiser/
│           ├── 42/             # Project Zomboid Build 42 implementation
│           │   ├── media/
│           │   │   ├── lua/
│           │   │   │   ├── client/
│           │   │   │   └── shared/
│           │   │   └── ui/
│           │   ├── mod.info
│           │   └── poster.png
│           ├── media/          # Project Zomboid Build 41 implementation
│           │   ├── lua/
│           │   │   ├── client/
│           │   │   └── shared/
│           │   └── ui/
│           ├── mod.info
│           └── poster.png
├── preview.png                 # Steam Workshop preview image
├── workshop.txt                # Workshop metadata & upload configuration
└── .gitignore
```

---

## 🌐 Localization & Translations

Translations follow Project Zomboid Build 42 and Build 41 standards:
* `UI.json` / `UI_<LANG>.txt`: UI labels and settings
* `ContextMenu.json` / `ContextMenu_<LANG>.txt`: Right-click contextual world options
* `Tooltip.json`: Detailed descriptions and tooltips
