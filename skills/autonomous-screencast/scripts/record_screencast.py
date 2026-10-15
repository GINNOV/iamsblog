#!/usr/bin/env python3
"""
Playwright Synchronized Browser Recorder for Autonomous Screencasts.
Executes DOM actions with smooth cursor movements, visual ripples, and timeline synchronization.

Usage:
    python3 record_screencast.py --script screencasts/work/VB-001_script_timed.json --work-dir screencasts/work/
"""

import argparse
import asyncio
import json
import os
import sys
import time

try:
    from playwright.async_api import async_playwright
except ImportError:
    print("[!] Playwright is required. Install with: pip install playwright && playwright install chromium")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CURSOR_OVERLAY_PATH = os.path.join(SCRIPT_DIR, "cursor_overlay.js")

async def record_screencast(script_file: str, work_dir: str, headless: bool = True):
    with open(script_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    video_code = data.get("video_code", "screencast")
    start_url = data.get("start_url", "https://viscardibomboniere.com")
    scenes = data.get("scenes", [])
    pre_setup = data.get("pre_recording_setup_actions", [])

    os.makedirs(work_dir, exist_ok=True)

    # Read cursor overlay JS
    with open(CURSOR_OVERLAY_PATH, "r", encoding="utf-8") as f:
        cursor_js = f.read()

    print(f"[*] Launching Playwright recorder for [{video_code}]...")
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=headless,
            args=[
                "--start-maximized",
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox"
            ]
        )

        # Check for persistent authenticated session state
        auth_state_path = os.path.join(work_dir, "auth.json")
        context_kwargs = {
            "viewport": {"width": 1920, "height": 1080},
            "device_scale_factor": 1,
            "locale": "it-IT",
            "record_video_dir": work_dir,
            "record_video_size": {"width": 1920, "height": 1080}
        }
        if os.path.exists(auth_state_path):
            print(f"[✓] Loading verified authenticated session state from: {auth_state_path}")
            context_kwargs["storage_state"] = auth_state_path

        context = await browser.new_context(**context_kwargs)

        # Inject cursor script on every page and frame
        await context.add_init_script(cursor_js)

        page = await context.new_page()
        page_recording = page.video

        # Initial navigation
        print(f"[*] Navigating to {start_url}...")
        await page.goto(start_url, wait_until="domcontentloaded")
        await page.wait_for_timeout(1000)

        # Execute pre-recording setup off-camera
        print("[*] Executing pre-recording setup...")
        # Auto-dismiss common Italian cookie banners if present
        try:
            cookie_btn = page.locator("button:has-text('Accetta'), button:has-text('Accetto'), button:has-text('Accetta tutti'), #cookie-accept, .cc-accept").first
            if await cookie_btn.is_visible(timeout=2000):
                await cookie_btn.click()
                print("  -> Dismissed cookie consent banner.")
        except Exception:
            pass

        # Execute custom pre-setup actions if specified
        for act in pre_setup:
            act_type = act.get("type")
            selector = act.get("selector")
            if act_type == "click" and selector:
                await page.locator(selector).first.click()
            elif act_type == "navigate" and act.get("url"):
                await page.goto(act["url"], wait_until="domcontentloaded")
            await page.wait_for_timeout(500)

        # Mark t_zero (time when actual tutorial begins)
        rec_start_time = time.time()
        print(f"[✓] Pre-recording complete. Marking t_zero at {rec_start_time:.3f}")

        # Execute Scenes in sequence
        for scene in scenes:
            scene_id = scene.get("scene_id")
            narration = scene.get("narration_it", "")
            actions = scene.get("browser_actions", [])
            lead_in_ms = scene.get("lead_in_ms", 300)
            audio_duration_ms = scene.get("audio_duration_ms", 3000)
            lead_out_ms = scene.get("lead_out_ms", 600)
            scene_target_duration_ms = lead_in_ms + audio_duration_ms + lead_out_ms

            print(f"[*] Scene {scene_id}: Executing actions (allocated: {scene_target_duration_ms}ms)...")
            scene_start = time.time()

            # Lead in pause
            if lead_in_ms > 0:
                await page.wait_for_timeout(lead_in_ms)

            # Perform actions
            for act in actions:
                act_type = act.get("type", "hover")
                selector = act.get("selector")
                x = act.get("x")
                y = act.get("y")

                if selector:
                    loc = page.locator(selector).first
                    await loc.wait_for(state="visible", timeout=10000)
                    box = await loc.bounding_box()
                    if box:
                        x = box["x"] + box["width"] / 2
                        y = box["y"] + box["height"] / 2

                if x is not None and y is not None:
                    # Smooth trajectory (35 steps ~ 700ms)
                    await page.mouse.move(x, y, steps=35)
                    await page.wait_for_timeout(250)

                if act_type == "click":
                    await page.mouse.down()
                    await page.wait_for_timeout(100)
                    await page.mouse.up()
                elif act_type == "type":
                    text_to_type = act.get("text", "")
                    await page.keyboard.type(text_to_type, delay=80)
                elif act_type == "scroll":
                    delta_y = act.get("delta_y", 300)
                    await page.mouse.wheel(0, delta_y)

                await page.wait_for_timeout(act.get("wait_after_ms", 200))

            # Hold until the end of the scene duration to stay synced with voiceover
            elapsed_ms = (time.time() - scene_start) * 1000.0
            remaining_ms = scene_target_duration_ms - elapsed_ms
            if remaining_ms > 0:
                await page.wait_for_timeout(remaining_ms)

        # Finished all scenes
        rec_end_time = time.time()
        print(f"[✓] Finished scene execution. Closing browser context...")
        await page.close()
        await context.close()
        await browser.close()

        # Rename raw video to standard name
        raw_video_path = await page_recording.path()
        standard_raw_path = os.path.join(work_dir, f"{video_code}_raw_video.webm")
        if os.path.exists(raw_video_path):
            os.replace(raw_video_path, standard_raw_path)
            print(f"[✓] Raw video saved to: {standard_raw_path}")

        # Save timing metadata for ffmpeg trimming
        timing_meta = {
            "video_code": video_code,
            "raw_video": standard_raw_path,
            "t_zero_seconds": 1.0,  # approximate baseline or calibrated
            "total_recorded_seconds": rec_end_time - rec_start_time
        }
        meta_file = os.path.join(work_dir, f"{video_code}_timing_meta.json")
        with open(meta_file, "w", encoding="utf-8") as f:
            json.dump(timing_meta, f, indent=2)

        return standard_raw_path

def main():
    parser = argparse.ArgumentParser(description="Synchronized Browser Recorder")
    parser.add_argument("--script", required=True, help="Path to [VIDEO_CODE]_script_timed.json")
    parser.add_argument("--work-dir", default="screencasts/work", help="Working directory for captures")
    parser.add_argument("--headless", action="store_true", default=True, help="Run headless")
    parser.add_argument("--headed", dest="headless", action="store_false", help="Run headed (visible browser)")

    args = parser.parse_args()
    asyncio.run(record_screencast(args.script, args.work_dir, headless=args.headless))

if __name__ == "__main__":
    main()
