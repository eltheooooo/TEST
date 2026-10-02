"""DestinyLife — synthé de sound design commun aux capsules (numpy uniquement).

Chaque capsule importe ce module, place ses sons sur la timeline de la vidéo puis appelle
`Mix.render(...)`. Tout est synthétisé : pas de droits musicaux à gérer.
"""
import wave
import numpy as np

SR = 48000
_rs = np.random.RandomState(4)


def tt(d): return np.arange(int(d * SR)) / SR
def noise(d): return _rs.uniform(-1, 1, int(d * SR))
def note(m): return 440 * 2 ** ((m - 69) / 12)


def lp(x, fc):
    """Passe-bas 1 pôle (fc scalaire ou tableau de même longueur que x)."""
    fc = np.broadcast_to(fc, x.shape)
    a = 1 - np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x); s = 0.0
    for i in range(len(x)):
        s += a[i] * (x[i] - s); y[i] = s
    return y


def hp(x, fc): return x - lp(x, fc)
def _sweep(f): return np.sin(2 * np.pi * np.cumsum(f) / SR)


# ---------- Percussions ----------
def kick(g=1.0):
    t = tt(.45)
    return _sweep(45 + 110 * np.exp(-t * 28)) * np.exp(-t * 7) * g + lp(noise(.45), 3000) * np.exp(-t * 90) * .3
def boom():
    t = tt(1.4)
    return np.tanh(1.8 * _sweep(32 + 90 * np.exp(-t * 9))) * np.exp(-t * 2.6)
def clap():
    t = tt(.3); n = hp(noise(.3), 900)
    env = np.exp(-t * 22) + .6 * np.exp(-np.maximum(t - .012, 0) * 30) * (t > .012) + .4 * np.exp(-np.maximum(t - .024, 0) * 26) * (t > .024)
    return n * env * .55
def hat(): t = tt(.08); return hp(noise(.08), 7000) * np.exp(-t * 60) * .5
def crash(d=2.2): t = tt(d); return hp(noise(d), 4500) * np.exp(-t * 2.2) * .5
def thud():  # tampon / coup sourd
    t = tt(.5)
    return (np.tanh(2.5 * _sweep(60 + 140 * np.exp(-t * 30))) * np.exp(-t * 12) + lp(noise(.5), 1200) * np.exp(-t * 30) * .8) * .9


# ---------- Mouvements ----------
def whoosh(d=.6, up=True):
    t = tt(d); x = t / d
    fc = (300 + 5200 * x ** 1.5) if up else (5500 - 5000 * x)
    return lp(noise(d), fc) * np.sin(np.pi * x) ** 2 * 2.2
def riser(d):
    t = tt(d); x = t / d
    return lp(noise(d), 400 + 7000 * x ** 2) * x ** 2 * 1.6 + _sweep(200 + 900 * x ** 2) * x ** 3 * .25
def pop(f0=900, d=.12):
    t = tt(d); return _sweep(f0 * (1 + 1.2 * np.exp(-t * 60))) * np.exp(-t * 35) * .6
def tick(f=2400): t = tt(.03); return np.sin(2 * np.pi * f * t) * np.exp(-t * 180) * .35
def click():
    t = tt(.06); return (hp(noise(.06), 2000) * np.exp(-t * 120) + np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 90)) * .6
def snip():  # coup de ciseaux : deux lames qui claquent
    out = np.zeros(int(.16 * SR))
    for k, d in enumerate((0, .055)):
        t = tt(.08); s = hp(noise(.08), 3500) * np.exp(-t * 90) + np.sin(2 * np.pi * (5200 - k * 900) * t) * np.exp(-t * 70) * .5
        i = int(d * SR); out[i:i + len(s)] += s
    return out * .7
def shing(d=1.0):  # entaille métallique
    t = tt(d)
    ring = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * k) for f, k in ((2950, 5), (4410, 7), (6120, 9)))
    return (ring * .25 + hp(noise(d), 6000) * np.exp(-t * 14) * .6) * np.minimum(1, t * 400)
