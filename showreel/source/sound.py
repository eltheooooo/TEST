# Sound design synthétisé, calé sur la timeline de reel.html (120 BPM, 15 s).
import numpy as np, wave
SR = 48000; DUR = 15.0; N = int(SR * DUR)
rs = np.random.RandomState(4)
mix = np.zeros((N, 2)); music = np.zeros((N, 2))
def place(buf, t, sig, gain=1.0, pan=0.0):
    i = int(t * SR)
    if i >= N: return
    sig = sig[: N - i]
    if i < 0: sig = sig[-i:]; i = 0
    l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
    buf[i:i + len(sig), 0] += sig * gain * l * 1.414
    buf[i:i + len(sig), 1] += sig * gain * r * 1.414
def tt(d): return np.arange(int(d * SR)) / SR
def lp(x, fc):  # passe-bas 1 pôle (fc scalaire ou tableau)
    fc = np.broadcast_to(fc, x.shape); a = 1 - np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x); s = 0.0
    for i in range(len(x)): s += a[i] * (x[i] - s); y[i] = s
    return y
def hp(x, fc): return x - lp(x, fc)
def noise(d): return rs.uniform(-1, 1, int(d * SR))
def note(f): return 440 * 2 ** ((f - 69) / 12)

# --- Sons ---
def kick(g=1.0):
    t = tt(.45); f = 45 + 110 * np.exp(-t * 28)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7) * g + lp(noise(.45), 3000) * np.exp(-t * 90) * .3
def boom():
    t = tt(1.4); f = 32 + 90 * np.exp(-t * 9)
    return np.tanh(1.8 * np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.exp(-t * 2.6)
def clap():
    t = tt(.3); n = hp(noise(.3), 900)
    env = np.exp(-t * 22) + .6 * np.exp(-np.maximum(t - .012, 0) * 30) * (t > .012) + .4 * np.exp(-np.maximum(t - .024, 0) * 26) * (t > .024)
    return n * env * .55
def hat(): t = tt(.08); return hp(noise(.08), 7000) * np.exp(-t * 60) * .5
def crash(): t = tt(2.2); return hp(noise(2.2), 4500) * np.exp(-t * 2.2) * .5
def whoosh(d=.6, up=True):
    t = tt(d); x = t / d
    env = np.sin(np.pi * x) ** 2
    fc = (300 + 5200 * x ** 1.5) if up else (5500 - 5000 * x)
    return lp(noise(d), fc) * env * 2.2
def riser(d):
    t = tt(d); x = t / d
    s = lp(noise(d), 400 + 7000 * x ** 2) * x ** 2 * 1.6
    f = 200 + 900 * x ** 2
    return s + np.sin(2 * np.pi * np.cumsum(f) / SR) * x ** 3 * .25
def pop(f0=900, d=.12):
    t = tt(d); f = f0 * (1 + 1.2 * np.exp(-t * 60))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 35) * .6
def tick(f=2400): t = tt(.03); return np.sin(2 * np.pi * f * t) * np.exp(-t * 180) * .35
def click(): t = tt(.06); return (hp(noise(.06), 2000) * np.exp(-t * 120) + np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 90)) * .6
def bell(f, d=1.2):
    t = tt(d)
    return (np.sin(2 * np.pi * f * t) + .5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 4) + .25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 9)) * np.exp(-t * 3.2) * .35
def chime(notes, gap=.06, d=1.2, g=1.0):
    out = np.zeros(int((d + gap * len(notes)) * SR))
    for k, m in enumerate(notes):
        b = bell(note(m), d); i = int(k * gap * SR); out[i:i + len(b)] += b
    return out * g
def coin():  # « ka-ching »
    c = chime([88, 95], gap=.07, d=.7); c[:int(.25 * SR)] += hp(noise(.25), 5000) * np.exp(-tt(.25) * 20) * .3
    return c
def pluck(f, d=.35):
    t = tt(d); w = 2 * (t * f % 1) - 1
    return lp(w, 800 + 4000 * np.exp(-t * 18)) * np.exp(-t * 9) * .25
def bass(f, d=.5):
    t = tt(d); w = np.sin(2 * np.pi * f * t) + .35 * np.sin(4 * np.pi * f * t) + .15 * (2 * (t * f % 1) - 1)
    return w * np.minimum(1, t * 200) * np.exp(-t * 3) * .5
def pad(fs, d):
    t = tt(d); s = sum(np.sin(2 * np.pi * f * t + k) + .4 * np.sin(2 * np.pi * f * 1.003 * t) for k, f in enumerate(fs))
    return s * np.minimum(1, t / .3) * np.minimum(1, (d - t) / .5) * .07

# --- Musique : 120 BPM ---
CH = {'C': [60, 64, 67, 72], 'G': [55, 59, 62, 67], 'Am': [57, 60, 64, 69], 'F': [53, 57, 60, 65]}
BAS = {'C': 36, 'G': 31, 'Am': 33, 'F': 29}
prog = [(1.5, 'C'), (3, 'C'), (5, 'G'), (7, 'Am'), (9, 'F'), (11, 'G'), (12, 'F'), (13, 'G'), (14, 'C')]
def chord_at(t):
    c = prog[0][1]
    for s, n in prog:
        if t >= s: c = n
    return c
