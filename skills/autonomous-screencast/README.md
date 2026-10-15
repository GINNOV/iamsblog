# Autonomous Instructional Screencast Engineering Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)
[![Node.js 18+](https://img.shields.io/badge/node.js-18+-green.svg)](https://nodejs.org/)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-1080p60-red.svg)](https://ffmpeg.org/)

An autonomous AI agent skill for planning, recording, synthesizing, and packaging broadcast-quality, synchronized video tutorials for web applications.

Works seamlessly with **Google Antigravity**, **OpenAI Codex / ChatGPT**, **Claude Code**, **Hermes Agent**, and **Cursor**.

---

## 🌟 Key Features

* **3 Execution Modes:**
  1. **Single Feature On-Demand:** Provide one specific user flow (e.g., *"Show how to filter by category and apply a promo coupon"*), and the agent records just that.
  2. **Batch Queue:** Supply an array of 5–10 features with deterministic video codes (`VB-001`, `VB-002`, etc.) to produce an entire tutorial series in one run.
  3. **Auto-Discovery Mode:** Point the agent at any web application (`BASE_URL`), and it will crawl the taxonomy, propose a structured curriculum plan (`curriculum_plan.json`), and record every feature sequentially.
* **Dual Browser Support:**
  * **Ego Lite (`ego-browser`):** Uses your active desktop profile and cookies—**no password typing or 2FA hurdles during recording**.
  * **Playwright:** Standalone headless Chromium engine with smooth cubic-bezier mouse trajectories.
* **Mandatory High-Visibility Pointer:** Injects an animated SVG cursor and expanding orange ripple rings (`#E65100`) on mouse clicks so viewers can effortlessly follow the action.
* **Synchronized Neural Voiceover:**
  * Powered by free Microsoft **Edge-TTS** (`it-IT-IsabellaNeural`, `it-IT-DiegoNeural`, or multilingual) or **ElevenLabs**.
  * Measures audio durations per scene with `ffprobe` and holds browser viewports until narration completes.
* **Broadcast-Standard Audio Mastering:** EBU R128 loudness normalization to **-16 LUFS** (-1.5 dB true peak ceiling).
* **Automated Deliverables:** Every video run outputs:
  * `[VIDEO_CODE]_video.mp4` (1920x1080 @ 60fps, H.264 / AAC)
  * `[VIDEO_CODE]_captions.srt` (Frame-accurate subtitles, max 42 chars/line)
  * `[VIDEO_CODE]_captions.vtt` (WebVTT standard format)
  * `[VIDEO_CODE]_transcript.txt` (Clean text transcript)
  * `[VIDEO_CODE]_REPORT_CARD.md` (Detailed production summary & QA audit)

---

## 🚀 Quick Install

### One-Line Install (Remote)
Run this command in your terminal to install the skill across all detected agent environments on your machine:

```bash
curl -fsSL https://raw.githubusercontent.com/GINNOV/littlethings/main/skills/autonomous-screencast/install.sh | bash
```

### Manual / Local Install
If you cloned the repository locally:

```bash
git clone https://github.com/GINNOV/littlethings.git
cd littlethings/skills/autonomous-screencast
./install.sh
```

The installer detects and automatically links the skill to:
* **Antigravity:** `~/.gemini/config/skills/autonomous-screencast`
* **Universal Agent Skills:** `~/.agents/skills/autonomous-screencast`
* **OpenAI Codex:** `~/.codex/skills/autonomous-screencast`
* **Claude Code:** `~/.claude/skills/autonomous-screencast`
* **Hermes Agent:** `~/.hermes/skills/autonomous-screencast`

---

## 📋 Prerequisites

1. **FFmpeg & FFprobe:**
   ```bash
   brew install ffmpeg      # macOS
   sudo apt install ffmpeg  # Ubuntu/Debian
   ```
2. **Python 3 & Edge-TTS:**
   ```bash
   pip install edge-tts
   ```
3. **Browser Engine:**
   * **Ego Lite:** Install [Ego Lite](https://github.com/citrolabs/ego) (default recommended on macOS).
   * **Playwright (Alternative):**
     ```bash
     pip install playwright && playwright install chromium
     ```

---

## 💡 How to Use

### 1. In AI Agent Chat (Antigravity, ChatGPT, Claude, Codex)
Once installed, simply ask your agent in plain English or Italian:

* **Single Feature:**
  > *"Using autonomous-screencast, record a 60-second video tutorial demonstrating how to search products and filter by price on https://example.com."*

* **Batch Production:**
  > *"Run autonomous-screencast in batch mode for our web app using this list of features: DEMO-001 (registration), DEMO-002 (dashboard overview), DEMO-003 (export data)."*

* **Auto-Discovery:**
  > *"Run auto-discovery on https://example.com, map the core customer journeys, and record a numbered tutorial curriculum."*

### 2. From the Terminal (CLI Master Orchestrator)
You can also run the entire pipeline directly with zero AI variance:

```bash
# Single feature run with Ego Lite browser:
python3 ~/.agents/skills/autonomous-screencast/scripts/run_pipeline.py \
  --video-code DEMO-001_quickstart \
  --url "https://example.com" \
  --browser-engine ego-lite

# Run from a custom task queue:
python3 ~/.agents/skills/autonomous-screencast/scripts/run_pipeline.py \
  --config task_queue.json
```

---

## ⚙️ Configuration Schema (`task_queue.json`)

```json
{
  "EXECUTION_MODE": "BATCH",
  "BASE_URL": "https://example.com",
  "LANGUAGE": "it-IT",
  "VOICE": "it-IT-IsabellaNeural",
  "BROWSER_ENGINE": "ego-lite",
  "CREDENTIALS": {
    "use_login": false,
    "login_url": "https://example.com/login",
    "username_or_email": "",
    "password": ""
  },
  "FEATURE_QUEUE": [
    {
      "video_code": "DEMO-001_catalog-search",
      "feature_name": "Product Search and Event Filters",
      "start_url": "https://example.com",
      "pre_recording_setup": "Dismiss cookie banners and promo popups before frame 0.",
      "must_demonstrate": [
        "Navigate to the main category menu",
        "Apply price and in-stock filters",
        "Open a product detail page"
      ],
      "out_of_scope": "Do not proceed to checkout or enter payment details.",
      "target_duration_seconds": 60
    }
  ]
}
```

---

## 📁 Repository Layout

```text
skills/autonomous-screencast/
├── SKILL.md                            # Comprehensive agent instructions & 6-phase pipeline
├── install.sh                          # Universal cross-platform installer
├── README.md                           # Documentation & quickstart
├── scripts/
│   ├── run_pipeline.py                 # Turnkey pipeline orchestrator
│   ├── record_screencast_ego.js        # Ego Lite browser recording runner
│   ├── auto_discover_ego.js            # Ego Lite auto-discovery crawler
│   ├── verify_auth.py                  # Pre-flight login verification & session exporter
│   ├── synthesize_tts.py               # Edge-TTS / ElevenLabs audio synthesizer & duration probe
│   ├── postprocess_mux.py              # Pre-roll trim, -16 LUFS loudnorm, muxer & report cards
│   ├── cursor_overlay.js               # Animated high-contrast SVG pointer & click ripple JS
│   ├── record_screencast.py            # Playwright recorder fallback
│   └── auto_discover.py                # Playwright crawler fallback
├── templates/
│   ├── task_queue.template.json        # Task input configuration template
│   └── script_matrix.template.json     # Scene matrix schema ([VIDEO_CODE]_script.json)
└── references/
    ├── pipeline_architecture.md        # Technical architecture, math, and video encoding
    ├── audio_and_tts.md                # Italian voice personas, Edge-TTS/ElevenLabs, -16 LUFS
    └── auto_discovery_heuristics.md    # Crawling heuristics and safety boundaries
```

---

## 📄 License

MIT © GINNOV
