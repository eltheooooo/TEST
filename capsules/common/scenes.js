// DestinyLife — scènes réutilisables d'une capsule à l'autre (à charger après dl.js).
// Chaque fabrique construit son DOM dans la <section> donnée et renvoie une fonction de rendu
// (u = temps local de la scène, t = temps global) qui peut renvoyer { cam, kick, rays, raysY, accent }.
// Les coordonnées sont celles d'une vidéo 1080×1920 avec l'en-tête commun en haut (titre jusqu'à ~580 px).

const q$ = (root, s) => root.querySelector(s);

// ---------- Logo + badge « FOCUS … » ----------
function makeLogoScene(sec, { focus, focusBg }) {
  sec.innerHTML = `<div class="c emo k-crown" style="font-size:180px">👑</div><div class="c k-logo" style="width:1000px;height:200px"></div>
    <div class="c fd k-tag" style="font-size:66px;color:var(--goldSoft);white-space:nowrap;text-shadow:0 6px 0 var(--ink)">Chaque choix compte !</div>
    <div class="c sticker k-focus" style="background:${focusBg};color:#fff;font-size:52px;letter-spacing:4px">${focus}</div>`;
  const letters = buildLogo(q$(sec, '.k-logo'), 160);
  return u => {
    tf(q$(sec, '.k-crown'), { y: lerp(-200, 560, E.outBounce(P(u, .05, .55))), r: Math.sin(u * 5) * 8 });
    renderLogoLetters(letters, u, .15, .03);
    tf(q$(sec, '.k-logo'), { y: 780, s: 1 + .025 * Math.sin(u * 4) });
    const tp = E.outBack(P(u, .7, 1.0));
    tf(q$(sec, '.k-tag'), { y: lerp(960, 930, tp), s: lerp(.6, 1, tp), op: P(u, .7, .82) });
    const fp = P(u, .95, 1.25);
    tf(q$(sec, '.k-focus'), { y: 1110, s: fp > 0 ? lerp(2.2, 1, E.outExpo(fp)) : 0, r: lerp(-14, -4, fp), op: fp > 0 ? 1 : 0 });
    const out = E.inExpo(P(u, 1.7, 1.95)), kick = u > .95 ? Math.exp(-(u - .95) * 9) * .045 : 0;
    return { cam: { s: 1 + (1 - E.outCubic(P(u, 0, .5))) * .12 + kick + out * .5, r: out * 4 + Math.sin(u * 30) * kick * 25 }, rays: .9 * P(u, .1, .5) * (1 - P(u, 1.7, 1.95)), raysY: 780, accent: '#6D4AFF' };
  };
}

// ---------- Carton de chapitre (01 / 02 / 03) ----------
function makeChapter(sec, chapters) {
  sec.innerHTML = `<div class="c k-k" style="font:800 34px Montserrat;color:#fff;letter-spacing:16px;white-space:nowrap">CHAPITRE</div>
    <div class="c fd k-n" style="font-size:560px;line-height:1;white-space:nowrap"></div>
    <div class="c title k-t" style="font-size:150px"></div><div class="c chip k-s" style="letter-spacing:2px;font-size:34px"></div>`;
  const n = q$(sec, '.k-n'), K = q$(sec, '.k-k');
  return (i, u) => {
    const c = chapters[i];
    if (n.dataset.txt !== c.n) {
      n.dataset.txt = c.n; n.textContent = c.n; n.style.color = c.acc + '33'; n.style.webkitTextStroke = `12px ${c.acc}`;
      setText(q$(sec, '.k-t'), c.t); q$(sec, '.k-s').textContent = c.s;
    }
    const np = E.outExpo(P(u, 0, .32));
    tf(K, { y: 470, op: E.outCubic(P(u, .05, .3)) }); K.style.letterSpacing = lerp(40, 16, E.outCubic(P(u, 0, .4))) + 'px';
    tf(n, { y: 780, s: lerp(1.9, 1, np) * (1 + .02 * Math.sin(u * 7)), r: lerp(-14, -3, np), op: P(u, 0, .08), b: (1 - np) * 18 });
    tf(q$(sec, '.k-t'), { y: 1110, s: pop(u, .12, .3), op: u > .12 ? 1 : 0, r: -2 });
    tf(q$(sec, '.k-s'), { y: 1265, s: pop(u, .25, .3), op: u > .25 ? 1 : 0 });
    const o = E.inExpo(P(u, .82, 1.0)), kick = Math.exp(-u * 8) * .06;
    return { cam: { s: 1 + kick, x: -o * 1150, b: o * 22, r: Math.sin(u * 30) * kick * 20 }, accent: c.acc, stripes: 1 - P(u, .8, 1) };
  };
}