place(music, 1.5, pad([note(m) for m in CH['C']], 1.6), .9)
b = 1.5
while b < 14.6:
    beat = round((b - 1.5) * 2)
    place(mix, b, kick(), .9)
    c = chord_at(b)
    if b >= 3.0:
        place(music, b + .25, hat(), .8, .3)
        place(music, b, bass(note(BAS[c]), .45), 1.0)
        place(music, b + .25, bass(note(BAS[c] + 12), .22), .5)
        if beat % 2 == 1: place(music, b, clap(), .7, -.1)
        for k in range(4):  # arpège en doubles croches
            m = CH[c][(beat * 4 + k) % 4] + (12 if k == 3 else 0)
            place(music, b + k * .125, pluck(note(m)), .9, (-.4 if k % 2 else .4))
    b += .5
# Accord final tenu.
place(music, 14.0, pad([note(m) for m in CH['C'] + [76]], 1.0), 1.4)

# --- Accroche ---
place(mix, 0.0, boom(), .9); place(mix, 0.0, kick(), 1.0); place(mix, 0.0, whoosh(.25, False), .5)
place(mix, .55, kick(.8), .9); place(mix, .55, clap(), .9, -.2)
place(mix, .63, kick(.8), .9); place(mix, .63, clap(), .9, .2)
place(mix, .82, chime([84, 88, 91, 96], gap=.03, d=.6), .5)
place(mix, .9, riser(.6), .6)
place(mix, 1.5, boom(), 1.0); place(mix, 1.5, crash(), .8)
# --- Logo ---
for i in range(11): place(mix, 1.5 + .2 + i * .032, pop(700 + i * 70, .09), .35, -.5 + i * .1)
place(mix, 2.2, chime([72, 76, 79, 84], gap=.05, d=1.0), .55)
# --- Coupes ---
for c in [3.0, 4.5, 6.0, 7.5, 9.0, 10.5, 12.0]:
    place(mix, c - .38, whoosh(.55), .55, -.3)
place(mix, 12.0, boom(), .7); place(mix, 12.0, crash(), .55)
# --- F1 ---
place(mix, 3.1, pop(600), .5)
place(mix, 3.8, click(), .9, .3)
for k in range(18): place(mix, 3.86 + .38 * k / 18, tick(1800 + k * 60), .9)
place(mix, 4.26, chime([79, 84], gap=.05, d=.6), .4)
# --- F2 ---
for k in range(3): place(mix, 4.5 + .32 + k * .07, whoosh(.18, True), .25, (-.6, .6, -.6)[k])
place(mix, 5.24, click(), .9, .3)
place(mix, 5.4, chime([76, 79, 84, 88], gap=.045, d=.9), .5)
for k in range(3): place(mix, 5.52 + k * .07, pop(500 + k * 150), .55, (-.5, .5, -.2)[k])
# --- F3 ---
for k in range(6): place(mix, 6.0 + .2 + k * .06, pop(500 + k * 110), .5, (-.5 if k % 2 == 0 else .5))
# --- F4 ---
for a in (8.0, 8.3): place(mix, a + .05, chime([83, 88], gap=.08, d=.5), .45, .2)
for k in range(10): place(mix, 8.05 + k * .09, pop(1200 + (k % 4) * 150, .06), .18, (-.6 + k * .12))
# --- F5 ---
for k in range(16):
    x = k / 16; place(mix, 9.1 + .5 * (1 - (1 - x) ** 2.2), tick(1500), .8)
place(mix, 9.64, coin(), .7)
place(mix, 9.66, pop(700), .45)
for k in range(5): place(mix, 9.75 + k * .1, coin() * .5, .35, (-.6 + k * .3))
# --- F6 ---
place(mix, 10.98, riser(.4), .35)
place(mix, 11.42, chime([72, 76, 79, 84, 88], gap=.04, d=1.2), .6)
place(mix, 11.42, crash(), .3)
# --- CTA ---
for i in range(11): place(mix, 12.05 + .1 + i * .025, pop(700 + i * 70, .08), .3, -.5 + i * .1)
place(mix, 12.55, whoosh(.3), .4); place(mix, 12.62, pop(400, .2), .6)
place(mix, 13.25, click(), 1.0, .3)
place(mix, 13.25, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.6), .7)
place(mix, 13.25, crash(), .45)
for k in range(12): place(mix, 13.3 + .6 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)

# Sidechain : la musique s'efface un peu sous chaque kick.
duck = np.ones(N)
b = 1.5
while b < 15:
    i = int(b * SR); L = int(.25 * SR); seg = 1 - .55 * np.exp(-np.arange(L) / SR * 14)
    duck[i:i + L] = np.minimum(duck[i:i + L], seg[: max(0, min(L, N - i))]); b += .5
music *= duck[:, None]
out = mix + music * 1.1
# Fondu de fin + limiteur doux.
fade = np.ones(N); fs = int(14.3 * SR); fade[fs:] = np.linspace(1, 0, N - fs) ** 1.5
out *= fade[:, None]
out = np.tanh(out / np.max(np.abs(out)) * 1.6) / np.tanh(1.6) * .89
w = wave.open('sound.wav', 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes((out * 32767).astype('<i2').tobytes()); w.close()
print('ok', out.shape)
