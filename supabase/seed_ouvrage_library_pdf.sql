-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — Bibliothèque d'ouvrages : seed from PDF
-- "Bibliothèque des Postes de Travail – Catalogue chiffré"
--
-- Inserts the 62 PDF ouvrages for EVERY user in auth.users.
-- Each user gets their own editable copy.
--
-- ▶ HOW TO RUN
--   Open Supabase → SQL Editor → New query → paste this file → Run.
--
-- ⚠️  For each user, wipes their current ouvrage library and replaces it
--    with the PDF library. Users lose any ouvrages they had created.
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_uid       uuid;
  v_count_in  int := 0;
  v_count_usr int := 0;
BEGIN
  -- ── 1) Wipe every user's library ─────────────────────────────────────────
  DELETE FROM ouvrage_library;

  -- ── 2) For each user, insert the 62 PDF ouvrages ─────────────────────────
  FOR v_uid IN SELECT id FROM auth.users LOOP
    INSERT INTO ouvrage_library
      (user_id, code, designation, famille, unite, temps_hu, commentaire)
    VALUES
    -- ▶ CARRELAGE — Sol
    (v_uid, 'CARSOL-001',    'Préparation sol complet (primaire + ragréage P3)',                                                   'Carrelage', 'm²', 0.32,  'Ensemble préparatoire avant toute pose de carrelage ou revêtement souple. Temps global = somme des sous-postes.'),
    (v_uid, 'CARSOL-001-01', 'Primaire d''accrochage (Primroxol® ou similaire)',                                                   'Carrelage', 'm²', 0.10,  'Application primaire sur béton ou support absorbant. Obligatoire avant ragréage.'),
    (v_uid, 'CARSOL-001-02', 'Enduit de ragréage P3 – ép. 5 mm (environ 7,5 kg/m²)',                                               'Carrelage', 'm²', 0.22,  'Mise à niveau du sol, ép. 5 mm. Indispensable si sol irrégulier.'),
    (v_uid, 'CARSOL-002',    'Pose carrelage sol 40×40 cm – rénovation sur ancien carrelage sain',                                 'Carrelage', 'm²', 1.30,  'Travaux complets de rénovation sur support sain. Inclut préparation + pose. Fourniture carreaux non comprise.'),
    (v_uid, 'CARSOL-002-01', 'Ragréage et lissage sol P3 – ép. 5 mm',                                                              'Carrelage', 'm²', 0.22,  'Préparation support avant pose.'),
    (v_uid, 'CARSOL-002-02', 'Pose carrelage 40×40 cm simple encollage (dépoussiérage, lavage, colle, coupes, joints, nettoyage)', 'Carrelage', 'm²', 0.98,  'Pose sur ancien carrelage sain. Fourniture carreaux non comprise.'),
    (v_uid, 'CARSOL-002-03', 'Rénovation joints carrelage 40×40 cm – joint 5 mm',                                                  'Carrelage', 'm²', 0.10,  'Joints au mortier alimentaire inclus dans le temps de pose.'),
    (v_uid, 'CARSOL-003',    'Pose carrelage sol 80×80 cm – support neuf (primaire + ragréage + pose double encollage)',           'Carrelage', 'm²', 1.48,  'Travaux complets sur support neuf. Fourniture carreaux non comprise.'),
    (v_uid, 'CARSOL-003-01', 'Primaire d''accrochage (support neuf)',                                                              'Carrelage', 'm²', 0.10,  'Couche primaire obligatoire sur béton neuf.'),
    (v_uid, 'CARSOL-003-02', 'Enduit de ragréage P3 – ép. 5 mm (support neuf)',                                                    'Carrelage', 'm²', 0.22,  'Mise à niveau avant pose.'),
    (v_uid, 'CARSOL-003-03', 'Pose carrelage 80×80 cm – double encollage (coupes, colle, joints, nettoyage)',                      'Carrelage', 'm²', 1.16,  'Double encollage obligatoire pour grands formats. Fourniture carreaux non comprise.'),

    -- ▶ CARRELAGE — Mur / Faïence
    (v_uid, 'CARMUR-001',    'Pose faïence mur 30×60 cm – salle de bains (ragréage + étanchéité + pose)',                          'Carrelage', 'm²', 1.536, 'Travaux complets sur mur salle de bains. Fourniture carreaux non comprise.'),
    (v_uid, 'CARMUR-001-01', 'Ragréage et lissage mur intérieur – ép. 5 mm',                                                       'Carrelage', 'm²', 0.42,  'Mise à niveau avant pose de faïence.'),
    (v_uid, 'CARMUR-001-02', 'Pose faïence 30×60 cm – simple encollage (coupes, colle, joints étanches, nettoyage)',               'Carrelage', 'm²', 1.116, 'Sous-couche étanchéité incluse. Fourniture carreaux non comprise.'),

    -- ▶ CARRELAGE — Réparation
    (v_uid, 'CARREP-001',    'Remplacement d''un carreau isolé 30×30 cm',                                                          'Carrelage', 'u',  0.50,  'Remplacement d''un seul carreau cassé ou décollé. Fourniture du carreau non comprise.'),
    (v_uid, 'CARREP-001-01', 'Dépose de l''ancien carreau + préparation support',                                                  'Carrelage', 'u',  0.20,  'Désolidarisation + nettoyage du lit de colle.'),
    (v_uid, 'CARREP-001-02', 'Pose nouveau carreau (colle + joints + nettoyage)',                                                  'Carrelage', 'u',  0.30,  'Fourniture du carreau non comprise.'),

    -- ▶ PEINTURE INTÉRIEURE — Mur
    (v_uid, 'PEIMUR-001',    'Réfection mur complet – support dégradé (enduit + impression + 2 couches satinée)',                  'Peinture intérieure', 'm²', 0.785, 'Travaux complets sur mur très dégradé. Pièce non meublée.'),
    (v_uid, 'PEIMUR-001-01', 'Lessivage + rinçage + fixateur de surface',                                                          'Peinture intérieure', 'm²', 0.18,  'Préparation du fond avant enduit.'),
    (v_uid, 'PEIMUR-001-02', 'Rebouchage + enduit de lissage (ép. 2 mm)',                                                          'Peinture intérieure', 'm²', 0.18,  'Rebouchage trous et fissures mineures, lissage.'),
    (v_uid, 'PEIMUR-001-03', 'Enduit pelliculaire de ratissage',                                                                   'Peinture intérieure', 'm²', 0.125, 'Finition avant impression, surface lisse.'),
    (v_uid, 'PEIMUR-001-04', 'Impression en phase solvant (1 couche)',                                                             'Peinture intérieure', 'm²', 0.10,  'Accrochage + régularisation de l''absorption.'),
    (v_uid, 'PEIMUR-001-05', 'Peinture satinée aqueuse – 2 couches au rouleau',                                                    'Peinture intérieure', 'm²', 0.20,  'Finition satinée, lavable. 2 couches.'),
    (v_uid, 'PEIMUR-002',    'Peinture mur – rénovation sur ancienne peinture en bon état (2 couches)',                            'Peinture intérieure', 'm²', 0.373, 'Sur ancienne peinture saine. Pièce non meublée. Masquage inclus.'),
    (v_uid, 'PEIMUR-002-01', 'Masquage menuiseries + plafonds + plinthes',                                                         'Peinture intérieure', 'm²', 0.05,  'Adhésif de masquage, protection surfaces adjacentes.'),
    (v_uid, 'PEIMUR-002-02', 'Léger ponçage + lessivage + rinçage du fond',                                                        'Peinture intérieure', 'm²', 0.123, 'Préparation du support existant.'),
    (v_uid, 'PEIMUR-002-03', 'Peinture mate ou satinée aqueuse – 2 couches au rouleau',                                            'Peinture intérieure', 'm²', 0.20,  'Finition. Nettoyage fin de chantier inclus.'),
    (v_uid, 'PEIMUR-003',    'Détapissage papier peint + peinture 2 couches (mur en bon état après dépose)',                       'Peinture intérieure', 'm²', 0.573, 'Enchaînement complet : dépose papier peint + peinture finition.'),
    (v_uid, 'PEIMUR-003-01', 'Détapissage manuel – papier peint ordinaire (grattage + lessivage + rinçage)',                       'Peinture intérieure', 'm²', 0.23,  'Dépose papier peint standard.'),
    (v_uid, 'PEIMUR-003-02', 'Ponçage + lessivage fond + masquage (après dépose papier)',                                          'Peinture intérieure', 'm²', 0.143, 'Préparation avant peinture après dépose papier.'),
    (v_uid, 'PEIMUR-003-03', 'Peinture mate ou satinée – 2 couches au rouleau (après dépose papier)',                              'Peinture intérieure', 'm²', 0.20,  'Finition. Nettoyage inclus.'),

    -- ▶ PEINTURE INTÉRIEURE — Plafond
    (v_uid, 'PEIPLF-001',    'Peinture plafond – rénovation sur ancienne peinture en bon état (2 couches)',                        'Peinture intérieure', 'm²', 0.53,  'Pièce non meublée. Protection sols incluse.'),
    (v_uid, 'PEIPLF-001-01', 'Protection des sols + léger ponçage (plafond)',                                                      'Peinture intérieure', 'm²', 0.08,  'Protection bâche + ponçage léger du plafond.'),
    (v_uid, 'PEIPLF-001-02', 'Lessivage + rinçage du fond (plafond)',                                                              'Peinture intérieure', 'm²', 0.10,  'Nettoyage du support avant peinture.'),
    (v_uid, 'PEIPLF-001-03', 'Peinture mate aqueuse plafond – 2 couches au rouleau',                                               'Peinture intérieure', 'm²', 0.35,  'Application 2 couches, nettoyage fin de chantier inclus.'),

    -- ▶ CLOISONS / PLAFONDS
    (v_uid, 'CLOCLO-001',    'Cloison BA13 – 72/48 mm + laine de verre 45 mm (distribution standard, EI 30)',                      'Cloisons / Plafonds', 'm²', 0.64,  'Cloison distribution clé en main. Ossature métal, isolation, plaques, joints.'),
    (v_uid, 'CLOCLO-001-01', 'Semelle résiliente basse (isolation phonique pied de cloison)',                                      'Cloisons / Plafonds', 'ml', 0.05,  'Bande Phaltex® ou similaire sous le rail bas.'),
    (v_uid, 'CLOCLO-001-02', 'Ossature métallique rail + montants, entraxe 60 cm',                                                 'Cloisons / Plafonds', 'm²', 0.18,  'Rail haut + rail bas + montants 48 mm vissés.'),
    (v_uid, 'CLOCLO-001-03', 'Laine de verre 45 mm entre montants',                                                                'Cloisons / Plafonds', 'm²', 0.06,  'Découpe et calage de la laine entre montants.'),
    (v_uid, 'CLOCLO-001-04', 'Pose 2 plaques BA13 vissées (1 face + 1 face) + traitement joints 2 faces',                          'Cloisons / Plafonds', 'm²', 0.35,  'Vissage, calicotage, enduit de joint, ponçage 2 faces.'),
    (v_uid, 'CLOPLF-001',    'Plafond BA13 EI 15 – vissé sur fourrure F47 (réfection ou création)',                                'Cloisons / Plafonds', 'm²', 0.484, 'Plaque BA13 EI 15 sur fourrure. Ossature et isolant non compris.'),
    (v_uid, 'CLOPLF-001-01', 'Pose ossature fourrure F47 (rails + suspentes)',                                                     'Cloisons / Plafonds', 'm²', 0.18,  'Ossature porteuse du plafond.'),
    (v_uid, 'CLOPLF-001-02', 'Vissage plaque BA13 EI 15 sur fourrure',                                                             'Cloisons / Plafonds', 'm²', 0.18,  'Pose et vissage de la plaque.'),
    (v_uid, 'CLOPLF-001-03', 'Traitement des joints plafond (calicot + enduit + ponçage)',                                         'Cloisons / Plafonds', 'm²', 0.124, 'Finition surface prête à peindre.'),

    -- ▶ MENUISERIES INTÉRIEURES
    (v_uid, 'MENPOR-001',    'Fourniture et pose bloc-porte isoplane pré-peint 204×83 cm (âme alvéolaire, cloison 70 mm)',         'Menuiseries intérieures', 'u',  1.70, 'Fourniture + pose complète. Huisserie sapin, serrure ½ tour, paumelles, accessoires.'),
    (v_uid, 'MENPOR-001-01', 'Pose huisserie + calage + fixation',                                                                 'Menuiseries intérieures', 'u',  0.60, 'Mise à l''aplomb, scellement ou vissage de l''huisserie.'),
    (v_uid, 'MENPOR-001-02', 'Pose vantail + réglage paumelles + serrure',                                                         'Menuiseries intérieures', 'u',  0.70, 'Ferrage, calage, réglage précis de l''ouverture.'),
    (v_uid, 'MENPOR-001-03', 'Pose poignée + béquille + finitions',                                                                'Menuiseries intérieures', 'u',  0.40, 'Montage quincaillerie, test ouverture/fermeture.'),
    (v_uid, 'MENPAR-001',    'Parquet stratifié 7 mm cl. 22 + sous-couche 4 mm + plinthes MDF (pose flottante)',                   'Menuiseries intérieures', 'm²', 0.47, 'Fourniture et pose complète parquet flottant + finition plinthes. Ratio 3 ML/M².'),
    (v_uid, 'MENPAR-001-01', 'Pose sous-couche polystyrène expansé 4 mm + pare-vapeur',                                            'Menuiseries intérieures', 'm²', 0.08, 'Déroulage et découpe sous-couche.'),
    (v_uid, 'MENPAR-001-02', 'Pose parquet stratifié ép. 7 mm – pose flottante à clipser (coupes, nettoyage)',                     'Menuiseries intérieures', 'm²', 0.39, 'Fourniture et pose. Classe 22 usage domestique général.'),
    (v_uid, 'MENPAR-001-03', 'Pose plinthes MDF à peindre 14×75 mm (coupes, fixation, finitions)',                                 'Menuiseries intérieures', 'ml', 0.08, 'Environ 3 ML par M² de pièce.'),

    -- ▶ REVÊTEMENTS SOLS SOUPLES
    (v_uid, 'SOLVIN-001',    'Pose revêtement vinyle lés cl. 22 – complet (dépose ancien + ragréage + pose)',                      'Revêtements sols souples', 'm²', 0.70, 'Travaux complets sur sol existant. Fourniture vinyle incluse.'),
    (v_uid, 'SOLVIN-001-01', 'Arrachage moquette collée existante',                                                                'Revêtements sols souples', 'm²', 0.15, 'Arrachage + mise en sac. Évacuation en supplément.'),
    (v_uid, 'SOLVIN-001-02', 'Primaire + enduit de lissage P2 – ép. 2 mm',                                                         'Revêtements sols souples', 'm²', 0.28, 'Ragréage indispensable pour sol souple.'),
    (v_uid, 'SOLVIN-001-03', 'Fourniture et pose vinyle en lés cl. 22 – collée (coupes, nettoyage)',                               'Revêtements sols souples', 'm²', 0.25, 'Vinyle dossier mousse. Prévoir 10% de chutes.'),

    -- ▶ DÉMOLITION / DÉPOSE
    (v_uid, 'DEMSOL-001',    'Dépose carrelage sol + mise en sac (sans évacuation)',                                               'Démolition / Dépose', 'm²', 0.50,  'Dépose à la masse ou piqueur. Évacuation gravats à facturer en supplément.'),
    (v_uid, 'DEMSOL-001-01', 'Dépose et cassage carrelage (masse / piqueur électrique)',                                           'Démolition / Dépose', 'm²', 0.35,  'Selon épaisseur et résistance de la colle.'),
    (v_uid, 'DEMSOL-001-02', 'Mise en sac des gravats sur place',                                                                  'Démolition / Dépose', 'm²', 0.15,  'Chargement dans sacs ou benne à proximité immédiate.'),

    -- ▶ ISOLATION
    (v_uid, 'ISOPLF-001',    'Isolation combles par soufflage laine de verre 330 mm – R = 7,00 m².K/W',                            'Isolation', 'm²', 0.29, 'Améliore fortement le DPE. Soufflage mécanique.'),
    (v_uid, 'ISOPLF-001-01', 'Mise en place guide + protection (pare-vapeur polyéthylène)',                                        'Isolation', 'm²', 0.06, 'Pose film plastique, calfeutrement des trappes.'),
    (v_uid, 'ISOPLF-001-02', 'Soufflage laine de verre ép. 330 mm (machine souffleuse)',                                           'Isolation', 'm²', 0.23, 'Application mécanique uniforme, R = 7,00 m².K/W.'),

    -- ▶ NETTOYAGE
    (v_uid, 'NET-001',       'Nettoyage fin de chantier + évacuation petits déchets',                                              'Nettoyage', 'u', 3.00, 'Forfait demi-journée. Balayage, aspiration, vitrages, petits déchets en sac.'),
    (v_uid, 'NET-001-01',    'Balayage + aspiration sols',                                                                         'Nettoyage', 'u', 1.00, 'Nettoyage général après chantier.'),
    (v_uid, 'NET-001-02',    'Nettoyage vitrages + menuiseries souillées',                                                         'Nettoyage', 'u', 1.00, 'Décroutage colle, ciment, peinture sur vitres et châssis.'),
    (v_uid, 'NET-001-03',    'Mise en sac + chargement petits déchets (≤ 1 m³)',                                                   'Nettoyage', 'u', 1.00, 'Évacuation déchets légers. Benne à facturer si volume important.');

    v_count_usr := v_count_usr + 1;
  END LOOP;

  SELECT COUNT(*) INTO v_count_in FROM ouvrage_library;
  RAISE NOTICE 'Done. % users seeded, % total rows inserted.', v_count_usr, v_count_in;
END $$;

-- ── Vérification ────────────────────────────────────────────────────────────
SELECT
  (SELECT COUNT(*) FROM auth.users)                                AS total_users,
  (SELECT COUNT(DISTINCT user_id) FROM ouvrage_library)            AS users_with_library,
  (SELECT COUNT(*) FROM ouvrage_library)                           AS total_ouvrages,
  (SELECT COUNT(*) FROM ouvrage_library) /
    NULLIF((SELECT COUNT(DISTINCT user_id) FROM ouvrage_library), 0) AS ouvrages_per_user;
