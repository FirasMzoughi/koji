-- ═══════════════════════════════════════════════════════════════════════════
-- KOJI — RESET tasks to PDF "Bibliothèque des Postes de Travail"
--
-- 1) DELETES ALL tasks (user + global) currently in the database
-- 2) RE-SEEDS the full PDF library (Carrelage, Peinture, Cloisons, Menuiseries,
--    Revêtements souples, Démolition, Isolation, Nettoyage) as GLOBAL tasks
--    (user_id IS NULL) so every user sees them.
--
-- Copy / paste this file ENTIRELY in Supabase → SQL Editor → Run.
-- ⚠️  DESTRUCTIVE — this wipes every existing task (PLO-02, PLO-03, PLO-04…).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 0. Wipe every existing task ─────────────────────────────────────────────
DELETE FROM tasks;

-- ── 1. Make sure required columns exist (idempotent) ────────────────────────
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS code           TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS famille        TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS sous_categorie TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS type_poste     TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS unite          TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS temps_hu       DOUBLE PRECISION;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS code_artiprix  TEXT;

ALTER TABLE tasks ALTER COLUMN user_id DROP NOT NULL;

-- ── 2. RLS (idempotent) ─────────────────────────────────────────────────────
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tasks_select" ON tasks;
CREATE POLICY "tasks_select" ON tasks FOR SELECT USING (
  user_id IS NULL OR user_id = auth.uid()
);

DROP POLICY IF EXISTS "tasks_insert" ON tasks;
CREATE POLICY "tasks_insert" ON tasks FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "tasks_update" ON tasks;
CREATE POLICY "tasks_update" ON tasks FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "tasks_delete" ON tasks;
CREATE POLICY "tasks_delete" ON tasks FOR DELETE USING (user_id = auth.uid());

-- ── 3. Seed PDF library as global tasks (user_id NULL) ──────────────────────

-- ▶ CARRELAGE — Sol
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Préparation sol complet (primaire + ragréage P3)', 'Ensemble préparatoire avant toute pose de carrelage ou revêtement souple. Temps global = somme des sous-postes.', 'Carrelage', 'CARSOL-001',    'Carrelage', 'Sol', 'POSTE',      'm²', 0.32,  '13.2.1/13.2.4', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Primaire d''accrochage (Primroxol® ou similaire)', 'Application primaire sur béton ou support absorbant. Obligatoire avant ragréage.', 'Carrelage', 'CARSOL-001-01', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.10,  '13.2.1',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Enduit de ragréage P3 – ép. 5 mm (environ 7,5 kg/m²)', 'Mise à niveau du sol, ép. 5 mm. Indispensable si sol irrégulier.', 'Carrelage', 'CARSOL-001-02', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.22,  '13.2.4',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose carrelage sol 40×40 cm – rénovation sur ancien carrelage sain', 'Travaux complets de rénovation sur support sain. Inclut préparation + pose. Fourniture carreaux non comprise.', 'Carrelage', 'CARSOL-002',    'Carrelage', 'Sol', 'POSTE',      'm²', 1.30,  '13.1.2/13.2.4', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Ragréage et lissage sol P3 – ép. 5 mm', 'Préparation support avant pose.', 'Carrelage', 'CARSOL-002-01', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.22,  '13.2.4',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose carrelage 40×40 cm simple encollage', 'Dépoussiérage, lavage, colle, coupes, joints, nettoyage. Pose sur ancien carrelage sain. Fourniture carreaux non comprise.', 'Carrelage', 'CARSOL-002-02', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.98,  '13.1.2',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Rénovation joints carrelage 40×40 cm – joint 5 mm', 'Joints au mortier alimentaire inclus dans le temps de pose.', 'Carrelage', 'CARSOL-002-03', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.10,  '13.2.15',       ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose carrelage sol 80×80 cm – support neuf (primaire + ragréage + pose double encollage)', 'Travaux complets sur support neuf. Fourniture carreaux non comprise.', 'Carrelage', 'CARSOL-003',    'Carrelage', 'Sol', 'POSTE',      'm²', 1.48,  '13.3.3',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Primaire d''accrochage (support neuf)', 'Couche primaire obligatoire sur béton neuf.', 'Carrelage', 'CARSOL-003-01', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.10,  '13.2.1',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Enduit de ragréage P3 – ép. 5 mm (support neuf)', 'Mise à niveau avant pose.', 'Carrelage', 'CARSOL-003-02', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 0.22,  '13.2.4',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose carrelage 80×80 cm – double encollage', 'Double encollage obligatoire pour grands formats. Coupes, colle, joints, nettoyage. Fourniture carreaux non comprise.', 'Carrelage', 'CARSOL-003-03', 'Carrelage', 'Sol', 'SOUS-POSTE', 'm²', 1.16,  '13.3.3',        ARRAY[]::text[], '{}'::jsonb);