def buzz(d=.25):  # néon
    t = tt(d); w = np.sign(np.sin(2 * np.pi * 100 * t)) * .5 + np.sin(2 * np.pi * 50 * t) * .5
    return lp(w, 2500) * .25 * np.minimum(1, t * 60) * np.minimum(1, (d - t) * 60)


# ---------- Mélodique ----------
def bell(f, d=1.2):
    t = tt(d)
    return (np.sin(2 * np.pi * f * t) + .5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 4)
            + .25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 9)) * np.exp(-t * 3.2) * .35
def chime(notes, gap=.06, d=1.2, g=1.0):
    out = np.zeros(int((d + gap * len(notes)) * SR))
    for k, m in enumerate(notes):
        b = bell(note(m), d); i = int(k * gap * SR); out[i:i + len(b)] += b
    return out * g
def coin():
    c = chime([88, 95], gap=.07, d=.7)
    c[:int(.25 * SR)] += hp(noise(.25), 5000) * np.exp(-tt(.25) * 20) * .3
    return c
def pluck(f, d=.35):
    t = tt(d); w = 2 * (t * f % 1) - 1
    return lp(w, 800 + 4000 * np.exp(-t * 18)) * np.exp(-t * 9) * .25
def bass(f, d=.5):
    t = tt(d)
    w = np.sin(2 * np.pi * f * t) + .35 * np.sin(4 * np.pi * f * t) + .15 * (2 * (t * f % 1) - 1)
    return w * np.minimum(1, t * 200) * np.exp(-t * 3) * .5
def pad(fs, d):
    t = tt(d)
    s = sum(np.sin(2 * np.pi * f * t + k) + .4 * np.sin(2 * np.pi * f * 1.003 * t) for k, f in enumerate(fs))
    return s * np.minimum(1, t / .3) * np.minimum(1, (d - t) / .5) * .07


CHORDS = {'C': [60, 64, 67, 72], 'G': [55, 59, 62, 67], 'Am': [57, 60, 64, 69], 'F': [53, 57, 60, 65], 'Dm': [50, 57, 62, 65], 'Em': [52, 59, 64, 67]}
ROOTS = {'C': 36, 'G': 31, 'Am': 33, 'F': 29, 'Dm': 38, 'Em': 28}


