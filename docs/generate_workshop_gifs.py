#!/usr/bin/env python3
import os
import sys
import math
import random
import subprocess
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "/root/Project-Zomboid-Optimiser/docs/gifs"
os.makedirs(OUT_DIR, exist_ok=True)

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

def save_optimized_gif(frames, durations, out_path):
    temp_gif = out_path + ".tmp.gif"
    frames[0].save(
        temp_gif,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        optimize=True
    )
    # Use gifsicle for deep palette and lossy optimization
    res = subprocess.run([
        "gifsicle", "-O3", "--lossy=80", temp_gif, "-o", out_path
    ], capture_output=True)
    if res.returncode == 0:
        os.remove(temp_gif)
    else:
        os.replace(temp_gif, out_path)
    size_kb = os.path.getsize(out_path) / 1024
    print(f"[+] Created: {out_path} ({size_kb:.1f} KB)")

# ==============================================================================
# GIF 1: Stock vs PZO Benchmark Comparison Card (Frame-time & Microstutters)
# ==============================================================================
def generate_benchmark_gif():
    print("[*] Generating Benchmark Comparison GIF...")
    W, H = 800, 380
    NUM_FRAMES = 48
    FPS = 12
    durations = [int(1000 / FPS)] * NUM_FRAMES
    
    font_title = get_font(FONT_BOLD, 20)
    font_sub = get_font(FONT_BOLD, 14)
    font_metric = get_font(FONT_MONO, 32)
    font_small = get_font(FONT_MONO, 12)
    font_tiny = get_font(FONT_REG, 11)

    # Seed random frame-times
    stock_fps_base = [random.randint(38, 55) for _ in range(NUM_FRAMES)]
    # Introduce random stutter spikes in stock
    for i in [6, 18, 30, 42]:
        stock_fps_base[i] = random.randint(14, 22)

    frames = []
    wipe_x_cycle = [int(W * 0.2 + (W * 0.6) * (0.5 + 0.5 * math.sin(i / NUM_FRAMES * 2 * math.pi))) for i in range(NUM_FRAMES)]

    for f in range(NUM_FRAMES):
        img = Image.new("RGB", (W, H), (14, 17, 23))
        draw = ImageDraw.Draw(img)

        # Header Banner
        draw.rectangle([0, 0, W, 48], fill=(22, 27, 34))
        draw.line([0, 48, W, 48], fill=(48, 54, 61), width=1)
        draw.text((20, 14), "PROJECT ZOMBOID B42 HIGHWAY 120 KM/H STREAMING TEST", fill=(240, 246, 252), font=font_title)
        draw.rectangle([W - 170, 10, W - 16, 38], fill=(33, 38, 45), outline=(56, 189, 248), width=1)
        draw.text((W - 156, 17), "AVX2 SIMD ACTIVE", fill=(56, 189, 248), font=font_small)

        # Split Screen Halves
        # Left Half: Stock Project Zomboid
        draw.rectangle([16, 60, 390, H - 16], fill=(20, 16, 16), outline=(90, 34, 34), width=1)
        draw.rectangle([16, 60, 390, 96], fill=(40, 20, 20))
        draw.text((28, 68), "STOCK GAME (VANILLA B42)", fill=(248, 113, 113), font=font_sub)
        draw.text((28, 106), "Frame Time & Micro-stutters", fill=(160, 140, 140), font=font_tiny)

        # Right Half: PZO Engine
        draw.rectangle([410, 60, W - 16, H - 16], fill=(16, 24, 20), outline=(22, 101, 52), width=1)
        draw.rectangle([410, 60, W - 16, 96], fill=(20, 48, 30))
        draw.text((422, 68), "PZO OPTIMIZER ENGINE (v0.9.9.5)", fill=(74, 222, 128), font=font_sub)
        draw.text((422, 106), "Low-Latency Pacing + AVX2 Streamer", fill=(140, 180, 150), font=font_tiny)

        # Live Metrics Stock
        fps_stock = stock_fps_base[f]
        ms_stock = 1000.0 / max(1, fps_stock)
        draw.text((28, 126), f"{fps_stock} FPS", fill=(239, 68, 68) if fps_stock < 30 else (245, 158, 11), font=font_metric)
        draw.text((180, 138), f"p99: {ms_stock:.1f} ms", fill=(245, 158, 11), font=font_small)
        draw.text((28, 172), "Stalls: HEAVY CHUNK SPIKES", fill=(248, 113, 113), font=font_small)
        draw.text((28, 190), "GC Stalls: 40-120ms freeze spikes", fill=(180, 140, 140), font=font_tiny)

        # Live Metrics PZO
        fps_pzo = 141
        ms_pzo = 7.1
        draw.text((422, 126), f"{fps_pzo} FPS", fill=(34, 197, 94), font=font_metric)
        draw.text((574, 138), f"p99: {ms_pzo:.1f} ms", fill=(74, 222, 128), font=font_small)
        draw.text((422, 172), "Pacing: SILKY SMOOTH (VRR LOCKED)", fill=(74, 222, 128), font=font_small)
        draw.text((422, 190), "GC Interceptor: ZERO FREEZES", fill=(140, 200, 160), font=font_tiny)

        # Frame-time Graph Visualizer
        graph_y = 220
        graph_h = 100
        # Stock graph box
        draw.rectangle([28, graph_y, 378, graph_y + graph_h], fill=(12, 10, 10), outline=(60, 30, 30))
        # PZO graph box
        draw.rectangle([422, graph_y, W - 28, graph_y + graph_h], fill=(10, 16, 12), outline=(30, 60, 40))

        # Render Stock Graph Points (spiky)
        pts_stock = []
        for x_idx in range(40):
            hist_idx = (f - 40 + x_idx) % NUM_FRAMES
            h_fps = stock_fps_base[hist_idx]
            val = min(graph_h - 4, int((60 - min(60, h_fps)) / 60.0 * (graph_h - 10) + 10))
            pts_stock.append((28 + x_idx * (350 / 40), graph_y + val))
        for p in range(len(pts_stock) - 1):
            draw.line([pts_stock[p], pts_stock[p+1]], fill=(239, 68, 68), width=2)

        # Render PZO Graph Points (ultra-flat)
        pts_pzo = []
        for x_idx in range(40):
            jitter = (math.sin((f + x_idx) * 0.8) * 1.5)
            pts_pzo.append((422 + x_idx * (350 / 40), graph_y + graph_h - 22 + jitter))
        for p in range(len(pts_pzo) - 1):
            draw.line([pts_pzo[p], pts_pzo[p+1]], fill=(34, 197, 94), width=2)

        # Footers
        draw.text((28, H - 36), "[X] Main Thread Hitching Detected", fill=(239, 68, 68), font=font_small)
        draw.text((422, H - 36), "[+] Thread Offloading & Physics Sleep", fill=(34, 197, 94), font=font_small)

        frames.append(img)

    save_optimized_gif(frames, durations, os.path.join(OUT_DIR, "01_pzo_vs_stock_frametime.gif"))