// ---------- Orientation de fin de 3ème (tap sur la voie pro) ----------
function makeOrientation(sec, { avg, subjects, tapT }) {
  sec.innerHTML = `<div class="c card k-card" style="width:900px;height:880px">
    <div class="bubble" style="position:absolute;left:40px;top:36px;width:110px;height:110px;background:#FEF3C7;font-size:64px">🎓</div>
    <div class="fd" style="position:absolute;left:174px;top:44px;font-size:56px;color:var(--navy)">Orientation</div>
    <div style="position:absolute;left:176px;top:112px;font:700 26px Montserrat;color:var(--inkMute)">Bulletin de 3ème</div>
    <div style="position:absolute;right:44px;top:34px;text-align:right"><div style="font:800 22px Montserrat;color:var(--inkMute);letter-spacing:3px">MOYENNE</div><div class="fd" style="font-size:68px;color:var(--greenDark)"><span class="k-avg">0</span><span style="font-size:36px;color:var(--inkMute)">/20</span></div></div>
    <div style="position:absolute;left:40px;top:176px;display:flex;gap:12px">${subjects.map(s => `<div class="pill neutral" style="font-size:24px;padding:10px 20px">${s}</div>`).join('')}</div>
    <div class="btn3d opt k-o" style="top:270px"><div class="lip" style="background:#047857"></div><div class="face" style="background:linear-gradient(120deg,#34D399,#10B981)"><div class="ob">✅</div><div><div class="ot">Voie générale</div><div class="os">Lycée général → études supérieures</div></div></div></div>
    <div class="btn3d opt k-o" style="top:465px"><div class="lip" style="background:#0E7AC4"></div><div class="face" style="background:linear-gradient(120deg,#38BDF8,#19A9E8)"><div class="ob">🔧</div><div><div class="ot">Voie technologique</div><div class="os">8 filières STxx → métier ou études</div></div></div></div>
    <div class="btn3d opt k-o" style="top:660px"><div class="lip" style="background:#C2410C"></div><div class="face" style="background:linear-gradient(120deg,#FB923C,#F97316)"><div class="ob">🛠️</div><div><div class="ot">Voie professionnelle</div><div class="os">11 CAP → travail direct</div></div><div class="shine k-sh"></div></div></div></div>`;
  const opts = [...sec.querySelectorAll('.k-o')];
  return (u, t) => {
    const cp = E.outBack(P(u, .02, .32), 1.5);
    tf(q$(sec, '.k-card'), { y: 1090, s: lerp(.85, 1, cp), op: P(u, .02, .1) });
    q$(sec, '.k-avg').textContent = (avg * E.outCubic(P(u, .15, .6))).toFixed(1).replace('.', ',');
    opts.forEach((el, k) => {
      const q = E.outBack(P(u, .22 + k * .08, .5 + k * .08), 2), dim = k < 2 ? P(u, 1.0, 1.15) : 0;
      el.style.transform = `translateX(${(1 - q) * (k % 2 ? 900 : -900)}px) scale(${k === 2 ? 1 + .03 * P(u, 1.0, 1.1) : 1})`;
      el.style.opacity = 1 - dim * .65;
      q$(el, '.face').style.transform = `translateY(${-12 + (k === 2 ? pressAt(t, tapT) * 10 : 0)}px)`;
    });
    q$(sec, '.k-sh').style.left = lerp(-200, 1000, P(u, .6, .9)) + 'px';
  };
}
const ORIENTATION_TAP = [790, 1392];

