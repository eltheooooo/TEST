// DestinyLife — moteur commun des capsules : rendu déterministe image par image (window.render(t)).
// Chaque capsule déclare ses scènes et appelle les briques ci-dessous : fond, logo, en-tête,
// transitions (volets / whip), curseur de tap, confettis.
const W = 1080, H = 1920;
const $ = s => document.querySelector(s);
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const lerp = (a, b, p) => a + (b - a) * p;
const P = (t, a, b) => clamp((t - a) / (b - a));
const E = {
  outCubic: p => 1 - Math.pow(1 - p, 3),
  inCubic: p => p * p * p,
  inOutCubic: p => p < .5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2,
  outQuint: p => 1 - Math.pow(1 - p, 5),
  outExpo: p => p >= 1 ? 1 : 1 - Math.pow(2, -10 * p),
  inExpo: p => p <= 0 ? 0 : Math.pow(2, 10 * p - 10),
  outBack: (p, s = 1.9) => 1 + (s + 1) * Math.pow(p - 1, 3) + s * Math.pow(p - 1, 2),
  outElastic: p => p <= 0 ? 0 : p >= 1 ? 1 : Math.pow(2, -10 * p) * Math.sin((p * 10 - .75) * (2 * Math.PI) / 3) + 1,
  outBounce: p => { const n = 7.5625, d = 2.75;
    if (p < 1 / d) return n * p * p; if (p < 2 / d) return n * (p -= 1.5 / d) * p + .75;
    if (p < 2.5 / d) return n * (p -= 2.25 / d) * p + .9375; return n * (p -= 2.625 / d) * p + .984375; },
};
// Pseudo-aléatoire déterministe : chaque image est identique d'un rendu à l'autre.
function rng(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

// Place un élément par son centre (x, y) en pixels.
function tf(el, o = {}) {
  const { x = 540, y = 960, s = 1, r = 0, op = 1, b = 0 } = o;
  const k = +(el.dataset.fit || 1);
  const sx = (o.sx ?? s) * k, sy = (o.sy ?? s) * k;
  el.style.transform = `translate(${x}px,${y}px) translate(-50%,-50%) rotate(${r}deg) scale(${sx},${sy})`;
  el.style.opacity = op;
  el.style.filter = b > .1 ? `blur(${b}px)` : '';
}
const html = (parent, s) => { parent.insertAdjacentHTML('beforeend', s); return parent.lastElementChild; };
const fmt = n => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ');
const BRAND = ['#F5B942', '#EC4899', '#6D4AFF', '#19A9E8', '#10B981', '#EF4444', '#FDE68A', '#fff'];
const pop = (u, a, d = .3, s = 2.4) => { const q = P(u, a, a + d); return q > 0 ? E.outBack(q, s) : 0; };

// Texte qui change : on ne relance la mise en page que si le contenu change, et on réduit
// l'échelle (data-fit) pour tenir dans maxW.
function setText(el, text, maxW = 980) {
  if (el.dataset.txt === text) return;
  el.textContent = text; el.dataset.fit = 1;
  // Ne mémorise la mesure qu'une fois les polices chargées (sinon on mesurerait la police de secours).
  if (!document.fonts || document.fonts.status === 'loaded') el.dataset.txt = text;
  const w = el.scrollWidth; el.dataset.fit = w > maxW ? maxW / w : 1;
}

// ---------- Fond : dégradé bleu nuit, halos colorés, emojis qui flottent ----------
const HALOS = [[.15, .2, '#19A9E8'], [.9, .15, '#6D4AFF'], [.85, .85, '#EF4444'], [.1, .9, '#10B981']];
let haloEls = [], floaters = [];
function initBackground(emojis, seed = 7) {
  const root = $('#root');
  const halos = html(root, '<div class="abs" style="inset:0"></div>');
  haloEls = HALOS.map(h => html(halos, `<div class="halo" style="background:radial-gradient(circle,${h[2]} 0%,transparent 65%)"></div>`));
  html(root, '<div id="accent" class="c" style="width:1500px;height:1500px;border-radius:50%"></div>');
  html(root, '<div id="stripes" class="abs" style="inset:-200px;opacity:0;background:repeating-linear-gradient(-30deg,rgba(255,255,255,.07) 0 60px,transparent 60px 140px)"></div>');
  html(root, '<div id="rays" class="c" style="width:2600px;height:2600px;border-radius:50%;background:repeating-conic-gradient(from 0deg,rgba(253,230,138,.22) 0deg 7deg,transparent 7deg 18deg);-webkit-mask-image:radial-gradient(circle,#000 0%,rgba(0,0,0,.6) 25%,transparent 62%)"></div>');
  const fl = html(root, '<div class="abs" style="inset:0"></div>');
  const r = rng(seed);
  floaters = emojis.map((e, i) => ({ el: html(fl, `<div class="emo" style="font-size:${60 + r() * 60}px">${e}</div>`),
    x: (i + .5) / emojis.length * W + (r() - .5) * 60, y0: r() * (H + 300), sp: 60 + r() * 90, ph: r() * 6.28 }));
  // Le reste de la page (#cam et overlays) passe au-dessus du fond.
  ['#cam', '#overlay'].forEach(s => $(s) && root.appendChild($(s)));
}
function renderBackground(t, accent, raysOp = 0, raysY = 820, stripesOp = 0) {
  haloEls.forEach((el, i) => {
    const h = HALOS[i];
    el.style.transform = `translate(${h[0] * W - 550 + Math.sin(t * .6 + i) * 60}px,${h[1] * H - 550 + Math.cos(t * .5 + i * 2) * 80}px)`;
    el.style.opacity = (.45 + .15 * Math.sin(t * 1.3 + i)) * clamp(t / .4);
  });
  floaters.forEach(f => {
    const y = ((f.y0 - t * f.sp) % (H + 300) + H + 300) % (H + 300) - 150;
    tf(f.el, { x: f.x + Math.sin(t * 1.2 + f.ph) * 26, y, r: Math.sin(t + f.ph) * 14, op: .16 * clamp(t / .6) });
  });
  const acc = $('#accent');
  acc.style.background = `radial-gradient(circle,${accent} 0%,transparent 62%)`;
  tf(acc, { x: 540, y: 1050, s: 1 + .06 * Math.sin(t * 3), op: .34 });
  tf($('#rays'), { x: 540, y: raysY, r: t * 14, op: raysOp, s: .9 + .1 * Math.sin(t * 2) });
  const st = $('#stripes');
  st.style.opacity = stripesOp; st.style.transform = `translateX(${(t * 160) % 160}px)`;
}

// ---------- Logo DestinyLife lettre par lettre ----------
function buildLogo(el, size) {
  const word = (t, c) => [...t].map(ch => `<span class="L" style="display:inline-block;color:${c}">${ch}</span>`).join('');
  el.innerHTML = `<div class="title" style="position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);font-size:${size}px">${word('Destiny', '#fff')}${word('Life', '#F5B942')}</div>`;
  return [...el.querySelectorAll('.L')];
}
function renderLogoLetters(letters, u, start = .1, step = .03) {
  letters.forEach((L, i) => {
    const q = P(u, start + i * step, start + .33 + i * step);
    L.style.transform = `translateY(${(1 - E.outCubic(q)) * 110}px) scale(${Math.max(0, E.outBack(q, 2.6))}) rotate(${(1 - q) * (i % 2 ? 20 : -20)}deg)`;
    L.style.opacity = q > 0 ? 1 : 0;
  });
}

// ---------- Confettis ----------
const confetti = [];
function addConfetti(n, seed, t0, x0, y0, spread = 1) {
  const r = rng(seed), fx = $('#fx');
  for (let i = 0; i < n; i++) confetti.push({ el: html(fx, `<div class="conf" style="background:${BRAND[Math.floor(r() * BRAND.length)]};${r() < .3 ? 'border-radius:50%;height:20px;width:20px;' : ''}"></div>`),
    t0, x0, y0, vx: (r() - .5) * 2000 * spread, vy: -800 - r() * 1700, vr: (r() - .5) * 1400, wob: r() * 6 });
}
function renderConfetti(t) {
  confetti.forEach(c => {
    const dt = t - c.t0;
    if (dt < 0 || dt > 1.8) { c.el.style.opacity = 0; return; }
    const x = c.x0 + c.vx * dt * (1 - dt * .25), y = c.y0 + c.vy * dt + 1600 * dt * dt;
    tf(c.el, { x: x + Math.sin(dt * 8 + c.wob) * 20, y, r: c.vr * dt, sx: Math.cos(dt * 9 + c.wob), op: 1 - P(dt, 1.3, 1.8) });
  });
}

// ---------- Curseur de tap (doigt stylisé + onde) ----------
function initOverlay() {
  const ov = html($('#root'), '<div id="overlay" class="abs" style="inset:0;pointer-events:none"></div>');
  html(ov, `<div id="tap" class="c" style="width:120px;height:120px">
    <div id="tapRing" style="position:absolute;left:50%;top:50%;width:120px;height:120px;margin:-60px 0 0 -60px;border-radius:50%;border:8px solid #fff"></div>
    <div style="position:absolute;inset:0;border-radius:50%;background:rgba(255,255,255,.95);box-shadow:0 0 0 10px rgba(255,255,255,.35),0 16px 30px rgba(0,0,0,.4)"></div></div>`);
  for (let k = 0; k < 3; k++) html(ov, '<div class="wb c" style="width:2300px;height:2600px"></div>');
  html(ov, '<div id="flash" class="abs" style="inset:0;background:#fff;opacity:0"></div>');
  html(ov, '<div id="prog" class="abs" style="height:10px;background:linear-gradient(90deg,#F5B942,#EC4899,#6D4AFF,#19A9E8,#10B981)"></div>');
}
function renderTaps(t, taps) {
  const tapEl = $('#tap'); let shown = false;
  for (const [t0, x, y] of taps) {
    if (t < t0 - .3 || t > t0 + .45) continue;
    shown = true;
    const inp = E.outCubic(P(t, t0 - .3, t0 - .05)), outp = E.inCubic(P(t, t0 + .25, t0 + .45));
    const press = P(t, t0 - .04, t0) - P(t, t0 + .05, t0 + .15);
    tf(tapEl, { x: x + (1 - inp) * 220 + outp * 160, y: y + (1 - inp) * 260 + outp * 200, s: 1 - press * .25, op: Math.min(inp, 1 - outp) });
    const rp = P(t, t0, t0 + .4);
    $('#tapRing').style.transform = `scale(${1 + rp * 2.2})`;
    $('#tapRing').style.opacity = rp > 0 ? 1 - rp : 0;
  }
  if (!shown) tapEl.style.opacity = 0;
}
// Enfoncement d'un bouton 3D autour d'un tap à t0.
const pressAt = (t, t0) => P(t, t0 - .04, t0) - P(t, t0 + .08, t0 + .16);

// ---------- Volets de transition (bandes diagonales sur une coupe) ----------
function renderWipes(t, cuts) {
  const wbs = [...document.querySelectorAll('.wb')];
  const active = cuts.find(c => t > c[0] - .3 && t < c[0] + .3);
  wbs.forEach((el, k) => {
    if (!active) { el.style.opacity = 0; return; }
    const [c, col, dark] = active;
    el.style.background = [col, dark, '#10233F'][k];
    const p = E.inOutCubic(P(t, c + [-.06, -.03, 0][k] - .25, c + [-.06, -.03, 0][k] + .25));
    el.style.transform = `translate(${lerp(-3300, 2200, p)}px,-340px) skewX(-18deg)`;
    el.style.opacity = 1;
  });
}

// ---------- En-tête de scène (chip + titre sur 2 lignes) ----------
function renderHeader(u, chip, a, b, colB) {
  $('#hchip').innerHTML = chip;
  setText($('#ht1'), a); setText($('#ht2'), b); $('#ht2').style.color = colB;
  const cp = E.outExpo(P(u, 0, .3));
  tf($('#hchip'), { y: 250, x: lerp(-300, 540, cp), op: cp });
  const p1 = P(u, .03, .33), p2 = P(u, .1, .4);
  tf($('#ht1'), { y: 385, s: lerp(.3, 1, E.outBack(p1, 2.4)), op: p1 > 0 ? 1 : 0, r: lerp(-10, 0, E.outCubic(p1)) });
  tf($('#ht2'), { y: 518, s: lerp(.3, 1, E.outBack(p2, 2.4)) * (1 + .03 * Math.sin(u * 8)), op: p2 > 0 ? 1 : 0, r: lerp(10, -1.5, E.outCubic(p2)) });
}

// Caméra : entrée/sortie en « whip pan » (glissé rapide + flou) pour enchaîner les scènes.
function whip(u, dur, dir = 1) {
  const i = 1 - E.outExpo(P(u, 0, .28)), o = E.inExpo(P(u, dur - .2, dur));
  return { x: (i * 1150 - o * 1150) * dir, b: (i + o) * 22, s: 1 + u * .01 };
}
function applyCam(cam) {
  const c = $('#cam');
  c.style.transform = `translate(${cam.x || 0}px,${cam.y || 0}px) rotate(${cam.r || 0}deg) scale(${cam.s || 1})`;
  c.style.filter = (cam.b || 0) > .3 ? `blur(${cam.b}px)` : '';
}
