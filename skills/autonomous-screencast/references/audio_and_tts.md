# Italian Voiceover, Audio Specs & Mastering Guide

This guide details voice personas, TTS engine configurations, prosody, and loudness mastering for Italian instructional screencasts.

---

## 1. Voice Persona & Conversational Tone

- **Tone:** Warm, polite, reassuring, patient, and conversational.
- **Form of Address:** Friendly informal second-person singular ("tu"):
  - *"Per prima cosa, clicca sulla categoria..."*
  - *"Come puoi vedere qui in alto, compaiono tutti i filtri disponibili..."*
  - *"Se desideri aggiungere un bigliettino personalizzato, inserisci qui il tuo testo..."*
- **Avoid:**
  - Mechanical literal translations (e.g., avoid *"clicca il bottone di submit"*; use *"clicca su Invia"* or *"conferma con un clic"*).
  - Rushing through steps without breathing pauses.
- **Pacing:** 130 to 145 words per minute (WPM). A prosody rate adjustment of `-5%` creates a relaxed, premium tutorial feel.

---

## 2. TTS Voice Selection & Configurations

### Option A: Microsoft Edge-TTS / Azure Neural (Free & High Quality)
- `it-IT-IsabellaNeural` (Default recommended female voice: warm, clear, melodic).
- `it-IT-ElsaNeural` (Clear, professional, neutral).
- `it-IT-DiegoNeural` (Natural male voice: reassuring, grounded).
- `it-IT-GiuseppeNeural` (Professional male voice).

**CLI command:**
```bash
edge-tts --voice it-IT-IsabellaNeural --rate="-5%" --text "Benvenuto su Viscardi Bomboniere." --write-media scene_01.mp3
```

### Option B: ElevenLabs Neural
- Model: `eleven_multilingual_v2`
- Voice Settings:
  - `stability`: `0.65`
  - `similarity_boost`: `0.80`
  - `style`: `0.15`
  - `use_speaker_boost`: `true`

---

## 3. Audio Timeline & Padding

To give viewers time to visually register UI changes:
- **Lead-In Silence (`lead_in_ms`):** `300ms` before speech begins.
- **Lead-Out Silence (`lead_out_ms`):** `600ms–800ms` after speech finishes before switching pages or views.
- **Inter-action pause:** `250ms` hover pause on buttons before triggering clicks.

---

## 4. Audio Mastering & Loudness Normalization

Broadcast standard for web video audio:
- **Target Integrated Loudness:** `-16 LUFS` (standard for web / YouTube / OTT).
- **True Peak Ceiling:** `-1.5 dBTP`.
- **Loudness Range (LRA):** `11 LU`.

### FFmpeg Filter Command
```bash
ffmpeg -y -i raw_concatenated.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" normalized_master.wav
```
