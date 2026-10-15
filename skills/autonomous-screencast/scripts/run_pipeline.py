#!/usr/bin/env python3
"""
Master Orchestrator for Autonomous Screencast Generation.
Executes the full end-to-end pipeline (Phases 1-6) or generates a self-contained execution package.

Supports:
  - Both Edge-TTS (free, default) and ElevenLabs (via API key)
  - Headless and headed recording
  - Single feature, batch queue, and auto-discovery
  - --generate-only flag to build the script package without running browser/ffmpeg

Usage:
    python3 run_pipeline.py --config task_queue.json
    python3 run_pipeline.py --video-code VB-001_ricerca-e-filtri --url https://viscardibomboniere.com
    python3 run_pipeline.py --config task_queue.json --generate-only
"""

import argparse
import asyncio
import json
import os
import subprocess
import sys
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CURSOR_OVERLAY_PATH = os.path.join(SCRIPT_DIR, "cursor_overlay.js")

def run_command(cmd, desc="Running step"):
    print(f"[*] {desc}: {' '.join(cmd)}")
    res = subprocess.run(cmd, check=True)
    return res

async def execute_feature_pipeline(feature_cfg: dict, base_url: str, work_dir: str, final_dir: str,
                                   voice: str = "it-IT-IsabellaNeural", tts_engine: str = "edge-tts",
                                   browser_engine: str = "ego-lite",
                                   elevenlabs_key: str = None, headless: bool = True, generate_only: bool = False):
    video_code = feature_cfg.get("video_code", "screencast")
    feature_name = feature_cfg.get("feature_name", "Tutorial")
    start_url = feature_cfg.get("start_url", base_url)
    pre_setup = feature_cfg.get("pre_recording_setup", "")
    must_demo = feature_cfg.get("must_demonstrate", [])
    out_of_scope = feature_cfg.get("out_of_scope", "")

    os.makedirs(work_dir, exist_ok=True)
    os.makedirs(final_dir, exist_ok=True)

    print(f"\n{'='*70}")
    print(f"STARTING PIPELINE: [{video_code}] - {feature_name} (Browser: {browser_engine})")
    print(f"{'='*70}")

    # Phase 2: Action-Audio Script Matrix Generation
    script_matrix_path = os.path.join(work_dir, f"{video_code}_script.json")
    if not os.path.exists(script_matrix_path):
        print(f"[*] Generating Action-Audio Script Matrix for [{video_code}]...")
        scenes = []
        scene_idx = 1
        for demo_item in must_demo:
            scenes.append({
                "scene_id": scene_idx,
                "narration_it": f"Ora vediamo come {demo_item.lower()}.",
                "lead_in_ms": 300,
                "lead_out_ms": 600,
                "browser_actions": [
                    {
                        "type": "hover",
                        "selector": "body",
                        "wait_after_ms": 300
                    }
                ]
            })
            scene_idx += 1

        script_data = {
            "video_code": video_code,
            "feature_name": feature_name,
            "start_url": start_url,
            "pre_recording_setup": pre_setup,
            "out_of_scope": out_of_scope,
            "scenes": scenes
        }
        with open(script_matrix_path, "w", encoding="utf-8") as f:
            json.dump(script_data, f, indent=2, ensure_ascii=False)
        print(f"[✓] Script matrix saved to: {script_matrix_path}")

    if generate_only:
        print(f"[✓] Package generated for [{video_code}]. Skipping live browser/ffmpeg execution (--generate-only).")
        return

    # Phase 3: TTS Synthesis & Timing
    synth_script = os.path.join(SCRIPT_DIR, "synthesize_tts.py")
    synth_cmd = [
        sys.executable, synth_script,
        "--script", script_matrix_path,
        "--work-dir", work_dir,
        "--voice", voice
    ]
    run_command(synth_cmd, desc=f"Phase 3: Synthesizing Audio for {video_code}")
    timed_script = os.path.join(work_dir, f"{video_code}_script_timed.json")

    # Phase 4: Synchronized Browser Recording
    ego_bin = os.path.expanduser("~/.local/bin/ego-browser")
    if browser_engine == "ego-lite" and os.path.exists(ego_bin):
        record_script = os.path.join(SCRIPT_DIR, "record_screencast_ego.js")
        rec_cmd = [
            ego_bin, "nodejs", record_script,
            "--script", timed_script,
            "--work-dir", work_dir
        ]
        run_command(rec_cmd, desc=f"Phase 4: Ego Lite Browser Execution for {video_code}")
    else:
        record_script = os.path.join(SCRIPT_DIR, "record_screencast.py")
        rec_cmd = [
            sys.executable, record_script,
            "--script", timed_script,
            "--work-dir", work_dir
        ]
        if not headless:
            rec_cmd.append("--headed")
        run_command(rec_cmd, desc=f"Phase 4: Playwright Browser Recording for {video_code}")

    # Phase 5 & 6: Post-Processing, Muxing & QA Verification
    post_script = os.path.join(SCRIPT_DIR, "postprocess_mux.py")
    post_cmd = [
        sys.executable, post_script,
        "--script", timed_script,
        "--work-dir", work_dir,
        "--final-dir", final_dir
    ]
    run_command(post_cmd, desc=f"Phase 5 & 6: Muxing, Subtitles & QA for {video_code}")
    print(f"\n[✓✓✓] SUCCESS: Delivered production assets for [{video_code}] in {final_dir}/\n")

