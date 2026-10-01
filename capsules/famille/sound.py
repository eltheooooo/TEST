"""Bande-son de la capsule « Famille » (29 s, 120 BPM), calée sur capsule.html."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'common'))
from sfx import *  # noqa: F401,F403

END = 29.0
m = Mix(END)
p = m.place

# ---- Musique : C G Am F (plus chaleureux), résolution sur C ----
def chord_at(t):
    if t >= 27: return 'C'
    if t >= 25: return 'G'
    return ['C', 'G', 'Am', 'F'][int((t - 2.0) // 2) % 4]
m.groove(2.0, 28.0, chord_at, hats_from=4.5, drop=[(10.5, 11.5), (17.0, 18.0)])
p(2.0, pad([note(x) for x in CHORDS['C']], 2.4), .9, 0, 'music')
p(27.0, pad([note(x) for x in CHORDS['C'] + [76]], 2.0), 1.5, 0, 'music')

# ---- Accroche : polaroïds, slams, déclic ----
for k, d in enumerate((0, .1, .2, .32, .44)):
    p(d, whoosh(.25), .35, (-.6, .6, -.6, 0, .6)[k]); p(d + .3, pop(380 + k * 60, .14), .5, (-.6, .6, -.6, 0, .6)[k])
p(0.5, kick(), 1.0); p(0.5, clap(), .9, -.2)
p(0.95, kick(), 1.0); p(0.95, clap(), .9, .2)
p(1.12, pop(700, .15), .5); p(1.12, chime([84, 88], gap=.05, d=.5), .3)
p(1.25, riser(.32), .45)
p(1.52, shutter(), 1.0)
p(1.6, boom(), 1.0); p(1.6, crash(), .7)
# ---- Logo ----
for i in range(11): p(1.70 + i * .03, pop(700 + i * 70, .09), .32, -.5 + i * .1)
p(2.25, musicbox([72, 76, 79, 84], gap=.07, d=1.0), .7)
p(2.5, thud(), .7); p(2.5, crash(1.4), .35); p(2.52, chime([79, 84, 88], gap=.04, d=.8), .35)

# ---- Coupes, chapitres, whips ----
for c in (3.5, 10.5, 17.0, 25.0):
    p(c - .38, whoosh(.55), .55, -.3)
for c in (3.5, 10.5, 17.0):
    p(c, boom(), .6); p(c, crash(1.6), .35); p(c + .12, chime([81, 88], gap=.04, d=.6), .3)
for c in (4.5, 7.0, 9.0, 11.5, 13.5, 15.0, 18.0, 20.5, 22.5):
    p(c - .18, whoosh(.3), .45, .4)

# ---- 01 · Ta famille ----
p(4.5, dice_roll(.32), .9)
p(4.65, whoosh(.25), .35, -.5); p(4.72, whoosh(.25), .35, .5)
def reel_ticks(a, b, n=14, pan=0):
    for k in range(n):
        x = k / n; p(a + (b - a) * (1 - (1 - x) ** 2), tick(1700), .7, pan)
reel_ticks(4.85, 5.55, pan=-.5); reel_ticks(4.95, 5.7, pan=.5)
p(5.55, chime([79, 84], gap=.04, d=.5), .4, -.5); p(5.7, chime([81, 86], gap=.04, d=.5), .4, .5)
p(5.65, whoosh(.25), .3)
p(5.8, musicbox([72, 76, 79, 84, 88, 91], gap=.06, d=1.4), .9); p(5.82, crash(1.2), .25)
p(5.95, pop(520, .14), .45); p(6.1, pop(420, .14), .4)
# Petit frère
p(7.02, pop(400, .16), .45)
p(7.3, pop(600, .14), .45, -.4)
p(7.45, slide_whistle(1600, 420, .48), .9, .4)
p(7.95, boing(150), .9, .4); p(7.97, musicbox([84, 88, 91], gap=.05, d=.8), .6)
p(8.05, pop(520, .14), .45)
p(8.3, chime([72, 76, 79, 84], gap=.05, d=1.0), .5)
# Grands-parents
for k in range(6): p(9.0 + k * .12, pop(700 + (k % 3) * 120, .1), .3, -.6 + k * .24)
p(9.05, whoosh(.3), .4, -.7); p(9.12, whoosh(.3), .4, .7)
p(9.4, boing(200, .35), .6, -.5); p(9.47, boing(180, .35), .6, .5)
p(9.45, pop(600), .4, -.5); p(9.52, pop(650), .4, .5); p(9.62, pop(420, .15), .4)

# ---- 02 · Les relations ----
for k in range(6): p(11.65 + k * .04, pop(500 + k * 70, .08), .3, -.4 + k * .16)
for tap, notes in ((12.05, [76, 79, 84, 88]), (12.7, [79, 84, 88])):
    p(tap, click(), .9, .2); p(tap + .08, musicbox(notes, gap=.05, d=.8), .8); p(tap + .12, pop(560, .14), .45)
p(13.95, click(), .9); p(13.97, chime([88, 95], gap=.06, d=.7), .5)
for k in range(4): p(14.0 + k * .06 + .3, coin() * .5, .4, -.4 + k * .25)
p(14.15, womp(), .8)
p(14.12, pop(420, .15), .4); p(14.35, pop(520), .45, -.4); p(14.43, womp(300, 180, .25), .5, .4)
for y in (15.35, 15.65, 15.95, 16.25):
    p(y, tick(2400), .7); p(y + .02, womp(500, 350, .2), .35)
p(16.45, chime([79, 84, 88], gap=.04, d=.8), .45)

# ---- 03 · Les moments ----
for k, a in enumerate((18.12, 18.55, 19.0, 19.45, 19.9)):
    p(a, pop(500 + k * 90, .14), .55, (-.4, .4)[k % 2])
p(18.22, musicbox([79, 84], gap=.05, d=.6), .6); p(20.0, musicbox([76, 79, 84, 88], gap=.05, d=.8), .7)
p(18.6, chime([84, 88, 91], gap=.04, d=.6), .3); p(19.1, coin(), .5); p(19.5, boing(220, .3), .35)
p(20.52, whoosh(.3), .35, -.7); p(20.56, whoosh(.3), .35, .7)
p(20.8, thud(), .6); p(20.72, pop(400, .16), .4)
p(21.4, click(), .9, -.3); p(21.45, musicbox([72, 76, 79, 84, 88], gap=.05, d=1.0), .8); p(21.5, crash(1.2), .3)
p(21.65, pop(520), .45, -.4); p(21.73, pop(650), .45, .4)
for k, a in enumerate((22.6, 22.66, 22.95, 23.01, 23.07, 23.35, 23.41, 23.47)):
    p(a, musicbox([72 + k * 2], d=.6), .55, -.5 + (k % 3) * .5)
p(22.8, whoosh(.3), .25); p(23.12, whoosh(.3), .25)
p(23.55, chime([84, 91], gap=.05, d=.8), .5); p(23.7, crash(1.4), .3)
for k in range(7): p(23.6 + k * .04, pop(900 + k * 60, .06), .2)
p(24.05, pop(450, .16), .4)

# ---- CTA ----
p(25.0, boom(), .7); p(25.0, crash(), .5)
for i in range(11): p(25.15 + i * .025, pop(700 + i * 70, .08), .28, -.5 + i * .1)
p(25.55, whoosh(.3), .4); p(25.62, pop(400, .2), .6)
p(26.3, click(), 1.0, .3); p(26.3, chime([72, 76, 79, 84, 88, 91], gap=.035, d=1.6), .7); p(26.3, crash(), .45)
for k in range(12): p(26.4 + .6 * k / 12, tick(3000 + (k % 3) * 300), .6, .2)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sound.wav')
m.render(out, fade_from=28.2)
print('ok', out)
