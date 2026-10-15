#!/usr/bin/env node
/**
 * Ego Lite Synchronized Browser Recorder for Autonomous Screencasts.
 * Executes scenes inside Ego Lite browser with native visible cursor, action labels,
 * and exact timeline synchronization.
 *
 * Usage:
 *   ego-browser nodejs record_screencast_ego.js --script screencasts/work/VB-001_script_timed.json --work-dir screencasts/work/
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Parse CLI args
const args = process.argv.slice(2);
let scriptFile = '';
let workDir = 'screencasts/work';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--script' && args[i + 1]) {
    scriptFile = args[i + 1];
    i++;
  } else if (args[i] === '--work-dir' && args[i + 1]) {
    workDir = args[i + 1];
    i++;
  }
}

if (!scriptFile) {
  console.error('[!] Error: --script [path] is required');
  process.exit(1);
}

const rawData = await fs.readFile(scriptFile, 'utf8');
const scriptData = JSON.parse(rawData);

const videoCode = scriptData.video_code || 'screencast';
const startUrl = scriptData.start_url || 'https://viscardibomboniere.com';
const scenes = scriptData.scenes || [];
const preActions = scriptData.pre_recording_setup_actions || [];

console.log(`[*] Initializing Ego Lite browser session for [${videoCode}]...`);

// 1. Create task space in Ego Lite
const task = await taskSpace(`screencast-${videoCode}`);
const page = task.page('p1');

console.log(`[*] Navigating to ${startUrl} in Ego Lite...`);
await page.goto(startUrl, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(1000);

// 2. Pre-recording setup (cookie dismissal, popups)
try {
  const cookieSelector = "button:has-text('Accetta'), button:has-text('Accetto'), #cookie-accept";
  const hasCookie = await page.evaluate((sel) => {
    const btn = document.querySelector(sel);
    if (btn) { btn.click(); return true; }
    return false;
  }, cookieSelector);
  if (hasCookie) console.log('  -> Dismissed cookie consent in Ego Lite.');
} catch (e) {}

for (const act of preActions) {
  if (act.type === 'click' && act.selector) {
    try { await page.click(act.selector); } catch (e) {}
  } else if (act.type === 'navigate' && act.url) {
    await page.goto(act.url);
  }
  await page.waitForTimeout(500);
}

// 3. Mark t_zero
const tZeroTime = Date.now();
console.log(`[✓] Setup complete in Ego Lite. Recording timeline starting at t_zero...`);

// 4. Execute scenes synchronized to TTS duration
for (const scene of scenes) {
  const sceneId = scene.scene_id;
  const narration = scene.narration_it || '';
  const actions = scene.browser_actions || [];
  const leadIn = scene.lead_in_ms || 300;
  const audioDuration = scene.audio_duration_ms || 3000;
  const leadOut = scene.lead_out_ms || 600;
  const totalSceneMs = leadIn + audioDuration + leadOut;

  const sceneStart = Date.now();
  console.log(`[*] Scene ${sceneId}: ${narration.substring(0, 45)}... (Duration: ${totalSceneMs}ms)`);

  if (leadIn > 0) {
    await page.waitForTimeout(leadIn);
  }

  for (const act of actions) {
    const label = narration.length > 30 ? narration.substring(0, 30) + '...' : narration;
    if (act.type === 'click' && act.selector) {
      try {
        await page.click(act.selector, { label });
      } catch (err) {
        console.warn(`    Warning on click ${act.selector}: ${err.message}`);
      }
    } else if (act.type === 'hover' && act.selector) {
      try {
        await page.hover(act.selector, { label });
      } catch (err) {}
    } else if (act.type === 'type' && act.text) {
      try {
        if (act.selector) await page.focus(act.selector);
        await page.keyboard.type(act.text, { delay: 80 });
      } catch (err) {}
    }

    if (act.wait_after_ms) {
      await page.waitForTimeout(act.wait_after_ms);
    }
  }

  // Hold for the remainder of the speech
  const elapsed = Date.now() - sceneStart;
  const remaining = totalSceneMs - elapsed;
  if (remaining > 0) {
    await page.waitForTimeout(remaining);
  }
}

const totalDurationSec = (Date.now() - tZeroTime) / 1000.0;
console.log(`[✓] Completed all scenes in Ego Lite (${totalDurationSec.toFixed(2)}s).`);

// Save timing metadata
const timingMeta = {
  video_code: videoCode,
  browser_engine: 'ego-lite',
  t_zero_seconds: 1.0,
  total_recorded_seconds: totalDurationSec
};

await fs.writeFile(
  path.join(workDir, `${videoCode}_timing_meta.json`),
  JSON.stringify(timingMeta, null, 2),
  'utf8'
);

// Finish task
await task.finish({ keep: [] });
console.log(`[✓] Ego Lite task finished and cleaned up.`);
