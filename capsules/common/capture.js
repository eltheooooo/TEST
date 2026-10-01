// Capture image par image d'une capsule.
// Usage : node capture.js <page.html> <fps> <dossier> [début-fin | t1 t2 ...]
//   sans 3e argument : toutes les images ; « a-b » : plage d'indices ; sinon liste de temps (s).
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
(async () => {
  const [page_, fpsArg, out, ...rest] = process.argv.slice(2);
  const fps = +fpsArg;
  const range = rest[0] && rest[0].includes('-') ? rest[0].split('-').map(Number) : null;
  const only = range ? [] : rest.map(Number);
  fs.mkdirSync(out, { recursive: true });
  const exe = ['/opt/pw-browsers/chromium-1194/chrome-linux/chrome'].find(p => fs.existsSync(p));
  const browser = await chromium.launch(exe ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  page.on('pageerror', e => console.error('PAGE ERROR', e.message));
  await page.goto('file://' + path.resolve(page_));
  await page.evaluate(async () => { await document.fonts.ready; await document.fonts.load('100px "Fredoka One"'); await document.fonts.load('800 30px Montserrat'); await document.fonts.load('600 30px Montserrat'); await document.fonts.load('700 30px Montserrat'); });
  await page.evaluate(() => window.render(0)); // re-mesure les textes une fois les polices chargées
  const dur = await page.evaluate(() => window.DURATION);
  const total = Math.round(dur * fps);
  const idx = only.length ? only.map((t, i) => i) : Array.from({ length: total }, (_, i) => i).slice(range ? range[0] : 0, range ? range[1] : total);
  for (const i of idx) {
    const t = only.length ? only[i] : i / fps;
    const ext = process.env.FRAME_EXT || 'png';
    const name = only.length ? `t${t.toFixed(2).padStart(5, '0')}.png` : `f${String(i).padStart(4, '0')}.${ext}`;
    const file = path.join(out, name);
    if (!only.length && fs.existsSync(file)) continue;
    await page.evaluate(t => window.render(t), t);
    await page.screenshot(file.endsWith('.jpg') ? { path: file, type: 'jpeg', quality: 95 } : { path: file });
  }
  await browser.close();
})();