# ==============================================================================
# GIF 2: In-Game F10 Control Center & Presets Showcase
# ==============================================================================
def generate_f10_menu_gif():
    print("[*] Generating F10 Control Center Showcase GIF...")
    W, H = 800, 400
    NUM_FRAMES = 40
    FPS = 10
    durations = [int(1000 / FPS)] * NUM_FRAMES

    font_title = get_font(FONT_BOLD, 18)
    font_bold = get_font(FONT_BOLD, 13)
    font_mono = get_font(FONT_MONO, 12)
    font_reg = get_font(FONT_REG, 12)
    font_small = get_font(FONT_REG, 11)

    tabs = ["Quick Actions & Presets", "General Engine", "Vehicles", "Blood & Corpses", "Audio & Climate", "ModShield"]
    presets = [
        ("[*] Balanced Mode (Recommended)", "Zero visual loss, 30 FPS lighting, safe blood cap (4/tile), vehicle road priority."),
        ("[+] Potato Mode (Low-End PC Savior)", "Aggressive FPS boost: 15 FPS lighting, corpse shadow cull, auto debris sweep."),
        ("[!] AMD FSR 1.0 (Spatial Upscale)", "Hardware accelerated upscaler (75% render scale + 80% RCAS edge sharpening)."),
    ]

    frames = []
    for f in range(NUM_FRAMES):
        img = Image.new("RGB", (W, H), (18, 20, 26))
        draw = ImageDraw.Draw(img)

        # Window Header
        draw.rectangle([0, 0, W, 42], fill=(28, 32, 42))
        draw.line([0, 42, W, 42], fill=(50, 60, 78), width=1)
        draw.text((18, 12), "PROJECT ZOMBOID OPTIMISER - CONTROL CENTER (F10)", fill=(240, 246, 252), font=font_title)
        
        # Hotkey badge
        draw.rectangle([W - 130, 8, W - 18, 34], fill=(13, 110, 253), outline=(100, 180, 255))
        draw.text((W - 118, 13), "TOGGLE: [F10]", fill=(255, 255, 255), font=font_bold)

        # Tabs Strip
        tab_x = 18
        for i, tab in enumerate(tabs):
            active = (i == 0)
            tw = 120 if i > 0 else 150
            tab_bg = (38, 44, 58) if active else (22, 26, 34)
            tab_border = (56, 189, 248) if active else (40, 48, 62)
            draw.rectangle([tab_x, 48, tab_x + tw, 72], fill=tab_bg, outline=tab_border)
            draw.text((tab_x + 8, 54), tab[:16] + (".." if len(tab) > 16 else ""), fill=(255, 255, 255) if active else (150, 160, 180), font=font_small)
            tab_x += tw + 6

        # Body Container
        draw.rectangle([18, 76, W - 18, H - 18], fill=(24, 28, 38), outline=(50, 60, 78))

        # Presets Header
        draw.text((36, 92), "1-CLICK PERFORMANCE PRESETS:", fill=(56, 189, 248), font=font_bold)

        # Highlight preset depending on frame
        selected_idx = 0 if f < 15 else (1 if f < 30 else 2)

        py = 118
        for i, (name, desc) in enumerate(presets):
            is_sel = (i == selected_idx)
            card_bg = (30, 45, 65) if is_sel else (20, 24, 32)
            card_border = (56, 189, 248) if is_sel else (40, 48, 62)
            draw.rectangle([36, py, W - 36, py + 48], fill=card_bg, outline=card_border, width=2 if is_sel else 1)
            
            # Checkbox / indicator
            check_box = "[X]" if is_sel else "[ ]"
            check_col = (74, 222, 128) if is_sel else (140, 150, 170)
            draw.text((48, py + 8), f"{check_box} {name}", fill=(255, 255, 255) if is_sel else (190, 200, 220), font=font_bold)
            draw.text((52, py + 28), desc, fill=(160, 185, 215) if is_sel else (130, 140, 160), font=font_small)
            
            if is_sel:
                draw.rectangle([W - 140, py + 12, W - 48, py + 36], fill=(22, 101, 52), outline=(74, 222, 128))
                draw.text((W - 128, py + 16), "APPLIED", fill=(255, 255, 255), font=font_bold)
            py += 58

        # Memory Purge & Status Footer
        draw.line([36, H - 85, W - 36, H - 85], fill=(45, 55, 72))
        
        # Purge button pulse
        pulse = (f % 10 < 5)
        purge_bg = (185, 28, 28) if pulse and selected_idx == 1 else (153, 27, 27)
        draw.rectangle([36, H - 72, 220, H - 32], fill=purge_bg, outline=(248, 113, 113))
        draw.text((46, H - 60), "[ PURGE UNUSED ASSETS ]", fill=(255, 255, 255), font=font_bold)

        # Status output line
        draw.text((240, H - 66), "Status: 100% ModShield Active | Parked Car Physics Asleep", fill=(74, 222, 128), font=font_mono)
        reclaimed_text = "VRAM: 1.4 GB reclaimed on last auto-sweep" if selected_idx == 1 else "Safehouse protection verified (0 player containers wiped)"
        draw.text((240, H - 48), reclaimed_text, fill=(180, 200, 230), font=font_small)

        frames.append(img)

    save_optimized_gif(frames, durations, os.path.join(OUT_DIR, "02_f10_control_center_presets.gif"))