// ---------- Liste des 11 CAP (GameData.CAP_FILIERES) ----------
const CAP_LIST = [['aepe', '🧸', 'CAP AEPE', 'Petite enfance', 1500, '#FEF3C7'], ['commerce', '🛒', 'CAP Commerce', 'Équipier magasin', 1400, '#E0F2FE'],
  ['cuisine', '🍳', 'CAP Cuisine', 'Cuisinier', 1600, '#FFEDD5'], ['patissier', '🧁', 'CAP Pâtissier', 'Pâtisserie', 1500, '#FCE7F3'],
  ['electricien', '⚡', 'CAP Électricien', 'Installations élec.', 1800, '#FEF9C3'], ['meca', '🔧', 'CAP Méca Auto', 'Mécanique auto', 1700, '#E0F2FE'],
  ['coiffure', '✂️', 'CAP Coiffure', 'Coiffure', 1400, '#FCE7F3'], ['esthetique', '💅', 'CAP Esthétique', 'Esthétique', 1500, '#FAE8FF'],
  ['boulanger', '🥖', 'CAP Boulanger', 'Boulangerie', 1500, '#FEF3C7'], ['menuisier', '🪚', 'CAP Menuisier', 'Travail du bois', 1700, '#FFEDD5'],
  ['plombier', '🚰', 'CAP Plombier', 'Plomberie', 1700, '#E0F2FE']];
function makeCapList(sec, { pick, pickDesc, color, okText, tapT }) {
  sec.innerHTML = `<div class="c card k-card" style="width:900px;height:940px">
    <div class="bubble" style="position:absolute;left:40px;top:34px;width:100px;height:100px;background:#FFEDD5;font-size:58px">🛠️</div>
    <div class="fd" style="position:absolute;left:164px;top:38px;font-size:52px;color:var(--navy)">CAP · voie pro</div>
    <div style="position:absolute;left:166px;top:100px;font:700 24px Montserrat;color:var(--inkMute)">Formation métier en 2 ans, très pratique</div>
    <div style="position:absolute;left:30px;right:30px;top:160px;height:750px;border-radius:36px;background:var(--sheet);overflow:hidden">
      <div class="k-list" style="position:absolute;left:0;right:0;top:0"></div>
      <div style="position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,#F4F7FC 0%,rgba(244,247,252,0) 9%,rgba(244,247,252,0) 91%,#F4F7FC 100%)"></div>
    </div></div><div class="c sticker gold k-ok" style="font-size:46px">${okText}</div>`;
  const pi = CAP_LIST.findIndex(c => c[0] === pick);
  const rows = CAP_LIST.map((c, i) => html(q$(sec, '.k-list'), `<div class="caprow" style="top:${13 + i * 140}px"><div class="cb" style="background:${c[5]}">${c[1]}</div><div><div class="cl">${c[2]}</div><div class="cd">${i === pi && pickDesc ? pickDesc : c[3]}</div></div><div class="pill good">~${fmt(c[4])} €</div></div>`));
  const target = 375 - (13 + pi * 140 + 62); // ligne choisie centrée dans la fenêtre
  return (u, t) => {
    const cp = E.outBack(P(u, .02, .32), 1.5);
    tf(q$(sec, '.k-card'), { y: 1120, s: lerp(.85, 1, cp), op: P(u, .02, .1) });
    const down = E.inOutCubic(P(u, .25, .85)), back = E.outBack(P(u, .88, 1.22), 1.6);
    const y = lerp(lerp(0, -806, down), target, back);
    const vel = Math.abs(lerp(0, -806, E.inOutCubic(P(u + .01, .25, .85))) - lerp(0, -806, down));
    const L = q$(sec, '.k-list');
    L.style.transform = `translateY(${y}px)`; L.style.filter = vel > 2 ? `blur(${Math.min(8, vel)}px)` : '';
    rows.forEach((r, i) => { if (i !== pi) r.style.opacity = 1 - .5 * P(u, 1.25, 1.4); });
    const hl = P(u, 1.2, 1.32), row = rows[pi];
    row.style.transform = `scale(${1 + .04 * hl - .03 * pressAt(t, tapT)})`;
    row.style.boxShadow = `0 6px 0 #E3E9F2,0 0 0 ${7 * hl}px ${color},0 ${20 * hl}px ${40 * hl}px ${color}59`;
    const q = P(u, 1.5, 1.75);
    tf(q$(sec, '.k-ok'), { y: 1580, s: q > 0 ? E.outBack(q, 3) : 0, r: -4 + (1 - q) * 20, op: q > 0 ? 1 : 0 });
  };
}
const CAPLIST_TAP = [770, 1185];

