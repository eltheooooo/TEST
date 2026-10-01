"""Bande-son de la capsule « Coiffure » (29 s, 120 BPM), calée sur capsule.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'common'))
from sfx import *  # noqa: F401,F403

END = 29.0
m = Mix(END)
p = m.place

# ---- Musique : Am F C G, résolution sur C à la fin ----
def chord_at(t):
    if t >= 27: return 'C'
    if t >= 25: return 'F'
    return ['Am', 'F', 'C', 'G'][int((t - 2.0) // 2) % 4]
m.groove(2.0, 28.0, chord_at, hats_from=4.5, drop=[(10.5, 11.5), (17.0, 18.0)])
p(2.0, pad([note(x) for x in CHORDS['Am']], 2.4), .9, 0, 'music')
p(27.0, pad([note(x) for x in CHORDS['C'] + [76]], 2.0), 1.5, 0, 'music')

# ---- Accroche : ciseaux, slams, entaille ----
p(0.0, boom(), .8); p(0.0, whoosh(.35, False), .5)
p(0.22, snip(), .9, -.2)
p(0.4, kick(), 1.0); p(0.4, clap(), .9, -.2); p(0.4, snip(), .6, .3)
p(0.9, kick(), 1.0); p(0.9, clap(), .9, .2)
p(0.95, riser(.6), .45)
p(1.24, whoosh(.36), .6, -.6)
for k in range(4): p(1.28 + k * .07, snip(), .7, -.6 + k * .4)
p(1.55, shing(1.2), .8, .3)
p(1.58, boom(), 1.0); p(1.58, crash(), .7)
# ---- Logo ----
for i in range(11): p(1.70 + i * .03, pop(700 + i * 70, .09), .32, -.5 + i * .1)
p(2.25, chime([69, 72, 76, 81], gap=.05, d=1.0), .5)
p(2.5, thud(), .7); p(2.5, snip(), .8); p(2.5, crash(1.4), .35)

# ---- Coupes (volets) et cartons de chapitre ----
for c in (3.5, 10.5, 17.0, 25.0):
    p(c - .38, whoosh(.55), .55, -.3)
for c in (3.5, 10.5, 17.0):
    p(c, boom(), .6); p(c, crash(1.6), .35); p(c + .12, chime([81, 88], gap=.04, d=.6), .3)
# Whips entre les scènes d'un même chapitre.
for c in (4.5, 6.5, 9.0, 11.5, 13.0, 15.0, 18.0, 20.5, 23.0):
    p(c - .18, whoosh(.3), .45, .4)

# ---- 01 · Le salon ----
for k in range(4): p(4.62 + k * .06, pop(500 + k * 120), .4, (-.4, .4)[k % 2])
p(5.12, click(), .9, .3)
p(5.3, pop(400, .2), .5)
p(6.05, click(), .9, .2); p(6.08, snip(), .8, .2)
# Roue : tapotement puis cliquetis à chaque frontière franchie.
p(6.8, click(), .9)
SPIN = 126 + 360 * 4
def rot(u):
    sp = min(1, max(0, (u - .34) / (2.0 - .34)))
    return SPIN * (1 - (1 - sp) ** 3.4)
prev = 0
for i in range(1, 2500):
    u = i / 1000
    r = rot(u)
    for b in (0, 216, 252, 288, 324):
        # Une frontière passe sous le pointeur quand l'angle sous lui la traverse.
        if int((r - (360 - b) % 360) // 360) != int((prev - (360 - b) % 360) // 360):
            p(6.5 + u, tick(2200 if b else 1700), 1.0, .1)
    prev = r
p(8.52, chime([76, 79, 84, 88, 91], gap=.04, d=1.2), .65); p(8.52, crash(1.5), .35)
# Miroir
p(9.15, chime([96, 93, 91, 88, 84], gap=.035, d=.6), .35)
p(9.33, chime([84, 91], gap=.05, d=.9), .5)
for k in range(4): p(9.42 + k * .07, pop(500 + k * 140), .5, (-.5, .5)[k % 2])
p(9.85, pop(800), .35)

# ---- 02 · Le CAP ----
for k in range(10): p(11.65 + k * .045, tick(2600 + k * 40), .5)
for k in range(3): p(11.72 + k * .08, whoosh(.2), .25, (-.6, .6, -.6)[k])
p(12.45, click(), .9, .3)
p(13.25, riser(.6), .35)
p(13.88, whoosh(.3, False), .4)
p(14.2, chime([79, 84], gap=.05, d=.6), .4)
p(14.35, click(), .9, .3)
p(14.5, pop(600, .15), .55); p(14.52, snip(), .6)
for k, tn in enumerate((15.15, 15.425, 15.7)): p(tn, chime([72 + k * 4], d=.5), .45)
p(15.6, whoosh(.3), .35)
for k in range(14): p(15.75 + k * .022, tick(3000), .45)
p(16.08, thud(), 1.0); p(16.08, crash(), .55); p(16.1, chime([72, 76, 79, 84, 88], gap=.05, d=1.3), .55)
p(16.25, pop(500), .5, -.4); p(16.33, pop(650), .5, .4)

# ---- 03 · La carrière ----
p(18.02, pop(500, .15), .45)
for i in range(6): p(18.15 + i * .07, whoosh(.16), .2, .5)
p(19.0, click(), .9, .3)
for k in range(6): p(19.06 + k * .055, tick(1500 if k % 2 else 1900), .5)
p(19.42, chime([72, 76, 79, 84, 88, 91], gap=.04, d=1.4), .65); p(19.42, crash(1.6), .4)
for k, a in enumerate((20.62, 21.05, 21.5, 21.95, 22.4)):
    p(a, pop(500 + k * 90, .14), .55, (-.4, .4)[k % 2])
p(21.12, coin(), .45)
p(22.05, coin(), .6); p(22.5, coin(), .6); p(22.58, coin(), .4, .5)
p(23.02, chime([84, 88, 91, 96], gap=.07, d=1.4), .3)
for a, d in ((23.45, .07), (23.58, .05), (23.66, .5)): p(a, buzz(d), .8)
p(23.52, pop(450, .15), .4)
p(24.25, click(), .9, .3)
p(24.4, pop(550), .5, -.4); p(24.48, pop(700), .5, .4)

# ---- CTA ----
p(25.0, boom(), .7); p(25.0, crash(), .5)
for i in range(11): p(25.15 + i * .025, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(25.55, whoosh(.3), .4); p(25.62, pop(400, .2), .6)
p(26.3, click(), 1.0, .3); p(26.3, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.6), .7); p(26.3, crash(), .45)
for k in range(12): p(26.4 + .6 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav')
m.render(out, fade_from=28.2)
print('ok', out)
