// Usage: node capture.js <fps> <outDir> [times...]  (sans temps : toute la durée)
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
(async () => {
  const fps = +process.argv[2], out = process.argv[3];
  const range = process.argv[4] && process.argv[4].includes('-') ? process.argv[4].split('-').map(Number) : null;
  const only = range ? [] : process.argv.slice(4).map(Number);
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  page.on('pageerror', e => console.error('PAGE ERROR', e.message));
  page.on('console', m => console.log('console:', m.text()));
  await page.goto('file://' + path.resolve(__dirname, 'reel.html'));
  await page.evaluate(async () => { await document.fonts.ready; await document.fonts.load('100px "Fredoka One"'); await document.fonts.load('800 30px Montserrat'); });
  const dur = await page.evaluate(() => window.DURATION);
  const times = only.length ? only : Array.from({ length: Math.round(dur * fps) }, (_, i) => i / fps);
  for (let i = range ? range[0] : 0; i < (range ? Math.min(range[1], times.length) : times.length); i++) {
    if (!only.length && fs.existsSync(path.join(out, `f${String(i).padStart(4, '0')}.png`))) continue;
    await page.evaluate(t => window.render(t), times[i]);
    const name = only.length ? `t${times[i].toFixed(2)}.png` : `f${String(i).padStart(4, '0')}.png`;
    await page.screenshot({ path: path.join(out, name) });
    if (i % 60 === 0) console.log('frame', i, '/', times.length);
  }
  await browser.close();
})();
