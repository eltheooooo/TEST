"""Bande-son de la capsule « Mécano » (29 s, 120 BPM), calée sur capsule.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'common'))
from sfx import *  # noqa: F401,F403

END = 29.0
m = Mix(END)
p = m.place

# ---- Musique : Am F C G, résolution sur C ----
def chord_at(t):
    if t >= 27: return 'C'
    if t >= 25: return 'F'
    return ['Am', 'F', 'C', 'G'][int((t - 2.0) // 2) % 4]
m.groove(2.0, 28.0, chord_at, hats_from=4.5, drop=[(10.5, 11.5), (17.0, 18.0)])
p(2.0, pad([note(x) for x in CHORDS['Am']], 2.4), .9, 0, 'music')
p(27.0, pad([note(x) for x in CHORDS['C'] + [76]], 2.0), 1.5, 0, 'music')

# ---- Accroche : clé, slams, voiture, rideau ----
p(0.0, boom(), .8); p(0.0, whoosh(.35, False), .5)
p(0.05, ratchet(9), .9)
p(0.4, kick(), 1.0); p(0.4, clap(), .9, -.2); p(0.4, shing(.5), .3)
p(0.9, kick(), 1.0); p(0.9, clap(), .9, .2)
for k, (a, pan) in enumerate(((0.95, -.8), (1.1, -.2), (1.25, .4), (1.38, .8))):
    p(a, engine(.22, 70 + k * 25, 110 + k * 30), .9, pan)
p(1.12, whoosh(.3), .7, 0)
p(1.5, door_roll(.55), 1.0)
p(1.62, boom(), 1.0); p(1.62, crash(), .7)
# ---- Logo ----
for i in range(11): p(1.70 + i * .03, pop(700 + i * 70, .09), .32, -.5 + i * .1)
p(2.25, chime([69, 72, 76, 81], gap=.05, d=1.0), .5)
p(2.5, thud(), .7); p(2.5, ratchet(6), .7); p(2.5, crash(1.4), .35)

# ---- Coupes, chapitres, whips ----
for c in (3.5, 10.5, 17.0, 25.0):
    p(c - .38, whoosh(.55), .55, -.3)
for c in (3.5, 10.5, 17.0):
    p(c, boom(), .6); p(c, crash(1.6), .35); p(c + .12, chime([81, 88], gap=.04, d=.6), .3)
for c in (4.5, 6.5, 9.0, 11.5, 13.0, 15.0, 18.0, 20.5, 23.0):
    p(c - .18, whoosh(.3), .45, .4)

# ---- 01 · Le métier ----
p(4.52, pop(300, .15), .5, -.6); p(4.56, pop(320, .15), .5, .6)
p(4.58, hydraulic(.5), .9)
p(5.0, click(), .9, .3)
for k in range(4):
    p(5.34 + k * .22, beep(1500 + k * 150, .06), .9); p(5.36 + k * .22, chime([84 + k * 2], d=.4), .25)
for k in range(10): p(5.12 + k * .088, beep(2400, .03), .35)
p(5.95, knock(4), .9); p(6.05, pop(250, .2), .5)
# Chasse à la panne
for i in range(6): p(6.58 + i * .04, pop(500 + i * 80, .1), .35, -.5 + i * .2)
for j in range(5): p(6.8 + j * .22, whoosh(.18), .2, .3)
for j, a in enumerate((6.88, 7.02, 7.24, 7.46, 7.68)): p(a, chime([86 + j], d=.35), .35)
for k in range(4): p(7.9 + k * .12, beep(980, .07), .9); p(7.96 + k * .12, beep(780, .05), .7)
p(8.38, chime([76, 79, 84, 88, 91], gap=.04, d=1.2), .6); p(8.4, crash(1.4), .3)
# Voiture de prestige
p(9.0, engine(.5, 60, 140, 1.2), 1.0, .6); p(9.32, screech(.35), .6, -.2)
p(9.5, chime([91, 96], gap=.03, d=.6), .4)
for k in range(5): p(9.5 + k * .08, pop(1400 + k * 120, .05), .2, -.6 + k * .3)
for k in range(3): p(9.7 + k * .07, pop(500 + k * 140), .5, (-.5, 0, .5)[k])

# ---- 02 · Le CAP ----
for k in range(10): p(11.65 + k * .045, tick(2600 + k * 40), .5)
for k in range(3): p(11.72 + k * .08, whoosh(.2), .25, (-.6, .6, -.6)[k])
p(12.45, click(), .9, .3)
p(13.25, riser(.6), .35); p(13.88, whoosh(.3, False), .4)
p(14.2, chime([79, 84], gap=.05, d=.6), .4)
p(14.35, click(), .9, .3)
p(14.5, pop(600, .15), .55); p(14.52, ratchet(5), .6)
for k, tn in enumerate((15.15, 15.425, 15.7)): p(tn, chime([72 + k * 4], d=.5), .45)
p(15.6, whoosh(.3), .35)
for k in range(14): p(15.75 + k * .022, tick(3000), .45)
p(16.08, thud(), 1.0); p(16.08, crash(), .55); p(16.1, chime([72, 76, 79, 84, 88], gap=.05, d=1.3), .55)
p(16.25, pop(500), .5, -.4); p(16.33, pop(650), .5, .4)

# ---- 03 · La carrière ----
p(18.02, pop(500, .15), .45)
for i in range(3): p(18.15 + i * .09, whoosh(.18), .25, .5)
p(19.0, click(), .9, .3)
for k in range(6): p(19.06 + k * .055, tick(1500 if k % 2 else 1900), .5)
p(19.42, chime([72, 76, 79, 84, 88, 91], gap=.04, d=1.4), .65); p(19.42, crash(1.6), .4)
for k, a in enumerate((20.62, 21.05, 21.5, 21.95, 22.4)):
    p(a, pop(500 + k * 90, .14), .55, (-.4, .4)[k % 2])
p(21.15, coin(), .6); p(21.6, coin(), .45); p(21.97, chime([79, 84, 88], gap=.05, d=.8), .4); p(22.05, coin(), .45); p(22.5, coin(), .6); p(22.58, coin(), .4, .5)
p(23.02, pop(450, .15), .45)
p(23.85, click(), .9, .3)
p(24.05, boom(), .5); p(24.05, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.5), .65); p(24.05, crash(1.6), .4)
p(24.2, pop(400, .2), .5)
p(24.25, pop(700), .45, -.6); p(24.31, pop(760), .45, .6)
p(24.45, coin(), .5, -.3); p(24.53, pop(650), .5, .4)

# ---- CTA ----
p(25.0, boom(), .7); p(25.0, crash(), .5)
for i in range(11): p(25.15 + i * .025, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(25.55, whoosh(.3), .4); p(25.62, pop(400, .2), .6)
p(26.3, click(), 1.0, .3); p(26.3, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.6), .7); p(26.3, crash(), .45)
p(26.32, engine(.45, 80, 160, .8), .6, .4)
for k in range(12): p(26.4 + .6 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav')
m.render(out, fade_from=28.2)
print('ok', out)