// ---------- 2 ans de formation + diplôme tamponné ----------
function makeDiploma(sec, { cap, name, avg, nodes, stampT }) {
  sec.innerHTML = `<div class="c glasscard k-time" style="width:940px;height:240px;border-radius:48px">
      <div style="position:absolute;left:150px;right:150px;top:88px;height:14px;border-radius:7px;background:rgba(255,255,255,.18)"><i class="k-fill" style="display:block;height:100%;width:0;border-radius:7px;background:linear-gradient(90deg,#FDE68A,#F97316)"></i></div></div>
    <div class="c k-dip" style="width:860px;height:560px;border-radius:44px;background:#FFFBEB;box-shadow:0 16px 0 #D6B97A,0 50px 90px rgba(3,8,25,.5)">
      <div style="position:absolute;inset:22px;border:5px dashed #F5B942;border-radius:30px"></div>
      <div style="position:absolute;left:0;right:0;top:62px;text-align:center;font:800 26px Montserrat;color:#B45309;letter-spacing:10px">📜 DIPLÔME</div>
      <div class="fd" style="position:absolute;left:0;right:0;top:112px;text-align:center;font-size:84px;color:var(--navy)">${cap}</div>
      <div style="position:absolute;left:0;right:0;top:220px;text-align:center;font:700 34px Montserrat;color:var(--inkSoft)">${name}</div>
      <div class="fd" style="position:absolute;left:0;right:0;top:285px;text-align:center;font-size:62px;color:var(--greenDark)">Moyenne : <span class="k-avg">0</span>/20</div>
      <div class="bubble" style="position:absolute;left:58px;bottom:46px;width:150px;height:150px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#FDE68A,#F5B942 55%,#B45309);box-shadow:0 8px 0 #92400E;font-size:76px">🏅</div></div>
    <div class="c fd k-stamp" style="font-size:120px;color:#059669;border:12px solid #059669;border-radius:28px;padding:0 34px;line-height:1.15;background:rgba(220,252,231,.55)">ADMIS</div>
    <div class="c sticker good k-g0" style="font-size:40px">😊 Bonheur +25</div>
    <div class="c sticker purple k-g1" style="font-size:40px">💞 Relation parents +15</div>`;
  const tl = q$(sec, '.k-time');
  const nodeEls = nodes.map((n, i) => {
    const c = html(tl, `<div style="position:absolute;left:${100 + i * 320}px;top:45px;width:100px;height:100px;border-radius:50%;background:#10233F;border:6px solid rgba(255,255,255,.3);display:flex;align-items:center;justify-content:center;font-size:52px">${n[0]}</div>`);
    html(tl, `<div style="position:absolute;left:${-10 + i * 320}px;width:320px;top:162px;text-align:center;font:700 26px Montserrat;color:#fff">${n[1]}</div>`);
    return c;
  });
  return (u, t) => {
    tf(tl, { y: 720, s: lerp(.85, 1, E.outBack(P(u, 0, .3), 1.4)), op: P(u, 0, .08) });
    const fp = E.inOutCubic(P(u, .15, .7));
    q$(sec, '.k-fill').style.width = (fp * 100) + '%';
    nodeEls.forEach((n, i) => { const on = P(fp, i / 2 - .02, i / 2 + .04); n.style.background = on > .5 ? '#F97316' : '#10233F'; n.style.transform = `scale(${1 + .25 * Math.sin(on * Math.PI)})`; });
    const dp = E.outBack(P(u, .6, .9), 1.6);
    tf(q$(sec, '.k-dip'), { y: 1210, s: lerp(.5, 1, dp), r: lerp(-10, -1.5, dp), op: P(u, .6, .68) });
    q$(sec, '.k-avg').textContent = Math.round(avg * E.outCubic(P(u, .75, 1.05)));
    const sq = P(u, (stampT - t + u) - .12, stampT - t + u);
    tf(q$(sec, '.k-stamp'), { x: 740, y: 1390, s: lerp(3, 1, E.inCubic(sq)), r: -14, op: sq > 0 ? 1 : 0 });
    [['.k-g0', 290, 1640, -4], ['.k-g1', 760, 1645, 4]].forEach(([s, x, y, r], k) => { const q = pop(u, 1.25 + k * .08, .28, 2.8); tf(q$(sec, s), { x, y, s: q, r, op: q > 0 ? 1 : 0 }); });
    return { kick: t > stampT ? Math.exp(-(t - stampT) * 9) * .05 : 0, rays: .8 * P(u, 1.05, 1.3), raysY: 1300 };
  };
}