class Mix:
    def __init__(self, dur):
        self.dur = dur; self.N = int(SR * dur)
        self.fx = np.zeros((self.N, 2)); self.music = np.zeros((self.N, 2)); self.kicks = []

    def place(self, t, sig, gain=1.0, pan=0.0, bus='fx'):
        buf = self.music if bus == 'music' else self.fx
        i = int(t * SR)
        if i >= self.N: return
        if i < 0: sig = sig[-i:]; i = 0
        sig = sig[: self.N - i]
        l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        buf[i:i + len(sig), 0] += sig * gain * l * 1.414
        buf[i:i + len(sig), 1] += sig * gain * r * 1.414

    def groove(self, start, end, chord_at, hats_from=None, drop=()):
        """Kick à 120 BPM, basse, clap, charley et arpège ; `drop` = intervalles sans charley/arpège."""
        b = start
        while b < end - 1e-6:
            beat = round((b - start) * 2)
            self.place(b, kick(), .9); self.kicks.append(b)
            c = chord_at(b)
            dropped = any(a <= b < z for a, z in drop)
            if hats_from is not None and b >= hats_from and not dropped:
                self.place(b + .25, hat(), .8, .3, 'music')
                if beat % 2 == 1: self.place(b, clap(), .7, -.1, 'music')
                for k in range(4):
                    m = CHORDS[c][(beat * 4 + k) % 4] + (12 if k == 3 else 0)
                    self.place(b + k * .125, pluck(note(m)), .9, (-.4 if k % 2 else .4), 'music')
            self.place(b, bass(note(ROOTS[c]), .45), 1.0, 0, 'music')
            self.place(b + .25, bass(note(ROOTS[c] + 12), .22), .5, 0, 'music')
            b += .5

    def render(self, path, fade_from):
        duck = np.ones(self.N)
        for b in self.kicks:
            i = int(b * SR); L = min(int(.25 * SR), self.N - i)
            if L > 0: duck[i:i + L] = np.minimum(duck[i:i + L], 1 - .55 * np.exp(-np.arange(L) / SR * 14))
        out = self.fx + self.music * duck[:, None] * 1.1
        fade = np.ones(self.N); fs = int(fade_from * SR); fade[fs:] = np.linspace(1, 0, self.N - fs) ** 1.5
        out *= fade[:, None]
        out = np.tanh(out / np.max(np.abs(out)) * 1.6) / np.tanh(1.6) * .89
        w = wave.open(path, 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((out * 32767).astype('<i2').tobytes()); w.close()


# ---------- Atelier / voitures ----------
def engine(d=.5, f0=55, f1=110, g=1.0):
    """Moteur qui monte en régime (dent de scie filtrée + grondement)."""
    t = tt(d); x = t / d
    f = f0 + (f1 - f0) * np.sin(np.pi * x * .5) ** 2
    ph = np.cumsum(f) / SR
    saw = 2 * (ph % 1) - 1
    s = lp(saw + .5 * np.sign(np.sin(2 * np.pi * ph * .5)), 900 + 2500 * x) + lp(noise(d), 300) * .4
    return np.tanh(1.5 * s) * np.sin(np.pi * x) ** .6 * .5 * g
def ratchet(n=8, gap=.028):
    out = np.zeros(int((n * gap + .05) * SR))
    for k in range(n):
        t = tt(.02); c = hp(noise(.02), 2500) * np.exp(-t * 300) + np.sin(2 * np.pi * 3200 * t) * np.exp(-t * 250) * .4
        i = int(k * gap * SR); out[i:i + len(c)] += c
    return out * .6
def door_roll(d=.5):
    t = tt(d); x = t / d
    rattle = np.zeros_like(t)
    for k in range(int(d / .035)):
        i = int(k * .035 * SR); c = hp(noise(.025), 1500) * np.exp(-tt(.025) * 160)
        rattle[i:i + len(c)] += c[: len(rattle) - i]
    return (lp(noise(d), 180) * 1.6 + rattle * .5) * np.minimum(1, x * 6) * np.minimum(1, (1 - x) * 4) * .8
def hydraulic(d=.5):
    t = tt(d); x = t / d
    return (lp(hp(noise(d), 1500), 5000) * .35 + np.sin(2 * np.pi * (90 + 40 * x) * t) * .3) * np.minimum(1, x * 10) * np.minimum(1, (1 - x) * 8)
def beep(f=1800, d=.08):
    t = tt(d); return np.sign(np.sin(2 * np.pi * f * t)) * .18 * np.minimum(1, t * 400) * np.minimum(1, (d - t) * 400)
def knock(n=4, gap=.11):
    out = np.zeros(int((n * gap + .2) * SR))
    for k in range(n):
        t = tt(.15); c = np.tanh(3 * _sweep(70 + 60 * np.exp(-t * 40))) * np.exp(-t * 25) + hp(noise(.15), 2000) * np.exp(-t * 60) * .3
        i = int(k * gap * SR); out[i:i + len(c)] += c
    return out * .6
def screech(d=.35):
    t = tt(d); x = t / d
    return lp(hp(noise(d), 2500), 6000) * np.sin(2 * np.pi * (1800 - 600 * x) * t) * np.sin(np.pi * x) * .5


# ---------- Famille ----------
def musicbox(notes, gap=.09, d=1.0):
    """Boîte à musique : clochettes aiguës et douces."""
    out = np.zeros(int((d + gap * len(notes)) * SR))
    for k, m in enumerate(notes):
        t = tt(d); f = note(m)
        b = (np.sin(2 * np.pi * f * t) + .3 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 8)) * np.exp(-t * 4) * .3
        i = int(k * gap * SR); out[i:i + len(b)] += b
    return out