-- ▶ CARRELAGE — Mur / Faïence
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Pose faïence mur 30×60 cm – salle de bains (ragréage + étanchéité + pose)', 'Travaux complets sur mur salle de bains. Fourniture carreaux non comprise.', 'Carrelage', 'CARMUR-001',    'Carrelage', 'Mur / Faïence', 'POSTE',      'm²', 1.536, '13.3.2', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Ragréage et lissage mur intérieur – ép. 5 mm', 'Mise à niveau avant pose de faïence.', 'Carrelage', 'CARMUR-001-01', 'Carrelage', 'Mur / Faïence', 'SOUS-POSTE', 'm²', 0.42,  '13.2.8', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose faïence 30×60 cm – simple encollage', 'Sous-couche étanchéité incluse. Coupes, colle, joints étanches, nettoyage. Fourniture carreaux non comprise.', 'Carrelage', 'CARMUR-001-02', 'Carrelage', 'Mur / Faïence', 'SOUS-POSTE', 'm²', 1.116, '13.3.2', ARRAY[]::text[], '{}'::jsonb);

-- ▶ CARRELAGE — Réparation
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Remplacement d''un carreau isolé 30×30 cm', 'Remplacement d''un seul carreau cassé ou décollé. Fourniture du carreau non comprise.', 'Carrelage', 'CARREP-001',    'Carrelage', 'Réparation', 'POSTE',      'u', 0.50, '13.2.12', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Dépose de l''ancien carreau + préparation support', 'Désolidarisation + nettoyage du lit de colle.', 'Carrelage', 'CARREP-001-01', 'Carrelage', 'Réparation', 'SOUS-POSTE', 'u', 0.20, '13.2.12', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose nouveau carreau (colle + joints + nettoyage)', 'Fourniture du carreau non comprise.', 'Carrelage', 'CARREP-001-02', 'Carrelage', 'Réparation', 'SOUS-POSTE', 'u', 0.30, '13.2.12', ARRAY[]::text[], '{}'::jsonb);

-- ▶ PEINTURE INTÉRIEURE — Mur
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Réfection mur complet – support dégradé (enduit + impression + 2 couches satinée)', 'Travaux complets sur mur très dégradé. Pièce non meublée.', 'Peinture', 'PEIMUR-001',    'Peinture intérieure', 'Mur', 'POSTE',      'm²', 0.785, '16.1.38',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Lessivage + rinçage + fixateur de surface', 'Préparation du fond avant enduit.', 'Peinture', 'PEIMUR-001-01', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.18,  '16.1.9',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Rebouchage + enduit de lissage (ép. 2 mm)', 'Rebouchage trous et fissures mineures, lissage.', 'Peinture', 'PEIMUR-001-02', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.18,  '16.2.x',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Enduit pelliculaire de ratissage', 'Finition avant impression, surface lisse.', 'Peinture', 'PEIMUR-001-03', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.125, '16.2.x',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Impression en phase solvant (1 couche)', 'Accrochage + régularisation de l''absorption.', 'Peinture', 'PEIMUR-001-04', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.10,  '16.3.x',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Peinture satinée aqueuse – 2 couches au rouleau', 'Finition satinée, lavable. 2 couches.', 'Peinture', 'PEIMUR-001-05', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.20,  '16.4.x',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Peinture mur – rénovation sur ancienne peinture en bon état (2 couches)', 'Sur ancienne peinture saine. Pièce non meublée. Masquage inclus.', 'Peinture', 'PEIMUR-002',    'Peinture intérieure', 'Mur', 'POSTE',      'm²', 0.373, '16.1.17',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Masquage menuiseries + plafonds + plinthes', 'Adhésif de masquage, protection surfaces adjacentes.', 'Peinture', 'PEIMUR-002-01', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.05,  '16.1.x',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Léger ponçage + lessivage + rinçage du fond', 'Préparation du support existant.', 'Peinture', 'PEIMUR-002-02', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.123, '16.1.17',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Peinture mate ou satinée aqueuse – 2 couches au rouleau', 'Finition. Nettoyage fin de chantier inclus.', 'Peinture', 'PEIMUR-002-03', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.20,  '16.1.17',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Détapissage papier peint + peinture 2 couches', 'Enchaînement complet : dépose papier peint + peinture finition. Mur en bon état après dépose.', 'Peinture', 'PEIMUR-003',    'Peinture intérieure', 'Mur', 'POSTE',      'm²', 0.573, '16.1.13/16.1.17', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Détapissage manuel – papier peint ordinaire', 'Grattage + lessivage + rinçage. Dépose papier peint standard.', 'Peinture', 'PEIMUR-003-01', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.23,  '16.1.13',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Ponçage + lessivage fond + masquage (après dépose papier)', 'Préparation avant peinture après dépose papier.', 'Peinture', 'PEIMUR-003-02', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.143, '16.1.17',         ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Peinture mate ou satinée – 2 couches au rouleau (après dépose papier)', 'Finition. Nettoyage inclus.', 'Peinture', 'PEIMUR-003-03', 'Peinture intérieure', 'Mur', 'SOUS-POSTE', 'm²', 0.20,  '16.1.17',         ARRAY[]::text[], '{}'::jsonb);