// ---------- Pôle Emploi : offres puis « Nouveau job ! » ----------
function makeJobBoard(sec, { intro, offers, pick, tapT, hired, salary }) {
  const big = offers.length <= 3;
  sec.innerHTML = `<div class="c glasscard k-msg" style="width:940px;height:150px;border-radius:44px;display:flex;align-items:center;gap:24px;padding:0 30px">
      <div class="bubble" style="width:96px;height:96px;background:linear-gradient(150deg,#818CF8,#4F46E5);font-size:54px;flex:none">💼</div>
      <div><div style="font:800 24px Montserrat;color:var(--goldSoft);letter-spacing:4px">PÔLE EMPLOI</div><div style="font:700 30px Montserrat;color:#fff;margin-top:6px">${intro}</div></div></div>
    <div class="k-rows"></div>
    <div class="c pill glass k-load" style="font-size:30px"><span class="k-spin" style="display:inline-block;width:34px;height:34px;border-radius:50%;border:6px solid rgba(255,255,255,.25);border-top-color:#F5B942"></span>Candidature envoyée…</div>
    <div class="abs k-dim" style="inset:0;background:rgba(7,18,36,.6)"></div>
    <div class="c card k-modal" style="width:880px;height:560px;overflow:hidden">
      <div style="position:absolute;left:0;right:0;top:0;height:190px;background:linear-gradient(120deg,#34D399,#047857)"></div>
      <div class="bubble" style="position:absolute;left:44px;top:40px;width:112px;height:112px;background:rgba(255,255,255,.22);font-size:64px">💼</div>
      <div class="fd" style="position:absolute;left:182px;top:56px;font-size:72px;color:#fff;text-shadow:0 5px 0 rgba(0,0,0,.15)">Nouveau job !</div>
      <div style="position:absolute;left:48px;right:48px;top:224px;font:600 32px/1.42 Montserrat;color:var(--navy)">${hired}</div>
      <div style="position:absolute;left:48px;top:420px;display:flex;gap:16px"><div class="pill good" style="font-size:28px">😊 Bonheur +10</div><div class="pill special" style="font-size:28px">💰 ${fmt(salary)} €/mois</div></div></div>`;
  const H = big ? 200 : 112, PITCH = big ? 230 : 124, Y0 = big ? 880 : 832;
  const rows = offers.map(o => html(q$(sec, '.k-rows'), `<div class="offer${big ? ' big' : ''}" style="height:${H}px"><div class="ob" style="background:${o[5] || '#FCE7F3'}">${o[0]}</div><div><div class="on">${o[1]}</div><div class="os">${o[2]}</div>${big && o[4] ? `<div class="oa">« ${o[4]} »</div>` : ''}</div><div class="pill good">${fmt(o[3])} €</div></div>`));
  const tap = [820, Y0 + pick * PITCH];
  const render = (u, t) => {
    tf(q$(sec, '.k-msg'), { y: 680, s: pop(u, .02, .3, 1.8), op: u > .02 ? 1 : 0 });
    rows.forEach((el, i) => {
      const q = E.outBack(P(u, .15 + i * .09, .45 + i * .09), 1.6), sel = i === pick, hl = P(u, .95, 1.05);
      el.style.transform = `translate(${70 + (1 - q) * 1100}px,${Y0 + i * PITCH - H / 2}px) scale(${sel ? 1 + .04 * hl - .03 * pressAt(t, tapT) : 1})`;
      el.style.opacity = sel ? 1 : 1 - .6 * P(u, 1.0, 1.15);
      if (sel) el.style.boxShadow = `0 8px 0 #9FB0CF,0 0 0 ${7 * hl}px #F5B942,0 20px 40px rgba(0,0,0,.25)`;
    });
    const lp = P(u, 1.05, 1.15) * (1 - P(u, 1.38, 1.45));
    tf(q$(sec, '.k-load'), { y: 1640, s: lp, op: lp });
    q$(sec, '.k-spin').style.transform = `rotate(${u * 900}deg)`;
    q$(sec, '.k-dim').style.opacity = P(u, 1.38, 1.5);
    const mp = P(u, 1.4, 1.7);
    tf(q$(sec, '.k-modal'), { y: 1110, s: mp > 0 ? E.outBack(mp, 2.2) : 0, r: lerp(-8, 0, E.outCubic(mp)), op: mp > 0 ? 1 : 0 });
    return { rays: .7 * P(u, 1.4, 1.7), raysY: 1110 };
  };
  render.tap = tap;
  return render;
}

