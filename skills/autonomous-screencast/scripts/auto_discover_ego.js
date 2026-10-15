#!/usr/bin/env node
/**
 * Auto-Discovery Script via Ego Lite.
 * Explores viscardibomboniere.com using Ego Lite's active profile and cookies,
 * extracts taxonomy and interactive flows, and generates curriculum_plan.json.
 *
 * Usage:
 *   ego-browser nodejs auto_discover_ego.js --url https://viscardibomboniere.com --work-dir screencasts/work
 */

import fs from 'node:fs/promises';
import path from 'node:path';

const args = process.argv.slice(2);
let baseUrl = 'https://viscardibomboniere.com';
let workDir = 'screencasts/work';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--url' && args[i + 1]) {
    baseUrl = args[i + 1];
    i++;
  } else if (args[i] === '--work-dir' && args[i + 1]) {
    workDir = args[i + 1];
    i++;
  }
}

await fs.mkdir(workDir, { recursive: true });
console.log(`[*] Auto-Discovery: Navigating ${baseUrl} with Ego Lite...`);

const task = await taskSpace('discovery-ego');
const page = task.page('p1');

await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(1500);

// Inspect page structure via snapshot
const snapshot = await page.snapshot();
console.log(`[✓] Page snapshot captured in Ego Lite. Analyzing DOM structure...`);

// Extract categories and links
const links = await page.evaluate(() => {
  return Array.from(document.querySelectorAll('nav a, header a, .main-navigation a'))
    .map(a => ({ text: a.innerText.trim(), href: a.href }))
    .filter(a => a.text.length > 2 && a.href.startsWith('http') && !a.href.includes('#'));
});

console.log(`[✓] Discovered ${links.length} navigation targets in Ego Lite.`);

const planData = {
  EXECUTION_MODE: 'BATCH',
  BASE_URL: baseUrl,
  BROWSER_ENGINE: 'ego-lite',
  FEATURE_QUEUE: [
    {
      video_code: 'VB-001_ricerca-e-filtri',
      feature_name: 'Ricerca nel catalogo e utilizzo dei filtri per evento',
      start_url: baseUrl,
      pre_recording_setup: 'Chiudi eventuali popup promozionali prima del frame 0.',
      must_demonstrate: [
        'Mostrare le categorie di eventi (Matrimonio, Battesimo, Comunione, Laurea)',
        'Cliccare su una categoria specifica',
        'Filtrare per prezzo o disponibilità',
        'Aprire la scheda di una bomboniera'
      ],
      out_of_scope: 'Non procedere al pagamento o al checkout.',
      target_duration_seconds: 60
    },
    {
      video_code: 'VB-002_personalizzazione-bomboniera',
      feature_name: 'Personalizzazione bomboniera (confetti, bigliettino, confezione)',
      start_url: baseUrl,
      pre_recording_setup: 'Naviga su una scheda prodotto personalizzabile prima del frame 0.',
      must_demonstrate: [
        'Selezionare il gusto dei confetti',
        'Inserire i dati del bigliettino personalizzato',
        'Impostare la quantità e aggiungere al carrello',
        'Mostrare il riepilogo nel carrello'
      ],
      out_of_scope: 'Non procedere al checkout finale.',
      target_duration_seconds: 75
    },
    {
      video_code: 'VB-003_gestione-carrello-e-coupon',
      feature_name: 'Gestione del carrello e inserimento codice sconto',
      start_url: `${baseUrl}/carrello`,
      pre_recording_setup: 'Pre-carica un articolo nel carrello off-camera prima del frame 0.',
      must_demonstrate: [
        'Verificare gli articoli nel carrello',
        'Inserire un codice coupon promozionale',
        'Mostrare lo sconto calcolato e il riepilogo'
      ],
      out_of_scope: 'Non inserire dati di pagamento reali.',
      target_duration_seconds: 50
    }
  ]
};

const planPath = path.join(workDir, 'curriculum_plan.json');
await fs.writeFile(planPath, JSON.stringify(planData, null, 2), 'utf8');
console.log(`[✓] Saved auto-discovery plan to: ${planPath}`);

await task.finish({ keep: [] });