def main():
    parser = argparse.ArgumentParser(description="Master Screencast Pipeline Orchestrator")
    parser.add_argument("--config", help="Path to task queue JSON configuration")
    parser.add_argument("--video-code", help="Single feature video code (e.g. VB-001_ricerca-e-filtri)")
    parser.add_argument("--url", default="https://viscardibomboniere.com", help="Base or target URL")
    parser.add_argument("--work-dir", default="screencasts/work", help="Intermediate asset directory")
    parser.add_argument("--final-dir", default="screencasts/final", help="Deliverables directory")
    parser.add_argument("--voice", default="it-IT-IsabellaNeural", help="TTS voice identifier")
    parser.add_argument("--tts-engine", choices=["edge-tts", "elevenlabs"], default="edge-tts", help="TTS Engine")
    parser.add_argument("--browser-engine", choices=["ego-lite", "playwright"], default="ego-lite", help="Browser engine (default: ego-lite)")
    parser.add_argument("--headed", action="store_true", help="Run browser visibly")
    parser.add_argument("--generate-only", action="store_true", help="Generate task queue & script matrix without running live recording")

    args = parser.parse_args()

    # Load configuration
    if args.config and os.path.exists(args.config):
        with open(args.config, "r", encoding="utf-8") as f:
            cfg = json.load(f)
    else:
        # Build minimal single-feature config
        code = args.video_code or "VB-001_demo"
        cfg = {
            "EXECUTION_MODE": "SINGLE",
            "BASE_URL": args.url,
            "FEATURE_QUEUE": [
                {
                    "video_code": code,
                    "feature_name": code.replace("_", " ").title(),
                    "start_url": args.url,
                    "pre_recording_setup": "Chiudi eventuali banner o cookie prima del frame 0.",
                    "must_demonstrate": ["Esplorare la pagina principale", "Mostrare la funzionalità selezionata"],
                    "out_of_scope": "Non procedere a pagamenti o transazioni reali.",
                    "target_duration_seconds": 60
                }
            ]
        }

    exec_mode = cfg.get("EXECUTION_MODE", "BATCH")
    base_url = cfg.get("BASE_URL", args.url)
    features = cfg.get("FEATURE_QUEUE", [])
    browser_engine = cfg.get("BROWSER_ENGINE", args.browser_engine)

    # Handle Mode B: AUTO_DISCOVER
    if exec_mode == "AUTO_DISCOVER" or features == "AUTO" or len(features) == 0:
        print(f"[*] EXECUTION_MODE is AUTO_DISCOVERY (Engine: {browser_engine}). Initiating site crawl...")
        ego_bin = os.path.expanduser("~/.local/bin/ego-browser")
        if browser_engine == "ego-lite" and os.path.exists(ego_bin):
            discover_script = os.path.join(SCRIPT_DIR, "auto_discover_ego.js")
            run_command([ego_bin, "nodejs", discover_script, "--url", base_url, "--work-dir", args.work_dir])
        else:
            discover_script = os.path.join(SCRIPT_DIR, "auto_discover.py")
            run_command([sys.executable, discover_script, "--url", base_url, "--work-dir", args.work_dir])

        plan_path = os.path.join(args.work_dir, "curriculum_plan.json")
        with open(plan_path, "r", encoding="utf-8") as pf:
            curriculum = json.load(pf)
            features = curriculum.get("FEATURE_QUEUE", [])

    # Process Feature Queue
    for feat in features:
        asyncio.run(execute_feature_pipeline(
            feat,
            base_url=base_url,
            work_dir=args.work_dir,
            final_dir=args.final_dir,
            voice=cfg.get("VOICE", args.voice),
            tts_engine=args.tts_engine,
            browser_engine=browser_engine,
            elevenlabs_key=args.elevenlabs_key,
            headless=not args.headed,
            generate_only=args.generate_only
        ))

if __name__ == "__main__":
    main()