// ---------- Années de travail : pile d'événements + salaire qui grimpe ----------
// value0/fmtValue/perLabel/plusFmt permettent d'afficher autre chose qu'un salaire (ex. relation famille).
function makeCareerStack(sec, { job, salary0, events, value0 = salary0, fmtValue = v => fmt(v) + ' €', perLabel = 'par mois', plusFmt = d => `▲ +${d} €/mois` }) {
  sec.innerHTML = `<div class="c card k-job" style="width:940px;height:210px">
      <div class="bubble" style="position:absolute;left:34px;top:46px;width:116px;height:116px;background:${job.bg};font-size:66px">${job.emoji}</div>
      <div class="fd" style="position:absolute;left:174px;top:50px;font-size:42px;color:var(--navy)">${job.name}</div>
      <div style="position:absolute;left:176px;top:110px;font:700 24px Montserrat;color:var(--inkMute)">${job.sub}</div>
      <div class="fd k-sal" style="position:absolute;right:40px;top:40px;font-size:66px;color:var(--greenDark)"></div>
      <div class="k-per" style="position:absolute;right:40px;top:122px;font:700 24px Montserrat;color:var(--inkMute)">${perLabel}</div></div>
    <div class="k-evs"></div>`;
  const evEls = events.map(e => html(q$(sec, '.k-evs'), `<div class="ev"><div class="eb" style="background:${e[2]}">${e[1]}</div><div style="min-width:0"><div class="et">${e[3]}</div><div class="es">${e[4]}</div></div><div class="pill ${e[6]}">${e[5]}</div></div>`));
  return u => {
    const jp = E.outBack(P(u, 0, .28), 1.5);
    let sal = value0, plus = null;
    events.forEach(e => { if (e[7]) { sal += e[7] * E.outCubic(P(u, e[0] + .1, e[0] + .4)); if (u > e[0] + .05 && u < e[0] + .7) plus = [e[7], u - e[0] - .05]; } });
    const salEl = q$(sec, '.k-sal'), per = q$(sec, '.k-per');
    salEl.textContent = fmtValue(sal);
    salEl.style.transform = `scale(${1 + (plus ? Math.exp(-plus[1] * 7) * .25 : 0)})`; salEl.style.transformOrigin = '100% 50%';
    per.textContent = plus ? plusFmt(plus[0]) : perLabel;
    per.style.color = plus ? '#059669' : '';
    tf(q$(sec, '.k-job'), { y: 720, s: lerp(.85, 1, jp) * (1 + (plus ? Math.exp(-plus[1] * 6) * .05 : 0)), op: P(u, 0, .08) });
    evEls.forEach((el, k) => {
      const q = P(u, events[k][0], events[k][0] + .3);
      let idx = 0;
      for (let j = k + 1; j < events.length; j++) idx += E.outCubic(P(u, events[j][0], events[j][0] + .25));
      el.style.transform = `translate(${80 + (1 - E.outCubic(q)) * 500}px,${935 + idx * 152 - 68}px) scale(${q > 0 ? E.outBack(q, 2.2) : 0}) rotate(${(1 - q) * 8}deg)`;
      el.style.opacity = q > 0 ? 1 - .3 * clamp(idx - 2) : 0;
    });
  };
}