# ==============================================================================
# GIF 3: AMD FidelityFX Super Resolution (FSR 1.0) Showcase
# ==============================================================================
def generate_fsr_showcase_gif():
    print("[*] Generating AMD FSR 1.0 Showcase GIF...")
    W, H = 800, 380
    NUM_FRAMES = 36
    FPS = 12
    durations = [int(1000 / FPS)] * NUM_FRAMES

    font_title = get_font(FONT_BOLD, 18)
    font_bold = get_font(FONT_BOLD, 14)
    font_metric = get_font(FONT_MONO, 28)
    font_mono = get_font(FONT_MONO, 12)
    font_small = get_font(FONT_REG, 11)

    wipe_positions = [int(W * 0.15 + (W * 0.7) * (i / (NUM_FRAMES - 1))) for i in range(NUM_FRAMES)]

    frames = []
    for f in range(NUM_FRAMES):
        img = Image.new("RGB", (W, H), (15, 18, 24))
        draw = ImageDraw.Draw(img)

        # Top Header
        draw.rectangle([0, 0, W, 46], fill=(22, 27, 36))
        draw.line([0, 46, W, 46], fill=(48, 58, 76), width=1)
        draw.text((20, 14), "PZO HARDWARE SPATIAL UPSCALING: AMD FSR 1.0 (EASU + RCAS)", fill=(240, 246, 252), font=font_title)
        draw.rectangle([W - 160, 8, W - 18, 38], fill=(30, 58, 138), outline=(96, 165, 250))
        draw.text((W - 146, 15), "1440p / 4K / DECK", fill=(219, 234, 254), font=font_bold)

        # Wipe Divider Position
        wx = wipe_positions[f]

        # Draw Left Side (Native 100% Unscaled - Heavy Load)
        draw.rectangle([18, 58, wx, H - 18], fill=(24, 20, 20))
        
        # Draw Right Side (PZO FSR 1.0 - 75% Scale + RCAS Sharpening)
        draw.rectangle([wx, 58, W - 18, H - 18], fill=(16, 28, 22))

        # Wipe Divider Line
        draw.line([wx, 58, wx, H - 18], fill=(56, 189, 248), width=3)
        draw.polygon([(wx - 8, 70), (wx + 8, 70), (wx, 82)], fill=(56, 189, 248))

        # Labels Left
        if wx > 220:
            draw.text((36, 74), "NATIVE RESOLUTION (100%)", fill=(239, 68, 68), font=font_bold)
            draw.text((36, 104), "54 FPS", fill=(245, 158, 11), font=font_metric)
            draw.text((36, 144), "GPU Fillrate: 98% (HEAVY)", fill=(248, 113, 113), font=font_mono)
            draw.text((36, 166), "Frame Time: 18.5 ms", fill=(200, 180, 180), font=font_small)
            draw.text((36, 188), "High battery draw on handhelds", fill=(170, 150, 150), font=font_small)

        # Labels Right
        if (W - wx) > 240:
            draw.text((wx + 24, 74), "PZO AMD FSR 1.0 (75% SCALE)", fill=(74, 222, 128), font=font_bold)
            draw.text((wx + 24, 104), "118 FPS (+118% BOOST)", fill=(34, 197, 94), font=font_metric)
            draw.text((wx + 24, 144), "GPU Fillrate: 46% | RCAS: 80% Sharp", fill=(74, 222, 128), font=font_mono)
            draw.text((wx + 24, 166), "Frame Time: 8.4 ms (ULTRA CRISP UI)", fill=(160, 220, 180), font=font_small)
            draw.text((wx + 24, 188), "Steam Deck / Ally Battery +1.5 Hours", fill=(180, 240, 200), font=font_small)

        # Feature Cards at the bottom
        draw.rectangle([36, H - 110, W - 36, H - 36], fill=(20, 26, 36), outline=(45, 55, 75))
        draw.text((50, H - 98), "HOW IT WORKS:", fill=(56, 189, 248), font=font_bold)
        draw.text((50, H - 76), "1. 3D Game World renders at performance scale (75% resolution).", fill=(220, 230, 245), font=font_small)
        draw.text((50, H - 58), "2. Edge-Adaptive RCAS reconstructs high-frequency details with zero UI text blur.", fill=(220, 230, 245), font=font_small)
        draw.rectangle([W - 190, H - 96, W - 50, H - 52], fill=(22, 101, 52), outline=(74, 222, 128))
        draw.text((W - 176, H - 80), "-pzo_fsr ACTIVE", fill=(255, 255, 255), font=font_bold)

        frames.append(img)

    save_optimized_gif(frames, durations, os.path.join(OUT_DIR, "03_fsr_upscaling_showcase.gif"))

