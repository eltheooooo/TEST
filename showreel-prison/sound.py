"""Bande-son du focus prison (30 s, 120 BPM), calée sur reel.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'capsules', 'common'))
from sfx import *  # noqa: F401,F403

m = Mix(30.0); p = m.place
def chord_at(t):
    if t >= 28: return 'C'
    if t >= 25: return ['F', 'G'][int((t - 25) // 2) % 2]
    if 23 <= t < 25: return 'C'
    return ['Am', 'F', 'Dm', 'Em'][int((t - 3.0) // 2) % 4]
m.groove(3.0, 29.0, chord_at, hats_from=5.0, drop=[(20.0, 21.0), (23.0, 24.0)])
p(0.0, pad([note(x) for x in CHORDS['Am']], 3.0), 1.2, 0, 'music')
p(0.0, siren(2.6), .5, -.3)
p(0.05, boom(), .6); p(0.4, boom(), .5)
for k in range(3): p(1.0 + k * .5, thud(), .6); p(1.0 + k * .5, chime([69 + k * 2, 76 + k * 2], gap=.05, d=.6), .3)
p(1.5, riser(1.4), .6); p(2.55, whoosh(.45), .6)
p(3.0, boom(), 1.0); p(3.0, crash(), .8)
for i in range(11): p(3.1 + i * .03, pop(700 + i * 70, .09), .3, -.5 + i * .1)
p(3.75, thud(), .7); p(3.75, crash(1.2), .3); p(4.0, chime([69, 72, 76, 81], gap=.05, d=1.0), .4)
p(4.85, whoosh(.3), .6)
p(5.0, whoosh(.5, False), .5); p(5.12, thud(), .6)
for a in (5.6, 5.9, 6.65): p(a, pop(600, .12), .4, .3)
p(5.7, riser(.7), .25)
p(7.45, click(), .9); p(7.5, womp(500, 200, .5), .5)
p(7.82, whoosh(.4), .6)
p(8.0, siren(2.6, 700, 1000, 3.0), .6, .3)
for i in range(5): p(8.75 + i * .03 + .25, thud(), .35)
p(9.05, bars_slam(), 1.0); p(9.1, gavel(), .8); p(9.1, crash(1.5), .4)
for a in (8.9, 9.4): p(a, pop(600, .12), .4)
p(10.82, whoosh(.4), .6)
for i in range(5): p(11.3 + i * .06, pop(450 + i * 60, .1), .35)
p(11.6, pop(600, .12), .4); p(12.2, pop(600, .12), .4)
p(12.0, click(), .9); p(12.1, chime([79, 84], gap=.05, d=.6), .4)
p(13.0, click(), .9); p(13.05, womp(400, 250, .4), .5); p(13.1, tick(1800), .6)
p(13.6, riser(.4), .5); p(14.0, boom(), .8); p(14.0, crash(), .6)
for k in range(12):
    a = 14.0 + k * .5
    p(a, whoosh(.18), .3, (-.5, .5)[k % 2]); p(a + .02, pop(360 + (k % 6) * 60, .14), .5); p(a + .06, thud(), .25)
p(19.5, riser(.5), .5)
p(20.0, boom(), .6); p(20.0, pad([note(x) for x in CHORDS['Am']], 1.6), 1.2, 0, 'music')
p(20.2, whoosh(.3), .4); p(20.45, pop(500), .4)
for k in range(26):
    x = k / 26; p(20.6 + 1.3 * (1 - (1 - x) ** 1.6), tick(1600 + (k % 2) * 400), .6)
p(21.95, siren(1.1, 700, 1000, 3.0), .7, -.2); p(21.95, bars_slam(), .8); p(21.95, womp(380, 140, .6), .6)
p(22.8, whoosh(.3), .5)
p(23.0, door_roll(.5), .7); p(23.2, chime([72, 76, 79, 84], gap=.07, d=1.6), .55); p(23.25, crash(1.6), .3)
p(23.8, pop(450, .15), .4); p(24.3, pop(500), .4); p(24.8, whoosh(.3), .5)
p(25.0, boom(), 1.0); p(25.0, crash(), .7)
for i in range(11): p(25.1 + i * .028, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(25.6, whoosh(.3), .4); p(25.68, pop(400, .2), .6)
p(26.7, click(), 1.0, .3); p(26.7, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.8), .75); p(26.7, crash(), .5)
for k in range(12): p(26.9 + .7 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)
p(28.0, pad([note(x) for x in CHORDS['C'] + [76, 79]], 2.0), 1.6, 0, 'music')
m.render(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav'), fade_from=29.0)
print('ok')
