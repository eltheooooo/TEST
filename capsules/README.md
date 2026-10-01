# Destiny Life — capsules motion design (9:16)

Série de capsules courtes qui mettent chacune en avant un aspect du jeu, dans la DA du showreel
(`../showreel`). Chaque capsule est une page HTML animée image par image (`window.render(t)`),
capturée avec Playwright puis encodée en MP4 avec une bande-son synthétisée.

| Capsule | Durée | Fichier |
|---|---|---|
| ✂️ Coiffure (salon · CAP Coiffure · carrière) | 29 s | `coiffure/DestinyLife_Capsule_Coiffure_9x16.mp4` |
| 🔧 Mécano (métier · CAP Méca Auto · carrière) | 29 s | `mecano/DestinyLife_Capsule_Mecano_9x16.mp4` |
| 👨‍👩‍👧‍👦 Famille (parents · fratrie · grands-parents · relations) | 29 s | `famille/DestinyLife_Capsule_Famille_9x16.mp4` |

## Socle commun (`common/`)
- `dl.css` : tokens et composants du jeu (bleu nuit, or, vert, cartes arrondies, boutons 3D, pastilles…)
- `dl.js` : fond animé, logo lettre par lettre, en-tête de scène, volets et whip pans, curseur de tap, confettis
- `scenes.js` : scènes prêtes à l'emploi (logo + badge FOCUS, cartons de chapitre, orientation de 3ème, liste des 11 CAP,
  diplôme, Pôle Emploi + embauche, pile d'événements (salaire ou autre valeur), CTA) et le montage (`makeMontage`) — utilisé par Mécano et Famille
- `sfx.py` : synthés de sound design (dont moteur, cliquet, rideau métallique, vérin, bips) + groove 120 BPM (`Mix`)
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
Pour une nouvelle capsule : partir de `mecano/` (qui s'appuie sur `common/scenes.js`), écrire seulement les
scènes propres au thème (accroche + 4 scènes) et brancher les scènes partagées avec les données du jeu.

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

## Capsule Mécano — découpage (120 BPM)
| Temps | Plan | Source dans le jeu |
|---|---|---|
| 0–2 s | « UN MOTEUR. UN DESTIN. » sur un rideau de garage, une voiture passe, le rideau se lève | — |
| 1,5–3,5 s | Logo + « 🔧 FOCUS MÉCANO » | — |
| 3,5–4,5 s | Chapitre 01 · Le métier | — |
| 4,5–6,5 s | Pont élévateur + valise de diagnostic (batterie, freins, huile, électronique) → « un bruit étrange » | `job_mecanique` : Premier diagnostic |
| 6,5–9 s | Inspection à la loupe → bague de cylindre usée : « Moteur mystère résolu ! » | `job_mecanique` : Moteur mystère résolu |
| 9–10,5 s | Voiture de prestige au garage (Bonheur +15, Beauté +3, Intelligence +5) | `job_mecanique` : Voiture de prestige |
| 10,5–11,5 s | Chapitre 02 · Le CAP | — |
| 11,5–17 s | Orientation → CAP Méca Auto (Mécanicien, Responsable atelier · ~1 700 €) → diplôme ADMIS | `CAP_FILIERES`, `SCHOOL.bac` |
| 17–18 s | Chapitre 03 · La carrière | — |
| 18–20,5 s | Pôle Emploi : Garage Dupont, Atelier Techno Cars, Garage Premium → embauche à 2 000 €/mois | `MECHANIC_OFFERS` |
| 20,5–23 s | Formation diagnostic, augmentation +120 €, pourboire client prestige, concours régional, +400 €/mois | `job_mecanique` |
| 23–25 s | « Marc te propose de gérer l'équipe » → promotion CHEF D'ÉQUIPE, +500 €/mois | `job_mecanique` : promotion |
| 25–29 s | CTA « Quel sera ton destin ? » ▶ JOUER · recherche « Destiny Life » | — |

## Capsule Famille — découpage (120 BPM)
| Temps | Plan | Source dans le jeu |
|---|---|---|
| 0–1,6 s | « UNE FAMILLE. UN DESTIN. » sur un album de polaroïds, « Souriez ! », déclic de l'appareil | — |
| 1,5–3,5 s | Logo + « 👨‍👩‍👧‍👦 FOCUS FAMILLE » | — |
| 3,5–4,5 s | Chapitre 01 · Ta famille | — |
| 4,5–7 s | Dé → mère et père tirés au sort (prénom, âge, métier, économies) → naissance de Léo + phrase de naissance | `CharacterFactory`, `buildBirthStory` |
| 7–9 s | « Un petit frère ! » (la cigogne repasse) → titre de grand frère, relation 64 | `EventsData.age0`, `SIBLING_INTROS` |
| 9–10,5 s | Visite des grands-parents : Mamie Rose et Papi Louis, cadeaux | `EventsData` (visite des grands-parents) |
| 10,5–11,5 s | Chapitre 02 · Les relations | — |
| 11,5–13,5 s | Fiche de maman : Parler, Câlin (+17), Jouer ensemble (+8), Secret, Se moquer | `RELATION_INTERACTIONS` |
| 13,5–15 s | « Demander de l'argent » à papi : 9 € mais −10 relation | `RelationAskMoney` |
| 15–17 s | Les années passent : −5 par an sans nouvelles, sauf avec ceux à qui on parle | `decayRelations` |
| 17–18 s | Chapitre 03 · Les moments | — |
| 18–20,5 s | Examen du frère, 50 ans de papa, enveloppe des grands-parents, question du tonton, vacances en famille | `EventsData` (adultes) |
| 20,5–22,5 s | « Famille ou amis ? » → la famille : +10 famille, +3 bonheur | `EventsData` (choix) |
| 22,5–25 s | Arbre de famille : grands-parents, parents, oncle, frère, cousine | relations du personnage |
| 25–29 s | CTA « Quel sera ton destin ? » ▶ JOUER · recherche « Destiny Life » | — |