// ---------- CTA final ----------
function makeCTA(sec, { tag, tagBg, tapT }) {
  sec.innerHTML = `<div class="c sticker k-tag" style="background:${tagBg};color:#fff;font-size:36px;letter-spacing:4px;padding:14px 32px">${tag}</div>
    <div class="c emo k-crown" style="font-size:150px">👑</div><div class="c k-logo" style="width:1000px;height:200px"></div>
    <div class="c title k-q1" style="font-size:96px;-webkit-text-stroke-width:12px">Quel sera</div>
    <div class="c title k-q2" style="font-size:96px;color:var(--gold);-webkit-text-stroke-width:12px">ton destin ?</div>
    <div class="c k-glow" style="width:760px;height:250px;border-radius:80px;background:rgba(110,231,183,.55);filter:blur(40px)"></div>
    <div class="btn3d c k-btn" style="width:740px;height:220px;border-radius:70px"><div class="lip" style="background:#065F46"></div>
      <div class="face" style="background:linear-gradient(170deg,#6EE7B7,#10B981 55%,#059669)"><div class="fd" style="font-size:112px;color:#fff;-webkit-text-stroke:8px #065F46;paint-order:stroke fill;letter-spacing:2px">▶ JOUER</div><div class="shine k-shine" style="width:160px"></div></div></div>
    <div class="c k-free" style="font:800 34px Montserrat;color:var(--onDarkSoft);letter-spacing:6px;white-space:nowrap">GRATUIT SUR ROBLOX</div>
    <div class="c k-search" style="width:720px;height:120px;border-radius:60px;background:#fff;box-shadow:0 12px 0 #9FB0CF,0 30px 60px rgba(0,0,0,.35);display:flex;align-items:center;padding:0 40px;gap:22px">
      <span style="font-size:52px">🔍</span><span class="fd k-type" style="font-size:56px;color:var(--navy)"></span><span class="k-caret" style="width:6px;height:60px;background:var(--purple);border-radius:3px;display:inline-block"></span></div>`;
  const letters = buildLogo(q$(sec, '.k-logo'), 150);
  const render = (u, t) => {
    tf(q$(sec, '.k-tag'), { y: 250, s: pop(u, .5, .3, 2.6), r: -3, op: u > .5 ? 1 : 0 });
    tf(q$(sec, '.k-crown'), { y: lerp(-150, 420, E.outBounce(P(u, 0, .45))), r: Math.sin(u * 4) * 8 });
    renderLogoLetters(letters, u, .05, .025);
    tf(q$(sec, '.k-logo'), { y: 600, s: 1 + .02 * Math.sin(u * 4) });
    const a = E.outBack(P(u, .35, .6), 2.2), b = E.outBack(P(u, .42, .67), 2.2);
    tf(q$(sec, '.k-q1'), { y: 790, s: a, op: a > 0 ? 1 : 0, r: -2 });
    tf(q$(sec, '.k-q2'), { y: 900, s: b, op: b > 0 ? 1 : 0, r: 2 });
    const bp = P(u, .55, 1.0), beat = 1 + .035 * Math.max(0, Math.sin((u - 1) * Math.PI * 4)) * P(u, 1.6, 1.8);
    tf(q$(sec, '.k-btn'), { y: 1150, s: E.outElastic(bp) * beat, op: bp > 0 ? 1 : 0 });
    q$(sec, '.k-btn .face').style.transform = `translateY(${-18 + pressAt(t, tapT) * 16}px)`;
    tf(q$(sec, '.k-glow'), { y: 1160, s: (1.05 + .12 * Math.sin(u * 6)) * E.outCubic(bp), op: .9 * bp });
    q$(sec, '.k-shine').style.left = lerp(-260, 900, ((u - .9) % 1.1) / .6) + 'px';
    tf(q$(sec, '.k-free'), { y: 1330, op: E.outCubic(P(u, .9, 1.15)) });
    const sq = E.outBack(P(u, 1.0, 1.3), 1.8);
    tf(q$(sec, '.k-search'), { y: 1450, s: sq, op: sq > 0 ? 1 : 0 });
    const txt = 'Destiny Life';
    q$(sec, '.k-type').textContent = txt.slice(0, Math.floor(txt.length * P(u, 1.4, 2.0)));
    q$(sec, '.k-caret').style.opacity = (Math.floor(u * 3) % 2 === 0 || u < 2.0) ? 1 : 0;
    const kick = t > tapT ? Math.exp(-(t - tapT) * 8) * .05 : 0;
    return { cam: { s: 1 + u * .012 + kick, r: Math.sin(u * 20) * kick * 20 }, accent: '#10B981', rays: .9 * P(u, .05, .4), raysY: 640 };
  };
  render.tap = [820, 1180];
  return render;
}

