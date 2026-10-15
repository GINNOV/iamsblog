---
name: autonomous-screencast
description: >-
  Autonomous instructional screencast engineering skill (also known as screencast-tutorial-generator).
  Use this skill whenever the user asks to plan, record, synthesize, or package high-definition video tutorials with
  synchronized Italian voiceover, custom cursor tracking, click animations, and subtitles for web applications (with defaults for viscardibomboniere.com).
  Supports Single Feature On-Demand, Batch Queue, and Auto-Discovery modes, and operates either as an end-to-end local autonomous runner or as a standalone package/code generator.
---

# Autonomous Instructional Screencast Engineering Skill

This skill guides the autonomous planning, recording, audio synthesis, browser automation, visual cursor rendering, and post-production muxing of professional, synchronized instructional video tutorials in Italian (or customizable language) for web applications (optimized for **https://viscardibomboniere.com**).

---

## What the Skill Does vs. What Runs Locally

The skill supports two operational postures depending on the agent environment and user request:

1. **End-to-End Autonomous Execution (Local Agent Runner):**
   - When tools such as Playwright, FFmpeg, and Python are available locally, the agent executes the full pipeline end-to-end: crawls the site, synthesizes TTS audio, records the browser with smooth cursor movements, trims frames, normalizes audio to -16 LUFS, muxes 1080p60 H.264/AAC video, generates captions, and runs self-QA checks.
2. **Package & Code Generation Mode (`--generate-only`):**
   - In sandboxed environments without direct browser/video rendering access, or when the user simply requests *"Generate the complete Playwright + TTS + FFmpeg package"*, the skill produces the complete task queue, Italian narration (`narration_it`), scene-by-scene action matrix (`[VIDEO_CODE]_script.json`), injected cursor JS, and self-contained runner scripts ready for immediate local execution.

---

## 1. Execution Modes (How to Specify What to Record)

The skill operates in three flexible execution modes defined in the task configuration:

1. **Single Feature On-Demand:**
   - The user provides one specific workflow (e.g., *"Show how to filter favors by Baptism and customize the ribbon printing"*).
   - The agent sets `EXECUTION_MODE: "SINGLE"`, scopes the specific `must_demonstrate` actions, and outputs one complete video package.
2. **Batch Queue (Multiple Specific Features):**
   - The user supplies an array of 5, 10, or more features with explicit video codes (e.g., `VB-001`, `VB-002`, `VB-003`).
   - The agent processes each feature sequentially from Phase 1 through Phase 6.
3. **Auto-Discovery Mode:**
   - Triggered when `FEATURE_QUEUE` is empty or set to `"AUTO"`.
   - The agent crawls `viscardibomboniere.com` (or target `BASE_URL`), maps available features (navigation, search, product customization, cart, support), generates a numbered curriculum plan (`screencasts/work/curriculum_plan.json`), and executes each one sequentially.

---

## 2. Task Queue Configuration Schema

Provide or generate the task input in the following structured JSON format:

```json
{
  "EXECUTION_MODE": "BATCH",
  "BASE_URL": "https://viscardibomboniere.com",
  "LANGUAGE": "it-IT",
  "VOICE": "it-IT-IsabellaNeural",
  "CREDENTIALS": {
    "use_login": false,
    "login_url": "https://viscardibomboniere.com/mio-account",
    "username_or_email": "",
    "password": ""
  },
  "FEATURE_QUEUE": [
    {
      "video_code": "VB-001_ricerca-e-filtri",
      "feature_name": "Ricerca nel catalogo e utilizzo dei filtri per evento",
      "start_url": "https://viscardibomboniere.com",
      "pre_recording_setup": "Accetta i cookie e chiudi eventuali popup promozionali prima di avviare la registrazione.",
      "must_demonstrate": [
        "Mostrare la barra di navigazione principale e le categorie di eventi (Matrimonio, Battesimo, Comunione, Laurea)",
        "Cliccare su una categoria specifica",
        "Utilizzare i filtri (es. fascia di prezzo o disponibilità) per restringere i risultati",
        "Aprire la scheda di una bomboniera per mostrarne i dettagli e le foto"
      ],
      "out_of_scope": "Non procedere al pagamento o al checkout in questo video; fermati alla scheda prodotto.",
      "target_duration_seconds": 60
    },
    {
      "video_code": "VB-002_personalizzazione-bomboniera",
      "feature_name": "Come personalizzare una bomboniera (confetti, bigliettino e confezione)",
      "start_url": "https://viscardibomboniere.com",
      "pre_recording_setup": "Naviga direttamente su una scheda prodotto che supporta la personalizzazione prima del frame 0.",
      "must_demonstrate": [
        "Selezionare il gusto/colore dei confetti",
        "Inserire i dati per il bigliettino personalizzato (nomi e data evento)",
        "Impostare la quantità desiderata",
        "Cliccare su Aggiungi al Carrello e mostrare il riepilogo delle personalizzazioni"
      ],
      "out_of_scope": "Non spiegare la registrazione dell'account o il pagamento finale.",
      "target_duration_seconds": 75
    }
  ]
}
```

### Key Scoping Fields:
- **`pre_recording_setup` vs `must_demonstrate`:** Any step inside `pre_recording_setup` (e.g., logging in, accepting cookies, or pre-filling a cart) happens **off-camera**. Frames prior to `t_zero` are automatically trimmed out so the tutorial begins directly on the relevant screen.
- **`out_of_scope`:** Hard boundaries to prevent the agent from wandering into unrelated features or triggering live checkout orders.
- **`CREDENTIALS`:** When `use_login: true`, the agent executes authentication during `pre_recording_setup`.

---

## 3. File System & Naming Architecture

Always maintain this directory layout in the project root:
- `screencasts/work/` — Intermediate and temporary assets (raw `.webm` captures, individual `.mp3` scene clips, timing logs, `_script.json`, keyframes).
- `screencasts/final/` — Production deliverables.

### Deliverables per `[VIDEO_CODE]`
Every tutorial in `screencasts/final/` must produce:
1. **Final Video:** `screencasts/final/[VIDEO_CODE]_video.mp4` (H.264, AAC, 1920x1080, 60fps, yuv420p).
2. **Full Transcript:** `screencasts/final/[VIDEO_CODE]_transcript.txt` (Clean Italian text formatted into logical sections).
3. **Timed Subtitles (SRT):** `screencasts/final/[VIDEO_CODE]_captions.srt` (Max 42 chars/line, max 2 lines/block, frame-accurate).
4. **Timed Subtitles (VTT):** `screencasts/final/[VIDEO_CODE]_captions.vtt` (WebVTT standard format).

---

## 4. Visual & Pointer Specification (Mandatory DOM Injection)

Headless browsers do not display the operating system cursor. In every recording, inject the custom visual cursor overlay script (`scripts/cursor_overlay.js` via Playwright `context.add_init_script`):

1. **High-Visibility SVG Cursor:** A distinct white pointer arrow with a dark border and drop shadow tracking mouse coordinates smoothly.
2. **Smooth Interpolation:** Never teleport the mouse. Move along smooth trajectories (`steps=35` or cubic bezier over `600ms–900ms`) from the current position to the element's bounding box center.
3. **Hover Hold:** Pause `250ms` on hover before clicking.
4. **Click Ripple & Pulse:** On mousedown, trigger an expanding orange circular ring (`border: 3px solid #E65100`, `background: rgba(255, 152, 0, 0.25)`) animating from `0px` to `64px` over `550ms`, accompanied by an outline pulse on the clicked element.

---

## 5. Language, Voiceover & Audio Specification

1. **Language:** Native, warm Italian (`it-IT`). Use polite, friendly second-person address ("tu", e.g., *"Per prima cosa, clicca su..."*, *"Come puoi vedere qui in alto..."*).
2. **Pacing & Prosody:** Measured and unhurried (~130–145 WPM).
3. **Timing Padding:**
   - `lead_in_ms`: `300ms` pause before narration begins.
   - `lead_out_ms`: `600ms–800ms` visual hold after action/speech completes before transitioning.
4. **Voice Engine:**
   - Microsoft Edge-TTS: `it-IT-IsabellaNeural` (recommended default female voice) or `it-IT-DiegoNeural` (male voice) with prosody `rate="-5%"`.
   - ElevenLabs: `eleven_multilingual_v2` (stability: `0.65`, similarity_boost: `0.80`, style: `0.15`).
5. **Audio Mastering:** EBU R128 loudness normalization to **-16 LUFS** with a **-1.5 dB true peak** ceiling (`loudnorm=I=-16:TP=-1.5:LRA=11`).

---

## 6. End-to-End 6-Phase Pipeline

Execute each feature sequentially through these 6 phases:

### Phase 1: Feature Reconnaissance & DOM Mapping
1. Launch Chromium (1920x1080, scale 1, locale `it-IT`).
2. Navigate to `start_url` and dismiss cookie/newsletter modals.
3. Dry run the feature to verify resilient selectors and confirm the path from start state to end goal works cleanly.

### Phase 2: Action-Audio Script Matrix (`screencasts/work/[VIDEO_CODE]_script.json`)
Break the walkthrough into atomic scenes. For each scene, specify:
- `scene_id`: Sequential integer.
- `narration_it`: Spoken Italian sentences.
- `browser_actions`: Array of `hover`, `click`, `type` (80ms delay/char), or `scroll` actions.
- `lead_in_ms` (300ms) and `lead_out_ms` (600ms).

### Phase 3: TTS Audio Synthesis & Timing Extraction
1. Generate audio for each scene clip (`[VIDEO_CODE]_scene_XX.mp3`).
2. Probe exact durations with `ffprobe`.
3. Compute the cumulative timeline so browser recording knows exactly how long to hold at each step.

### Phase 4: Synchronized Browser Recording
1. Start recording context (`record_video_dir="screencasts/work/"`).
2. Inject `cursor_overlay.js`.
3. Execute `pre_recording_setup` off-camera.
4. Mark `t_zero` timestamp.
5. Execute each scene:
   - Glide mouse to target (`mouse.move(x, y, steps=35)`).
   - Hover pause (250ms).
   - Trigger click or type.
   - Wait remaining duration: `audio_duration_ms - elapsed_action_ms + lead_out_ms`.
6. Close context to flush `[VIDEO_CODE]_raw_video.webm`.

### Phase 5: Post-Processing, Muxing & Subtitle Generation
1. **Trim Pre-Roll:** Trim all frames before `t_zero` via FFmpeg.
2. **Audio Assembly:** Concatenate scene clips with silence padding and normalize to -16 LUFS.
3. **Mux Final MP4:**
   ```bash
   ffmpeg -y -i screencasts/work/[VIDEO_CODE]_trimmed.webm \
          -i screencasts/work/[VIDEO_CODE]_full_audio.wav \
          -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 60 \
          -c:a aac -b:a 192k -movflags +faststart \
          screencasts/final/[VIDEO_CODE]_video.mp4
   ```
4. **Generate Captions:** Output `[VIDEO_CODE]_captions.srt` (max 42 chars/line), `[VIDEO_CODE]_captions.vtt`, and `[VIDEO_CODE]_transcript.txt`.

### Phase 6: Automated Quality Assurance & Deliverables Report Card
1. **Automated Verification:**
   - Confirm all 4 core files exist and are non-empty (`_video.mp4`, `_transcript.txt`, `_captions.srt`, `_captions.vtt`).
   - `ffprobe` confirms H.264 1080p60 + AAC streams with matched duration ($\pm 0.5\text{s}$).
   - Extract 3 keyframes into `screencasts/work/` to verify cursor rendering visually.
2. **Production Deliverables Report Card (Mandatory):**
   - Save `screencasts/final/[VIDEO_CODE]_REPORT_CARD.md`.
   - Present a structured **Report Card** to the user containing:
     - Executive summary (feature name, video code, duration, scenes).
     - Clickable links to all 4 deliverables with file sizes.
     - QA verification checklist (resolution, fps, loudness, synchronization).
     - Local playback and HTML5 web-embedding snippets.

---

## 7. Reusable Helper Scripts

The skill provides production-ready helper scripts located in `./scripts/`:

- **Unified Master Orchestrator:** [`scripts/run_pipeline.py`](./scripts/run_pipeline.py)  
  Runs the end-to-end pipeline across all phases, orchestrates Edge-TTS / ElevenLabs, coordinates Playwright recording, handles FFmpeg muxing, and supports a `--generate-only` flag to build packages without executing browser/video rendering.
- **Cursor Overlay:** [`scripts/cursor_overlay.js`](./scripts/cursor_overlay.js)  
  Injected via `context.add_init_script` to render the SVG pointer, smooth movement, and orange ripple rings.
- **Audio Synthesizer:** [`scripts/synthesize_tts.py`](./scripts/synthesize_tts.py)  
  Synthesizes scene audio via `edge-tts` and probes durations with `ffprobe`.
- **Ego Lite Browser Recorder:** [`scripts/record_screencast_ego.js`](./scripts/record_screencast_ego.js)  
  Drives Ego Lite browser (`ego-browser nodejs`) using the user's active session, native pointer labels, and timeline synchronization.
- **Ego Lite Auto-Discovery:** [`scripts/auto_discover_ego.js`](./scripts/auto_discover_ego.js)  
  Crawls `BASE_URL` within Ego Lite's active profile, extracts site taxonomy, and outputs `curriculum_plan.json`.
- **Playwright Browser Recorder:** [`scripts/record_screencast.py`](./scripts/record_screencast.py)  
  Alternative headless Playwright runner with smooth bezier trajectories and audio synchronization.
- **Post-Processor & Muxer:** [`scripts/postprocess_mux.py`](./scripts/postprocess_mux.py)  
  Handles pre-roll trimming, audio concatenation, -16 LUFS normalization, H.264/AAC muxing, captions, and QA verification.
- **Authentication Verifier & Session Exporter:** [`scripts/verify_auth.py`](./scripts/verify_auth.py)  
  Tests login credentials off-camera, verifies post-login DOM state, captures a proof screenshot, and exports persistent `auth.json` session state.
- **Auto-Discovery Crawler:** [`scripts/auto_discover.py`](./scripts/auto_discover.py)  
  Playwright-based crawler to map navigation, categories, and flows, generating `curriculum_plan.json`.

---

## 8. Templates & Reference Documentation

- [Task Queue Template](./templates/task_queue.template.json): Example configuration for Single, Batch, and Auto modes.
- [Script Matrix Template](./templates/script_matrix.template.json): Scene schema for `[VIDEO_CODE]_script.json`.
- [Pipeline Architecture Deep Dive](./references/pipeline_architecture.md): Detailed timing math and synchronization logic.
- [Audio & TTS Guide](./references/audio_and_tts.md): Voice models, pronunciation tips, and mastering specs.
- [Auto-Discovery Heuristics](./references/auto_discovery_heuristics.md): Crawling strategies, taxonomy mapping, and safety boundaries.

---

## 9. How to Trigger It Anytime

You can invoke this skill across sessions with natural prompts such as:

- **Single Feature Package:**  
  *"Generate a screencast package VB-003_checkout-rapido showing how to complete an order on viscardibomboniere.com."*
- **Turnkey Code Generation:**  
  *"Write the complete Python Playwright + ElevenLabs + FFmpeg runner script for the screencast-tutorial-generator workflow."*
- **Batch Production:**  
  *"Run screencasts in batch mode for viscardibomboniere.com covering VB-001 (catalogo) and VB-002 (personalizzazione).'"*
- **Autonomous Auto-Discovery:**  
  *"Run auto-discovery on viscardibomboniere.com to map available workflows and record the full tutorial curriculum."*