def slide_whistle(f0=1500, f1=400, d=.5):
    t = tt(d); x = t / d
    f = f0 * (f1 / f0) ** x * (1 + .01 * np.sin(2 * np.pi * 6 * t))
    return _sweep(f) * np.minimum(1, t * 40) * np.minimum(1, (d - t) * 20) * .3
def boing(f=160, d=.45):
    t = tt(d); return _sweep(f * (1 + .35 * np.sin(2 * np.pi * 9 * t) * np.exp(-t * 6))) * np.exp(-t * 7) * .6
def shutter():
    out = np.zeros(int(.25 * SR))
    for d, g in ((0, 1), (.07, .7)):
        t = tt(.05); c = hp(noise(.05), 1800) * np.exp(-t * 120) * g + np.sin(2 * np.pi * 900 * t) * np.exp(-t * 90) * .3 * g
        i = int(d * SR); out[i:i + len(c)] += c
    return out * .8
def dice_roll(d=.35):
    out = np.zeros(int((d + .05) * SR)); k = 0; tpos = 0.0
    while tpos < d:
        t = tt(.03); c = hp(noise(.03), 1200) * np.exp(-t * 200) + np.sin(2 * np.pi * (700 + 400 * (k % 3)) * t) * np.exp(-t * 160) * .4
        i = int(tpos * SR); out[i:i + len(c)] += c[: len(out) - i]
        tpos += .018 + .05 * (tpos / d) ** 2; k += 1
    return out * .55
def womp(f0=420, f1=160, d=.4):
    t = tt(d); x = t / d
    return _sweep(f0 * (f1 / f0) ** x) * np.exp(-t * 3) * np.minimum(1, t * 60) * .35


# ---------- École ----------
def school_bell(d=.9):
    t = tt(d); trem = (np.sin(2 * np.pi * 22 * t) > 0).astype(float) * .7 + .3
    return (np.sin(2 * np.pi * 1250 * t) + .5 * np.sin(2 * np.pi * 2610 * t)) * trem * np.exp(-t * 1.5) * np.minimum(1, (d - t) * 10) * .22
def scribble(d=.4):
    t = tt(d); env = (.6 + .4 * np.sin(2 * np.pi * 9 * t)) * np.minimum(1, t * 30) * np.minimum(1, (d - t) * 30)
    return lp(hp(noise(d), 2500), 7000) * env * .35
def page_flip(d=.45):
    t = tt(d); x = t / d
    return (lp(noise(d), 600 + 5000 * x) * np.sin(np.pi * x) ** 2 * 1.4 + hp(noise(d), 3000) * np.exp(-((x - .8) * 12) ** 2) * .6) * .8


# ---------- Prison ----------
def siren(d=1.0, f0=650, f1=950, rate=2.0):
    t = tt(d); f = f0 + (f1 - f0) * (.5 + .5 * np.sign(np.sin(2 * np.pi * rate * t)))
    return lp(_sweep(f) + .3 * np.sign(_sweep(f)), 3000) * np.minimum(1, t * 20) * np.minimum(1, (d - t) * 6) * .22
def bars_slam():
    t = tt(1.2)
    ring = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * k) for f, k in ((220, 3), (347, 4), (512, 6), (790, 8)))
    return (ring * .3 + thud()[: len(t)] if len(thud()) >= len(t) else ring * .3) * .9
def gavel():
    out = np.zeros(int(.6 * SR))
    for d in (0, .18):
        c = thud(); i = int(d * SR); out[i:i + len(c)] += c[: len(out) - i] * (.8 if d else 1)
    return out