-- ▶ PEINTURE INTÉRIEURE — Plafond
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Peinture plafond – rénovation sur ancienne peinture en bon état (2 couches)', 'Pièce non meublée. Protection sols incluse.', 'Peinture', 'PEIPLF-001',    'Peinture intérieure', 'Plafond', 'POSTE',      'm²', 0.53, '16.1.1', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Protection des sols + léger ponçage plafond', 'Protection bâche + ponçage léger du plafond.', 'Peinture', 'PEIPLF-001-01', 'Peinture intérieure', 'Plafond', 'SOUS-POSTE', 'm²', 0.08, '16.1.1', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Lessivage + rinçage du fond (plafond)', 'Nettoyage du support avant peinture.', 'Peinture', 'PEIPLF-001-02', 'Peinture intérieure', 'Plafond', 'SOUS-POSTE', 'm²', 0.10, '16.1.1', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Peinture mate aqueuse plafond – 2 couches au rouleau', 'Application 2 couches, nettoyage fin de chantier inclus.', 'Peinture', 'PEIPLF-001-03', 'Peinture intérieure', 'Plafond', 'SOUS-POSTE', 'm²', 0.35, '16.1.1', ARRAY[]::text[], '{}'::jsonb);

-- ▶ CLOISONS / PLAFONDS
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Cloison BA13 – 72/48 mm + laine de verre 45 mm (distribution standard, EI 30)', 'Cloison distribution clé en main. Ossature métal, isolation, plaques, joints.', 'Plâtrerie', 'CLOCLO-001',    'Cloisons / Plafonds', 'Cloison', 'POSTE',      'm²', 0.64,  '12.2.14', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Semelle résiliente basse (isolation phonique pied de cloison)', 'Bande Phaltex® ou similaire sous le rail bas.', 'Plâtrerie', 'CLOCLO-001-01', 'Cloisons / Plafonds', 'Cloison', 'SOUS-POSTE', 'ml', 0.05,  '12.2.1',  ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Ossature métallique rail + montants, entraxe 60 cm', 'Rail haut + rail bas + montants 48 mm vissés.', 'Plâtrerie', 'CLOCLO-001-02', 'Cloisons / Plafonds', 'Cloison', 'SOUS-POSTE', 'm²', 0.18,  '12.2.13', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Laine de verre 45 mm entre montants', 'Découpe et calage de la laine entre montants.', 'Plâtrerie', 'CLOCLO-001-03', 'Cloisons / Plafonds', 'Cloison', 'SOUS-POSTE', 'm²', 0.06,  '12.2.14', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose 2 plaques BA13 vissées (1 face + 1 face) + traitement joints 2 faces', 'Vissage, calicotage, enduit de joint, ponçage 2 faces.', 'Plâtrerie', 'CLOCLO-001-04', 'Cloisons / Plafonds', 'Cloison', 'SOUS-POSTE', 'm²', 0.35,  '12.2.14', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Plafond BA13 EI 15 – vissé sur fourrure F47 (réfection ou création)', 'Plaque BA13 EI 15 sur fourrure. Ossature et isolant non compris.', 'Plâtrerie', 'CLOPLF-001',    'Cloisons / Plafonds', 'Plafond', 'POSTE',      'm²', 0.484, '12.1.8',  ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose ossature fourrure F47 (rails + suspentes)', 'Ossature porteuse du plafond.', 'Plâtrerie', 'CLOPLF-001-01', 'Cloisons / Plafonds', 'Plafond', 'SOUS-POSTE', 'm²', 0.18,  '12.1.8',  ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Vissage plaque BA13 EI 15 sur fourrure', 'Pose et vissage de la plaque.', 'Plâtrerie', 'CLOPLF-001-02', 'Cloisons / Plafonds', 'Plafond', 'SOUS-POSTE', 'm²', 0.18,  '12.1.8',  ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Traitement des joints plafond (calicot + enduit + ponçage)', 'Finition surface prête à peindre.', 'Plâtrerie', 'CLOPLF-001-03', 'Cloisons / Plafonds', 'Plafond', 'SOUS-POSTE', 'm²', 0.124, '12.1.8',  ARRAY[]::text[], '{}'::jsonb);