// ---------- Montage : scènes, en-têtes, caméra, volets ----------
// scenes : [{ id, a, b, fn(u, t), act?, t1?, t2? }] ; acts : [{ chip, col, acc }] ; cuts : [[t, couleur, foncée]]
function makeMontage({ END, scenes, acts, cuts, taps, flash }) {
  return t => {
    document.querySelectorAll('.scene').forEach(s => s.style.display = 'none');
    $('#head').style.display = 'none';
    let cam = { s: 1 }, accent = '#EC4899', rays = 0, raysY = 820, stripes = 0;
    for (const sc of scenes.filter(s => t >= s.a && t < s.b)) {
      const u = t - sc.a;
      $('#' + sc.id).style.display = 'block';
      const r = sc.fn(u, t) || {};
      if (sc.act !== undefined) {
        const A = acts[sc.act];
        $('#head').style.display = 'block';
        renderHeader(u, A.chip, sc.t1, sc.t2, A.col);
        accent = A.acc;
        cam = whip(u, sc.b - sc.a);
        if (r.kick) { cam.s += r.kick; cam.r = Math.sin(u * 30) * r.kick * 25; }
      } else if (r.cam) cam = r.cam;
      if (r.accent) accent = r.accent;
      if (r.rays !== undefined) { rays = r.rays; raysY = r.raysY ?? raysY; }
      if (r.stripes !== undefined) stripes = r.stripes;
    }
    renderBackground(t, accent, rays, raysY, stripes);
    applyCam(cam);
    renderConfetti(t);
    renderTaps(t, taps);
    renderWipes(t, cuts);
    $('#prog').style.width = (t / END * W) + 'px';
    if (flash) $('#flash').style.opacity = .7 * P(t, flash - .08, flash) * (1 - P(t, flash, flash + .32));
  };
}
