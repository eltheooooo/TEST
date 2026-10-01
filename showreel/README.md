# Destiny Life — Showreel motion design (9:16, 15 s)

- `DestinyLife_Showreel_9x16.mp4` : vidéo finale 1080×1920, 60 i/s, H.264 + AAC (−14 LUFS)
- `cover.png` : dernière image (CTA), utilisable comme miniature

## Découpage (120 BPM, coupes sur les temps)
| Temps | Plan |
|---|---|
| 0–1,5 s | Accroche « 1 VIE. MILLE DESTINS. » + explosion d'emojis |
| 1,5–3 s | Logo DestinyLife + « Chaque choix compte ! » |
| 3–4,5 s | 01 Naissance : fiche perso, stats, VIEILLIR 0 → 18 ans |
| 4,5–6 s | 02 Événements : « La tentation de sécher les cours », choix, conséquences |
| 6–7,5 s | 03 La ville : Boulangerie, Coiffeur, Cinéma, Fleuriste, Poissonnerie, Banque |
| 7,5–9 s | 04 Réseaux : YouTube, Instagram, Meeter |
| 9–10,5 s | 05 Carrière & banque : métier, Livret A, ETF |
| 10,5–12 s | 06 Classements du jour |
| 12–15 s | CTA « Quel sera ton destin ? » ▶ JOUER, recherche « Destiny Life » sur Roblox |

Charte reprise du jeu : bleu nuit #10233F / #1A3157 → #2A1850, or #F5B942, vert #10B981, violet #6D4AFF,
cyan #19A9E8, rose #EC4899, police Fredoka One (+ Montserrat pour Gotham).

## Régénérer
```
cd source
NODE_PATH=$(npm root -g) node capture.js 60 frames 0-900   # images (Playwright/Chromium)
pip install numpy && python3 sound.py                      # bande-son synthétisée
bash encode.sh                                             # MP4 final
```
Tout le minutage est dans `reel.html` (fonction `render(t)`).