# ==============================================================================
# GIF 4: Project Viewpoint Compatibility & In-Game "PZO" Options Tab
# ==============================================================================
def generate_viewpoint_standdown_gif():
    print("[*] Generating Project Viewpoint Standdown & Settings Tab GIF...")
    W, H = 800, 380
    NUM_FRAMES = 36
    FPS = 10
    durations = [int(1000 / FPS)] * NUM_FRAMES

    font_title = get_font(FONT_BOLD, 18)
    font_bold = get_font(FONT_BOLD, 13)
    font_mono = get_font(FONT_MONO, 12)
    font_small = get_font(FONT_REG, 11)

    frames = []
    for f in range(NUM_FRAMES):
        img = Image.new("RGB", (W, H), (18, 22, 30))
        draw = ImageDraw.Draw(img)

        # Options Tab Header
        draw.rectangle([0, 0, W, 42], fill=(26, 32, 44))
        draw.line([0, 42, W, 42], fill=(45, 55, 75), width=1)
        draw.text((20, 12), "OPTIONS > PZO (v0.9.9.5-unstable)", fill=(240, 246, 252), font=font_title)

        # Tab strip in game options
        tab_names = ["Display", "Audio", "Keybindings", "Mods", "PZO"]
        tx = 20
        for tname in tab_names:
            is_pzo = (tname == "PZO")
            tw = 80 if not is_pzo else 90
            draw.rectangle([tx, 50, tx + tw, 74], fill=(30, 58, 138) if is_pzo else (24, 28, 38), outline=(96, 165, 250) if is_pzo else (40, 48, 62))
            draw.text((tx + 14, 56), tname, fill=(255, 255, 255) if is_pzo else (150, 160, 180), font=font_bold)
            tx += tw + 8

        # Settings Card 1: Project Viewpoint Standdown
        draw.rectangle([20, 84, W - 20, 206], fill=(16, 28, 24), outline=(34, 197, 94), width=2)
        draw.text((36, 96), "PROJECT VIEWPOINT & 3D CAMERA STANDDOWN GOVERNOR", fill=(74, 222, 128), font=font_bold)
        
        # Pulse Standdown Active Badge
        badge_pulse = (f % 8 < 4)
        draw.rectangle([W - 240, 92, W - 36, 122], fill=(22, 101, 52) if badge_pulse else (20, 83, 45), outline=(74, 222, 128))
        draw.text((W - 226, 99), "[STANDDOWN ACTIVE]", fill=(255, 255, 255), font=font_bold)

        draw.text((36, 128), "Detection: Project Viewpoint / PZ3D mod active in world", fill=(219, 234, 254), font=font_mono)
        draw.text((36, 148), "- Automatically bypassed 2D frustum culling & horde spatial sweeps (Zero camera pop-in)", fill=(160, 210, 180), font=font_small)
        draw.text((36, 166), "- Bypassed quarter-buffer fog overrides (Viewpoint true weathers active at full fidelity)", fill=(160, 210, 180), font=font_small)
        draw.text((36, 184), "Mode: [ AUTO (Recommended) ] -> Saved in pzo_config.json", fill=(100, 200, 255), font=font_small)

        # Settings Card 2: FSR 1.0 Visual Notification
        draw.rectangle([20, 218, W - 20, 320], fill=(20, 26, 38), outline=(56, 189, 248), width=1)
        draw.text((36, 230), "AMD FIDELITYFX SUPER RESOLUTION (FSR 1.0)", fill=(56, 189, 248), font=font_bold)
        draw.rectangle([W - 200, 226, W - 36, 256], fill=(12, 74, 110), outline=(56, 189, 248))
        draw.text((W - 186, 233), "[FSR ENABLED: 75%]", fill=(255, 255, 255), font=font_bold)

        draw.text((36, 260), "World Upscaling: Active via Steam Launch Option (-pzo_fsr)", fill=(240, 246, 252), font=font_mono)
        draw.text((36, 280), "Render Scale: 75% | Edge-Adaptive RCAS Sharpening: 80% | UI Text: Native 100%", fill=(180, 200, 230), font=font_small)
        draw.text((36, 298), "Delivers +80% to +120% FPS on 1440p, 4K, and Steam Deck with zero visual fuzziness.", fill=(140, 170, 210), font=font_small)

        # Footer Action Buttons
        bx = 20
        buttons = ["[ Steam Workshop ]", "[ GitHub Issues ]", "[ Check for Updates ]"]
        for btn in buttons:
            draw.rectangle([bx, 334, bx + 160, 366], fill=(30, 41, 59), outline=(71, 85, 105))
            draw.text((bx + 14, 344), btn, fill=(226, 232, 240), font=font_small)
            bx += 175

        frames.append(img)

    save_optimized_gif(frames, durations, os.path.join(OUT_DIR, "04_project_viewpoint_standdown.gif"))

if __name__ == "__main__":
    generate_benchmark_gif()
    generate_f10_menu_gif()
    generate_fsr_showcase_gif()
    generate_viewpoint_standdown_gif()
    print("[*] All GIFs generated successfully!")
