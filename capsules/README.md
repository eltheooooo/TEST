# Destiny Life — capsules motion design (9:16)

Série de capsules courtes qui mettent chacune en avant un aspect du jeu, dans la DA du showreel
(`../showreel`). Chaque capsule est une page HTML animée image par image (`window.render(t)`),
capturée avec Playwright puis encodée en MP4 avec une bande-son synthétisée.

| Capsule | Durée | Fichier |
|---|---|---|
| ✂️ Coiffure (salon · CAP Coiffure · carrière) | 29 s | `coiffure/DestinyLife_Capsule_Coiffure_9x16.mp4` |

## Socle commun (`common/`)
- `dl.css` : tokens et composants du jeu (bleu nuit, or, vert, cartes arrondies, boutons 3D, pastilles…)
- `dl.js` : fond animé, logo lettre par lettre, en-tête de scène, volets et whip pans, curseur de tap, confettis
- `sfx.py` : synthés de sound design + groove 120 BPM (`Mix`)
- `capture.js` / `encode.sh` : capture et encodage
- `fonts/` : Fredoka One (police du jeu) et Montserrat (à la place de Gotham)

## Fabriquer une capsule
```
cd coiffure
NODE_PATH=$(npm root -g) FRAME_EXT=jpg node ../common/capture.js capsule.html 60 /tmp/frames   # images
pip install numpy && python3 sound.py                                                         # sound.wav
bash ../common/encode.sh /tmp/frames sound.wav DestinyLife_Capsule_Coiffure_9x16.mp4 jpg 60  # MP4
```
Astuce : lancer `capture.js` sur plusieurs plages (`0-435`, `435-870`…) en parallèle accélère le rendu.
Pour une nouvelle capsule : copier `coiffure/`, garder le montage (`SCENES`, `CUTS`, `TAPS`) et
remplacer les scènes.

## Capsule Coiffure — découpage (120 BPM)
| Temps | Plan | Source dans le jeu |
|---|---|---|
| 0–2 s | « UNE COUPE. UN DESTIN. » : les ciseaux découpent l'écran | — |
| 1,5–3,5 s | Logo + « ✂️ FOCUS COIFFURE » | — |
| 3,5–4,5 s | Chapitre 01 · Le salon | Activités → Ville → Coiffeur |
| 4,5–6,5 s | Ville → tuile Coiffeur « Une nouvelle tête ? » → « Se faire coiffer · 20 € » | Main.lua, `COIFFEUR_COST` |
| 6,5–9 s | Roue des 5 issues (60 % normale, 10 % réussie / conseil / ratée / mauvais jour) | `doCoiffeurCut` (GameServer) |
| 9–10,5 s | Miroir : nouvelle coupe, Beauté +8, Bonheur +15, Relation +15, −20 € ; talent Beauté | GameServer, Talents |
| 10,5–11,5 s | Chapitre 02 · Le CAP | — |
| 11,5–13 s | Orientation fin de 3ème : générale / techno / pro (11 CAP) | Main.lua |
| 13–15 s | Liste des 11 CAP → CAP Coiffure (Coiffeur, Coloriste · ~1 400 €) | `GameData.CAP_FILIERES` |
| 15–17 s | 2 ans de formation → « CAP obtenu ! » ADMIS, Bonheur +25, parents +15 | `SCHOOL.bac` |
| 17–18 s | Chapitre 03 · La carrière | — |
| 18–20,5 s | Pôle Emploi : 6 salons → embauche au Salon de Dorothée, 1 830 €/mois | `SALON_OFFERS`, Job « accept » |
| 20,5–23 s | Événements : client célèbre, pourboire, formation ombré hair, augmentation, offre d'un autre salon | `EventsData.job_coiffure` |
| 23–25 s | « Rêve d'ouvrir ton salon » → Économiser | `EventsData.job_coiffure` |
| 25–29 s | CTA « Quel sera ton destin ? » ▶ JOUER · recherche « Destiny Life » | — |
