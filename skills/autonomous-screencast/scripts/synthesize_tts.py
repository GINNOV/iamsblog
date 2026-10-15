#!/usr/bin/env python3
"""
TTS Audio Synthesis and Timing Extraction Script for Autonomous Screencasts.
Synthesizes per-scene audio files in Italian using Edge-TTS or ElevenLabs,
and probes exact millisecond durations via ffprobe.

Usage:
    python3 synthesize_tts.py --script screencasts/work/VB-001_script.json --work-dir screencasts/work/
"""

import argparse
import asyncio
import json
import os
import subprocess
import sys

async def synthesize_edge_tts(text: str, output_path: str, voice: str = "it-IT-IsabellaNeural", rate: str = "-5%"):
    """Synthesize voice using edge-tts python library or CLI."""
    try:
        import edge_tts
        communicate = edge_tts.Communicate(text, voice, rate=rate)
        await communicate.save(output_path)
        return True
    except ImportError:
        # Fallback to edge-tts command line tool if available
        cmd = ["edge-tts", "--voice", voice, f"--rate={rate}", "--text", text, f"--write-media={output_path}"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            return True
        raise RuntimeError(
            "Neither python package 'edge_tts' nor 'edge-tts' CLI found. "
            "Install with: pip install edge-tts"
        )

def get_audio_duration_ms(file_path: str) -> int:
    """Measure exact duration of an audio file in milliseconds via ffprobe."""
    cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        file_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    duration_seconds = float(result.stdout.strip())
    return int(round(duration_seconds * 1000))

async def process_script(script_path: str, work_dir: str, voice: str = "it-IT-IsabellaNeural", rate: str = "-5%"):
    with open(script_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    video_code = data.get("video_code", "screencast")
    scenes = data.get("scenes", [])
    os.makedirs(work_dir, exist_ok=True)

    print(f"[*] Processing {len(scenes)} scenes for [{video_code}] using voice '{voice}' (rate={rate})...")

    cumulative_ms = 0
    for scene in scenes:
        scene_id = scene.get("scene_id", 1)
        narration = scene.get("narration_it", "").strip()
        lead_in_ms = scene.get("lead_in_ms", 300)
        lead_out_ms = scene.get("lead_out_ms", 600)

        filename = f"{video_code}_scene_{scene_id:02d}.mp3"
        out_audio_path = os.path.join(work_dir, filename)

        if not narration:
            # Empty narration: synthesize 1s silence or skip
            scene["audio_file"] = ""
            scene["audio_duration_ms"] = 0
            scene["scene_duration_ms"] = lead_in_ms + lead_out_ms
            continue

        print(f"  -> Scene {scene_id}: Synthesizing: \"{narration[:45]}...\"")
        await synthesize_edge_tts(narration, out_audio_path, voice=voice, rate=rate)

        duration_ms = get_audio_duration_ms(out_audio_path)
        scene["audio_file"] = filename
        scene["audio_duration_ms"] = duration_ms
        scene["lead_in_ms"] = lead_in_ms
        scene["lead_out_ms"] = lead_out_ms
        scene["scene_start_ms"] = cumulative_ms
        scene["scene_duration_ms"] = lead_in_ms + duration_ms + lead_out_ms

        cumulative_ms += scene["scene_duration_ms"]
        print(f"     Duration: {duration_ms}ms (Total scene duration: {scene['scene_duration_ms']}ms)")

    data["total_calculated_duration_ms"] = cumulative_ms

    # Save updated script matrix with exact timings
    updated_path = os.path.join(work_dir, f"{video_code}_script_timed.json")
    with open(updated_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"[✓] Completed TTS synthesis. Total timeline: {cumulative_ms/1000.0:.2f}s. Saved to {updated_path}")
    return updated_path

def main():
    parser = argparse.ArgumentParser(description="TTS Audio Synthesizer for Screencasts")
    parser.add_argument("--script", required=True, help="Path to [VIDEO_CODE]_script.json")
    parser.add_argument("--work-dir", default="screencasts/work", help="Working directory for audio assets")
    parser.add_argument("--voice", default="it-IT-IsabellaNeural", help="Neural TTS voice identifier")
    parser.add_argument("--rate", default="-5%", help="Prosody rate adjustment (e.g. -5% for natural calm pacing)")

    args = parser.parse_args()
    asyncio.run(process_script(args.script, args.work_dir, voice=args.voice, rate=args.rate))

if __name__ == "__main__":
    main()
