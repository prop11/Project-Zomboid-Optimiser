PROJECT ZOMBOID - MULTI-CPU & MEMORY (JVM) OPTIMIZER (BUILD 42 & 41)
===============================================================================

This package contains optimized Java Virtual Machine (JVM) configurations 
for Project Zomboid Build 42 and Build 41.

WHAT THESE SETTINGS DO:
-----------------------
1. Increases RAM limit from 3GB to 8GB / 6GB to prevent Out-Of-Memory stutters with mods.
2. Enables NUMA architecture optimization (-XX:+UseNUMA) for AMD Ryzen & Intel multi-core CPUs.
3. Pre-touches heap memory pages (-XX:+AlwaysPreTouch) to eliminate runtime OS page faults.
4. Activates low-latency ZGC / G1GC for smooth sub-millisecond memory cleanup.

HOW TO INSTALL (EASY 1-MINUTE SETUP):
-------------------------------------
In Project Zomboid (Build 42 & 41), the game launcher reads its JVM configuration directly 
from "ProjectZomboid64.json" in the game directory (Steam Launch Options are passed as game 
arguments, not JVM heap).

METHOD 1: Copy Pre-Built File (Recommended)
1. Open Steam -> Library -> Right-click "Project Zomboid" -> Manage -> Browse Local Files.
2. (Optional) Rename your current "ProjectZomboid64.json" to "ProjectZomboid64.json.bak" as a backup.
3. Copy "ProjectZomboid64_8GB.json" (or 6GB / 4GB) from this folder into your game folder.
4. Rename it to "ProjectZomboid64.json" and launch the game!

METHOD 2: Edit ProjectZomboid64.json in Notepad
1. Open "ProjectZomboid64.json" in your game folder with Notepad.
2. Change "-Xmx3072m" to "-Xmx8192m" (or 6144m).
3. Add "-XX:+UseNUMA" and "-XX:+AlwaysPreTouch" to the vmArgs list.
4. Save and launch!
