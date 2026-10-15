# Screencast Autonomous Pipeline Architecture

This document describes the 6-phase engineering pipeline used to record, synthesize, synchronize, and package high-definition screencasts.

---

## Pipeline Overview

```
Phase 1: Feature Reconnaissance & DOM Mapping (Dry-run, selector verification, off-camera setup)
      │
      ▼
Phase 2: Action-Audio Script Matrix ([VIDEO_CODE]_script.json generation)
      │
      ▼
Phase 3: TTS Audio Synthesis & Timing Extraction (ffprobe duration probing, timeline indexing)
      │
      ▼
Phase 4: Synchronized Browser Recording (Playwright + Cursor Overlay + synchronized wait loop)
      │
      ▼
Phase 5: Post-Processing, Muxing & Captions (FFmpeg trim, loudnorm -16 LUFS, H.264/AAC mux, SRT/VTT)
      │
      ▼
Phase 6: Automated Quality Assurance (Verification checklist: streams, durations, keyframes)
```

---

## Phase Details & Formulas

### Phase 1: Feature Reconnaissance & DOM Mapping
1. **Viewport & Device Scale:** Launch headless Chromium at `1920x1080`, device scale factor 1.0, locale `it-IT`.
2. **Pre-Recording Setup:** Dismiss cookie consent banners, modal alerts, newsletter popups, or perform prerequisites (such as logging in or populating a cart) **before** the recording timeline begins.
3. **Resilient Selectors:** Discover stable selectors preferring ARIA roles, test IDs, or distinct text content over brittle auto-generated CSS classes.

### Phase 2: Action-Audio Script Matrix
Break the tutorial into atomic scenes. For each scene:
- `scene_id`: Sequential integer (1, 2, 3...).
- `narration_it`: Spoken natural Italian text.
- `lead_in_ms`: Visual pause before speech starts (default: `300ms`).
- `lead_out_ms`: Visual hold after action/speech completes (default: `600ms`).
- `browser_actions`: Atomic interaction sequence (`hover`, `click`, `type`, `scroll`).

### Phase 3: TTS Audio Synthesis & Timing Extraction
1. Synthesize audio per scene: `[VIDEO_CODE]_scene_XX.mp3`.
2. Measure duration in milliseconds via `ffprobe`:
   $$\text{Duration}_{\text{ms}} = \text{round}(\text{duration\_seconds} \times 1000)$$
3. Compute cumulative timeline:
   $$\text{SceneTotal}_{\text{ms}} = \text{lead\_in\_ms} + \text{Duration}_{\text{ms}} + \text{lead\_out\_ms}$$
   $$\text{TimelineStart}_{i} = \sum_{k=1}^{i-1} \text{SceneTotal}_{k}$$

### Phase 4: Synchronized Browser Recording
- Mouse movement uses cubic-bezier interpolation or 35 subdivision steps over `600ms–900ms` (`page.mouse.move(x, y, steps=35)`).
- Hover hold: `250ms` on target element before click.
- Click triggers visual circle animation and element pulse via injected script.
- Wait formula:
  $$\text{WaitRemaining}_{\text{ms}} = \text{SceneTotal}_{\text{ms}} - \text{ActionElapsed}_{\text{ms}}$$
- Ensures browser video duration exactly mirrors the synthesized voiceover duration.

### Phase 5: Post-Processing & Muxing
- **Pre-Roll Trimming:** Trim all frames before `t_zero` so Frame 0 begins with a ready UI:
  ```bash
  ffmpeg -y -ss <t_zero_seconds> -i [VIDEO_CODE]_raw_video.webm -c:v copy [VIDEO_CODE]_trimmed.webm
  ```
- **Loudness Normalization:** Concatenate scene audios and normalize to EBU R128 standard:
  ```bash
  ffmpeg -y -i [VIDEO_CODE]_unnorm.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" [VIDEO_CODE]_full_audio.wav
  ```
- **Final Multiplexing (H.264 / AAC 60fps):**
  ```bash
  ffmpeg -y -i [VIDEO_CODE]_trimmed.webm -i [VIDEO_CODE]_full_audio.wav \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 60 \
    -c:a aac -b:a 192k -movflags +faststart \
    screencasts/final/[VIDEO_CODE]_video.mp4
  ```
- **Captions & Transcript Generation:**
  Generate frame-accurate `.srt` and `.vtt` using calculated start and end milliseconds for each scene. Format subtitle lines with max 42 characters and max 2 lines per block.

### Phase 6: Automated Quality Assurance
Audit deliverables inside `screencasts/final/`:
1. `_video.mp4` exists, size > 0.
2. `_transcript.txt` exists, size > 0.
3. `_captions.srt` exists, size > 0.
4. `_captions.vtt` exists, size > 0.
5. Stream check: H.264 1920x1080 at 60fps, AAC audio.
6. Sync check: $|\text{VideoDuration} - \text{AudioDuration}| \le 0.5\text{s}$.
7. Extract 3 verification keyframes to `screencasts/work/` to confirm cursor rendering.