-- ▶ MENUISERIES INTÉRIEURES
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Fourniture et pose bloc-porte isoplane prépeint 204×83 cm', 'Fourniture + pose complète. Huisserie sapin, serrure ½ tour, paumelles, accessoires. Âme alvéolaire, cloison 70 mm.', 'Menuiserie', 'MENPOR-001',    'Menuiseries intérieures', 'Bloc-porte',    'POSTE',      'u',  1.70, '14.3.8',            ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose huisserie + calage + fixation', 'Mise à l''aplomb, scellement ou vissage de l''huisserie.', 'Menuiserie', 'MENPOR-001-01', 'Menuiseries intérieures', 'Bloc-porte',    'SOUS-POSTE', 'u',  0.60, '14.3.8',            ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose vantail + réglage paumelles + serrure', 'Ferrage, calage, réglage précis de l''ouverture.', 'Menuiserie', 'MENPOR-001-02', 'Menuiseries intérieures', 'Bloc-porte',    'SOUS-POSTE', 'u',  0.70, '14.3.8',            ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose poignée + béquille + finitions', 'Montage quincaillerie, test ouverture/fermeture.', 'Menuiserie', 'MENPOR-001-03', 'Menuiseries intérieures', 'Bloc-porte',    'SOUS-POSTE', 'u',  0.40, '14.3.8',            ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Parquet stratifié 7 mm cl. 22 + sous-couche 4 mm + plinthes MDF (pose flottante)', 'Fourniture et pose complète parquet flottant + finition plinthes. Prix plinthe calculé sur ratio 3 ML/M2.', 'Menuiserie', 'MENPAR-001',    'Menuiseries intérieures', 'Parquet / Sol', 'POSTE',      'm²', 0.47, '14.3.260/14.3.245', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose sous-couche polystyrène expansé 4 mm + pare-vapeur', 'Déroulage et découpe sous-couche.', 'Menuiserie', 'MENPAR-001-01', 'Menuiseries intérieures', 'Parquet / Sol', 'SOUS-POSTE', 'm²', 0.08, '14.3.260',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose parquet stratifié ép. 7 mm – pose flottante à clipser', 'Fourniture et pose. Classe 22 usage domestique général. Coupes, nettoyage.', 'Menuiserie', 'MENPAR-001-02', 'Menuiseries intérieures', 'Parquet / Sol', 'SOUS-POSTE', 'm²', 0.39, '14.3.260',          ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Pose plinthes MDF à peindre 14×75 mm (coupes, fixation, finitions)', 'Environ 3 ML par M2 de pièce.', 'Menuiserie', 'MENPAR-001-03', 'Menuiseries intérieures', 'Parquet / Sol', 'SOUS-POSTE', 'ml', 0.08, '14.3.245',          ARRAY[]::text[], '{}'::jsonb);

