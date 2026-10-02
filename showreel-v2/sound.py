"""Bande-son du showreel v2 (30 s, 120 BPM), calée sur reel.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'capsules', 'common'))
from sfx import *  # noqa: F401,F403

m = Mix(30.0); p = m.place
def chord_at(t):
    if t >= 28: return 'C'
    if t >= 24: return ['F', 'G'][int((t - 24) // 2) % 2]
    if 20 <= t < 24: return ['Am', 'F'][int((t - 20) // 2) % 2]
    return ['Am', 'F', 'C', 'G'][int((t - 3.0) // 2) % 4]
m.groove(3.0, 29.0, chord_at, hats_from=5.0, drop=[(20.0, 22.0)])
# Ouverture : pad, montage d'icônes à la double croche, montée
p(0.0, pad([note(x) for x in CHORDS['Am']], 3.0), 1.2, 0, 'music')
p(0.05, boom(), .5); p(0.45, boom(), .4)
p(0.05, chime([69, 76], gap=.08, d=1.2), .35); p(0.45, chime([72, 79], gap=.08, d=1.2), .35)
for k in range(12):
    p(1.0 + k * .125, pop(500 + (k % 4) * 140, .07), .45, -.6 + (k % 5) * .3); p(1.0 + k * .125, tick(2200), .5)
p(1.5, riser(1.5), .7)
p(2.55, whoosh(.45), .6)
p(3.0, boom(), 1.0); p(3.0, crash(), .8); p(3.0, kick(), 1.0)
for i in range(11): p(3.1 + i * .03, pop(700 + i * 70, .09), .3, -.5 + i * .1)
p(3.9, chime([69, 72, 76, 81], gap=.05, d=1.2), .5); p(4.05, thud(), .5)
p(4.7, riser(.3), .4); p(4.85, whoosh(.3), .6)
# Téléphone
p(5.0, whoosh(.5, False), .5); p(5.12, thud(), .6)
for k, a in enumerate((5.3, 5.9, 6.5)):
    p(a, dice_roll(.25), .6); p(a + .3, chime([76 + k * 3, 83 + k * 3], gap=.04, d=.6), .4)
for a in (5.6, 5.8, 6.0): p(a, pop(600, .12), .45, .3)
p(7.55, click(), .9); p(7.6, chime([72, 76, 79, 84, 88], gap=.04, d=1.0), .55); p(7.6, crash(1.2), .3)
p(7.82, whoosh(.4), .6); p(10.82, whoosh(.4), .6)
for k, a in enumerate((8.55 + i * .27 for i in range(8))): p(a, click(), .6, .2); p(a + .02, pop(500 + k * 60, .1), .45)
for a in (8.7, 9.3): p(a, pop(650, .12), .4)
for k in range(3): p(11.3 + k * .1, whoosh(.2), .25, (-.6, .6, -.6)[k])
p(12.35, click(), .9); p(12.55, whoosh(.4), .5)
for i in range(3): p(12.7 + i * .12, scribble(.2) if False else whoosh(.25), .3, -.6 + i * .6); p(12.95 + i * .12, pop(450 + i * 120, .14), .5, -.6 + i * .6)
p(13.6, riser(.4), .5); p(14.0, boom(), .8); p(14.0, crash(), .6)
# Carrousel : un impact par temps
for k in range(12):
    a = 14.0 + k * .5
    p(a, whoosh(.18), .3, (-.5, .5)[k % 2]); p(a + .02, pop(380 + (k % 6) * 70, .14), .55); p(a + .1, chime([72 + (k * 5) % 12 + 7], d=.4), .25)
p(19.5, riser(.5), .5)
# Talents (respiration) puis classement
p(20.0, boom(), .5); p(20.0, pad([note(x) for x in CHORDS['Am'] + [76]], 2.0), 1.3, 0, 'music')
for i in range(11): p(20.32 + i * .07, musicbox([72 + (i * 3) % 14], d=.6), .5, -.6 + (i % 5) * .3)
p(21.8, whoosh(.3), .5)
for k in range(5): p(22.1 + k * .05, whoosh(.15), .2, .5)
p(22.5, riser(.6), .4); p(23.15, chime([72, 76, 79, 84, 88, 91], gap=.04, d=1.4), .6); p(23.15, crash(1.4), .4)
p(23.5, riser(.5), .5)
# CTA
p(24.0, boom(), 1.0); p(24.0, crash(), .7)
for i in range(11): p(24.1 + i * .028, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(24.6, whoosh(.3), .4); p(24.68, pop(400, .2), .6)
p(25.7, click(), 1.0, .3); p(25.7, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.8), .75); p(25.7, crash(), .5)
for k in range(12): p(25.9 + .7 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)
p(28.0, pad([note(x) for x in CHORDS['C'] + [76, 79]], 2.0), 1.6, 0, 'music')
m.render(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav'), fade_from=29.0)
print('ok')
