"""Bande-son de la capsule « École » (29 s, 120 BPM), calée sur capsule.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'common'))
from sfx import *  # noqa: F401,F403

END = 29.0
m = Mix(END)
p = m.place

def chord_at(t):
    if t >= 27: return 'C'
    if t >= 25: return 'G'
    return ['C', 'Am', 'F', 'G'][int((t - 2.0) // 2) % 4]
m.groove(2.0, 28.0, chord_at, hats_from=4.5, drop=[(10.5, 11.5), (17.0, 18.0)])
p(2.0, pad([note(x) for x in CHORDS['C']], 2.4), .9, 0, 'music')
p(27.0, pad([note(x) for x in CHORDS['C'] + [76]], 2.0), 1.5, 0, 'music')

# ---- Accroche : cahier, crayon, 20/20, page qui tourne ----
for i in range(5): p(i * .05, pop(500 + i * 80, .1), .3, -.6 + i * .3)
p(0.15, kick(), 1.0); p(0.15, clap(), .9, -.2)
p(0.62, kick(), 1.0); p(0.62, clap(), .9, .2)
p(0.85, scribble(.25), .9, .2)
p(1.0, pop(700, .15), .5); p(1.05, scribble(.3), .9, .4)
p(1.36, chime([84, 88, 91], gap=.04, d=.7), .45)
p(1.48, page_flip(.5), 1.1)
p(1.98, boom(), 1.0); p(1.98, crash(), .7)
for i in range(11): p(1.70 + i * .03, pop(700 + i * 70, .09), .25, -.5 + i * .1)
p(2.25, chime([72, 76, 79, 84], gap=.05, d=1.0), .5)
p(2.5, thud(), .7); p(2.5, crash(1.4), .35)

# ---- Coupes, chapitres, whips ----
for c in (3.5, 10.5, 17.0, 25.0):
    p(c - .38, whoosh(.55), .55, -.3)
for c in (3.5, 10.5, 17.0):
    p(c, boom(), .6); p(c, crash(1.6), .35); p(c + .12, school_bell(.7), .7)
for c in (4.5, 6.5, 9.0, 11.5, 13.0, 15.0, 18.0, 20.0, 22.5):
    p(c - .18, whoosh(.3), .45, .4)

# ---- 01 · Primaire ----
for i in range(7): p(4.55 + i * .05, pop(450 + i * 60, .1), .3)
for k, a in enumerate((4.8, 5.05, 5.3, 5.5, 5.7, 5.88, 6.1)): p(a, chime([72 + k * 2], d=.4), .35)
p(5.0, pop(450, .14), .4)
for a, notes in ((7.0, [79, 84, 88]), (7.65, [79, 84]), (8.3, [79, 84, 88])):
    p(a, click(), .9, .2); p(a + .1, chime(notes, gap=.04, d=.6), .45); p(a + .12, pop(600, .12), .4)
p(9.2, scribble(.3), .5); for_ticks = [p(9.2 + k * .03, tick(2600), .4) for k in range(12)]
p(9.74, thud(), 1.0); p(9.76, chime([72, 76, 79, 84], gap=.05, d=1.0), .5); p(9.74, crash(1.2), .35)
p(9.95, pop(420, .15), .4)

# ---- 02 · Collège ----
p(11.52, school_bell(.9), .6)
p(11.55, pop(400, .16), .4)
for k in range(6): p(11.8 + k * .05, pop(800 + k * 80, .07), .2)
p(12.2, whoosh(.3), .4); p(12.5, chime([88, 91], gap=.06, d=.6), .5); p(12.5, pop(550), .45)
for k, a in enumerate((13.1, 13.45, 13.8, 14.15, 14.5)):
    p(a, pop(500 + k * 90, .14), .55, (-.4, .4)[k % 2])
p(13.2, chime([79, 84], gap=.05, d=.6), .4); p(13.55, chime([79, 84, 88], gap=.05, d=.6), .4)
p(13.85, womp(), .5); p(14.25, chime([79, 84, 88, 91], gap=.04, d=.8), .45)
for k in range(10): p(15.15 + k * .045, tick(2600 + k * 40), .5)
for k in range(3): p(15.22 + k * .08, whoosh(.2), .25, (-.6, .6, -.6)[k])
p(15.95, click(), .9, .3); p(16.0, chime([72, 76, 79, 84], gap=.05, d=1.0), .55)

# ---- 03 · Lycée & BAC ----
for i in range(12): p(18.08 + i * .025, pop(500 + i * 40, .08), .2, -.5 + (i % 3) * .5)
for k, a in enumerate((18.45, 18.75, 19.05)):
    p(a, click(), .8, -.3 + k * .3); p(a + .06, chime([79 + k * 3], d=.4), .45)
p(19.6, womp(380, 240, .25), .4); p(19.3, pop(600), .45)
for k, a in enumerate((20.35, 20.7, 21.05)):
    p(a - .2, scribble(.2), .7, .5); p(a, thud(), .55); p(a + .02, chime([76 + k * 3], d=.4), .35)
for k in range(14): p(21.35 + k * .03, tick(3000), .4)
p(21.85, chime([72, 76, 79, 84, 88], gap=.05, d=1.2), .6); p(21.9, crash(1.4), .4); p(21.85, thud(), .6)
p(22.55, whoosh(.4), .5); p(22.9, boom(), .5)
p(23.0, chime([72, 76, 79, 84, 88, 91], gap=.04, d=1.6), .7); p(23.0, crash(), .5)
for k in range(9): p(23.0 + k * .04, pop(900 + k * 60, .06), .2, -.6 + k * .15)

# ---- CTA ----
p(25.0, boom(), .7); p(25.0, crash(), .5)
for i in range(11): p(25.15 + i * .025, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(25.55, whoosh(.3), .4); p(25.62, pop(400, .2), .6)
p(26.3, click(), 1.0, .3); p(26.3, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.6), .7); p(26.3, crash(), .45)
for k in range(12): p(26.4 + .6 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav')
m.render(out, fade_from=28.2)
print('ok', out)