-- ▶ REVÊTEMENTS SOLS SOUPLES
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Pose revêtement vinyle lés cl. 22 – complet (dépose ancien + ragréage + pose)', 'Travaux complets sur sol existant. Fourniture vinyle incluse.', 'Revêtement sol', 'SOLVIN-001',    'Revêtements sols souples', 'Vinyle / Lino', 'POSTE',      'm²', 0.70, '19.1.1/19.1.5/19.3.1', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Arrachage moquette collée existante', 'Arrachage + mise en sac. Évacuation en supplément.', 'Revêtement sol', 'SOLVIN-001-01', 'Revêtements sols souples', 'Vinyle / Lino', 'SOUS-POSTE', 'm²', 0.15, '19.1.1',               ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Primaire + enduit de lissage P2 – ép. 2 mm', 'Ragréage indispensable pour sol souple.', 'Revêtement sol', 'SOLVIN-001-02', 'Revêtements sols souples', 'Vinyle / Lino', 'SOUS-POSTE', 'm²', 0.28, '19.1.4/19.1.5',        ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Fourniture et pose vinyle en lés cl. 22 – collée (coupes, nettoyage)', 'Vinyle dossier mousse. Prévoir 10% de chutes.', 'Revêtement sol', 'SOLVIN-001-03', 'Revêtements sols souples', 'Vinyle / Lino', 'SOUS-POSTE', 'm²', 0.25, '19.3.1',               ARRAY[]::text[], '{}'::jsonb);

-- ▶ DÉMOLITION / DÉPOSE
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Dépose carrelage sol + mise en sac (sans évacuation)', 'Dépose à la masse ou piqueur. Évacuation gravats à facturer en supplément.', 'Démolition', 'DEMSOL-001',    'Démolition / Dépose', 'Carrelage sol', 'POSTE',      'm²', 0.50, '1.x', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Dépose et cassage carrelage (masse / piqueur électrique)', 'Selon épaisseur et résistance de la colle.', 'Démolition', 'DEMSOL-001-01', 'Démolition / Dépose', 'Carrelage sol', 'SOUS-POSTE', 'm²', 0.35, '1.x', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Mise en sac des gravats sur place', 'Chargement dans sacs ou benne à proximité immédiate.', 'Démolition', 'DEMSOL-001-02', 'Démolition / Dépose', 'Carrelage sol', 'SOUS-POSTE', 'm²', 0.15, '1.x', ARRAY[]::text[], '{}'::jsonb);

-- ▶ ISOLATION
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Isolation combles par soufflage laine de verre 330 mm – R = 7,00 m².K/W', 'Améliore fortement le DPE. Soufflage mécanique.', 'Isolation', 'ISOPLF-001',    'Isolation', 'Combles / Plafond', 'POSTE',      'm²', 0.29, '12.1.6', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Mise en place guide + protection (pare-vapeur polyéthylène)', 'Pose film plastique, calfeutrement des trappes.', 'Isolation', 'ISOPLF-001-01', 'Isolation', 'Combles / Plafond', 'SOUS-POSTE', 'm²', 0.06, '12.1.6', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Soufflage laine de verre ép. 330 mm (machine souffleuse)', 'Application mécanique uniforme, R = 7,00 m².K/W.', 'Isolation', 'ISOPLF-001-02', 'Isolation', 'Combles / Plafond', 'SOUS-POSTE', 'm²', 0.23, '12.1.6', ARRAY[]::text[], '{}'::jsonb);

-- ▶ NETTOYAGE
INSERT INTO tasks (id, user_id, title, description, profession, code, famille, sous_categorie, type_poste, unite, temps_hu, code_artiprix, image_urls, default_products) VALUES
(gen_random_uuid(), NULL, 'Nettoyage fin de chantier + évacuation petits déchets', 'Forfait demi-journée. Balayage, aspiration, vitrages, petits déchets en sac.', 'Nettoyage', 'NET-001',    'Nettoyage', 'Fin de chantier', 'POSTE',      'u', 3.00, '20.x', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Balayage + aspiration sols', 'Nettoyage général après chantier.', 'Nettoyage', 'NET-001-01', 'Nettoyage', 'Fin de chantier', 'SOUS-POSTE', 'u', 1.00, '20.x', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Nettoyage vitrages + menuiseries souillées', 'Décroutage colle, ciment, peinture sur vitres et châssis.', 'Nettoyage', 'NET-001-02', 'Nettoyage', 'Fin de chantier', 'SOUS-POSTE', 'u', 1.00, '20.x', ARRAY[]::text[], '{}'::jsonb),
(gen_random_uuid(), NULL, 'Mise en sac + chargement petits déchets (≤ 1 m³)', 'Évacuation déchets légers. Benne à facturer si volume important.', 'Nettoyage', 'NET-001-03', 'Nettoyage', 'Fin de chantier', 'SOUS-POSTE', 'u', 1.00, '20.x', ARRAY[]::text[], '{}'::jsonb);

-- ── Vérification ────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM tasks;            -- doit retourner 57
-- SELECT code, title, profession FROM tasks ORDER BY code;
