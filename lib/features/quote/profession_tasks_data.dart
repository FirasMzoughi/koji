

class TaskCategory {
  final String title;
  final List<TaskItem> tasks;

  TaskCategory({required this.title, required this.tasks});
}

class TaskItem {
  final String id;
  final String label;

  TaskItem({required this.id, required this.label});
}

// Profession-specific task data
final Map<String, List<TaskCategory>> professionTasksData = {
  'Peintre': [
    TaskCategory(
      title: 'PREPARATION & PROTECTION',
      tasks: [
        TaskItem(id: 'protection_sols', label: 'Protection des sols, meubles et ouvertures'),
        TaskItem(id: 'depose_elements', label: 'Dépose légère des éléments (prises, luminaires si nécessaire)'),
      ],
    ),
    TaskCategory(
      title: 'MURS & PLAFONDS',
      tasks: [
        TaskItem(id: 'prep_murs_plafonds', label: 'Préparation des murs et plafonds'),
        TaskItem(id: 'rebouchage_trous', label: 'Rebouchage des trous et fissures'),
        TaskItem(id: 'enduit_lissage', label: 'Application d\'enduit de lissage'),
        TaskItem(id: 'poncage', label: 'Ponçage des surfaces'),
        TaskItem(id: 'depoussierage', label: 'Dépoussiérage'),
        TaskItem(id: 'sous_couche', label: 'Application d\'une sous-couche d\'impression'),
        TaskItem(id: 'peinture_plafond', label: 'Peinture du plafond'),
        TaskItem(id: 'peinture_murs', label: 'Peinture des murs'),
      ],
    ),
    TaskCategory(
      title: 'PEINTURE & FINITIONS',
      tasks: [
        TaskItem(id: 'peinture_couche_1', label: 'Application de la première couche de peinture'),
        TaskItem(id: 'peinture_couche_2', label: 'Application de la seconde couche de peinture'),
        TaskItem(id: 'finition_supp', label: 'Application de couches de finition si nécessaire'),
        TaskItem(id: 'boiseries', label: 'Peinture des boiseries (portes, plinthes, encadrements)'),
        TaskItem(id: 'peinture_radiateurs', label: 'Peinture des radiateurs'),
        TaskItem(id: 'peinture_volets', label: 'Peinture des volets'),
        TaskItem(id: 'reprises', label: 'Reprises et retouches'),
        TaskItem(id: 'pose_papier_peint', label: 'Pose de papier peint'),
      ],
    ),
    TaskCategory(
      title: 'NETTOYAGE & FIN',
      tasks: [
        TaskItem(id: 'finitions_nettes', label: 'Finitions nettes autour des meubles et éléments fixés'),
        TaskItem(id: 'nettoyage', label: 'Nettoyage du chantier'),
        TaskItem(id: 'evacuation', label: 'Évacuation des déchets'),
      ],
    ),
  ],
  
  'Électricien': [
    TaskCategory(
      title: 'PREPARATION & DIAGNOSTIC',
      tasks: [
        TaskItem(id: 'diag_elec', label: 'Diagnostic électrique'),
        TaskItem(id: 'protection_elec', label: 'Protection du chantier'),
      ],
    ),
    TaskCategory(
      title: 'INSTALLATION ÉLECTRIQUE',
      tasks: [
        TaskItem(id: 'tableau_elec', label: 'Installation/Mise à jour du tableau électrique'),
        TaskItem(id: 'prises_elec', label: 'Installation des prises et interrupteurs'),
        TaskItem(id: 'prises_usb', label: 'Installation des prises USB'),
        TaskItem(id: 'luminaires', label: 'Installation des luminaires'),
        TaskItem(id: 'spots_led', label: 'Installation des spots LED encastrables'),
        TaskItem(id: 'cable_elec', label: 'Passage de câbles'),
        TaskItem(id: 'gaines_elec', label: 'Pose de gaines électriques'),
        TaskItem(id: 'variateurs', label: 'Installation de variateurs'),
        TaskItem(id: 'detecteurs_mouvement', label: 'Installation de détecteurs de mouvement'),
      ],
    ),
    TaskCategory(
      title: 'MISE AUX NORMES',
      tasks: [
        TaskItem(id: 'terre_elec', label: 'Mise à la terre'),
        TaskItem(id: 'differentiel', label: 'Installation différentiel'),
        TaskItem(id: 'disjoncteurs', label: 'Installation des disjoncteurs'),
        TaskItem(id: 'parafoudre', label: 'Installation parafoudre'),
      ],
    ),
    TaskCategory(
      title: 'TESTS & FINITIONS',
      tasks: [
        TaskItem(id: 'test_elec', label: 'Tests et vérifications'),
        TaskItem(id: 'nettoyage_elec', label: 'Nettoyage du chantier'),
      ],
    ),
  ],
  
  'Plombier': [
    TaskCategory(
      title: 'DIAGNOSTIC & PREPARATION',
      tasks: [
        TaskItem(id: 'diag_plomb', label: 'Diagnostic plomberie'),
        TaskItem(id: 'protection_plomb', label: 'Protection du chantier'),
      ],
    ),
    TaskCategory(
      title: 'INSTALLATION SANITAIRE',
      tasks: [
        TaskItem(id: 'wc_install', label: 'Installation WC'),
        TaskItem(id: 'wc_suspendu', label: 'Installation WC suspendu'),
        TaskItem(id: 'lavabo_install', label: 'Installation lavabo/vasque'),
        TaskItem(id: 'douche_install', label: 'Installation douche/baignoire'),
        TaskItem(id: 'receveur_douche', label: 'Installation receveur de douche'),
        TaskItem(id: 'robinet_install', label: 'Installation robinetterie'),
        TaskItem(id: 'mitigeur_thermostatique', label: 'Installation mitigeur thermostatique'),
      ],
    ),
    TaskCategory(
      title: 'RACCORDEMENTS',
      tasks: [
        TaskItem(id: 'eau_froide', label: 'Raccordement eau froide'),
        TaskItem(id: 'eau_chaude', label: 'Raccordement eau chaude'),
        TaskItem(id: 'evacuation_plomb', label: 'Raccordement évacuation'),
        TaskItem(id: 'chauffe_eau', label: 'Installation chauffe-eau'),
        TaskItem(id: 'tuyauterie_cuivre', label: 'Pose tuyauterie cuivre'),
        TaskItem(id: 'tuyauterie_per', label: 'Pose tuyauterie PER'),
      ],
    ),
    TaskCategory(
      title: 'TESTS & FINITIONS',
      tasks: [
        TaskItem(id: 'test_etancheite', label: 'Tests d\'étanchéité'),
        TaskItem(id: 'nettoyage_plomb', label: 'Nettoyage du chantier'),
      ],
    ),
  ],
  
  'Carreleur': [
    TaskCategory(
      title: 'PREPARATION DES SUPPORTS',
      tasks: [
        TaskItem(id: 'prep_sol', label: 'Préparation du sol'),
        TaskItem(id: 'ragreage', label: 'Ragréage'),
        TaskItem(id: 'primaire', label: 'Application primaire d\'accrochage'),
      ],
    ),
    TaskCategory(
      title: 'POSE DU CARRELAGE',
      tasks: [
        TaskItem(id: 'trace_carrelage', label: 'Traçage et calepinage'),
        TaskItem(id: 'pose_carreaux', label: 'Pose des carreaux'),
        TaskItem(id: 'pose_faience', label: 'Pose de faïence murale'),
        TaskItem(id: 'decoupe', label: 'Découpes spéciales'),
        TaskItem(id: 'pose_mosaique', label: 'Pose de mosaïque'),
      ],
    ),
    TaskCategory(
      title: 'JOINTS & FINITIONS',
      tasks: [
        TaskItem(id: 'joints_carrelage', label: 'Réalisation des joints'),
        TaskItem(id: 'joints_epoxy', label: 'Joints époxy pour zones humides'),
        TaskItem(id: 'silicone', label: 'Joints silicone'),
        TaskItem(id: 'nettoyage_joints', label: 'Nettoyage des joints'),
      ],
    ),
    TaskCategory(
      title: 'NETTOYAGE',
      tasks: [
        TaskItem(id: 'nettoyage_carrelage', label: 'Nettoyage final'),
      ],
    ),
  ],
  
  'Menuisier': [
    TaskCategory(
      title: 'PRISE DE MESURES',
      tasks: [
        TaskItem(id: 'mesures', label: 'Prise de mesures précises'),
        TaskItem(id: 'devis_menuiserie', label: 'Établissement devis'),
      ],
    ),
    TaskCategory(
      title: 'FABRICATION/INSTALLATION',
      tasks: [
        TaskItem(id: 'porte_install', label: 'Installation portes'),
        TaskItem(id: 'porte_coulissante', label: 'Installation portes coulissantes'),
        TaskItem(id: 'fenetre_install', label: 'Installation fenêtres'),
        TaskItem(id: 'placard_install', label: 'Installation placards'),
        TaskItem(id: 'parquet_install', label: 'Pose parquet'),
        TaskItem(id: 'parquet_massif', label: 'Pose parquet massif'),
        TaskItem(id: 'plinthe_install', label: 'Pose de plinthes'),
        TaskItem(id: 'escalier', label: 'Fabrication/Installation escalier'),
      ],
    ),
    TaskCategory(
      title: 'AJUSTEMENTS',
      tasks: [
        TaskItem(id: 'ajust_menuiserie', label: 'Ajustements et réglages'),
        TaskItem(id: 'quincaillerie', label: 'Pose quincaillerie'),
        TaskItem(id: 'serrures', label: 'Installation serrures'),
        TaskItem(id: 'poignees', label: 'Pose poignées'),
      ],
    ),
    TaskCategory(
      title: 'FINITIONS',
      tasks: [
        TaskItem(id: 'vernis_menuiserie', label: 'Vernissage/Lasure'),
        TaskItem(id: 'vitrification_parquet', label: 'Vitrification parquet'),
        TaskItem(id: 'sous_couche_parquet', label: 'Pose sous-couche parquet'),
        TaskItem(id: 'nettoyage_menuiserie', label: 'Nettoyage'),
      ],
    ),
  ],
};

// Get tasks for a specific profession
List<TaskCategory> getTasksForProfession(String? profession) {
  if (profession == null) {
    return professionTasksData['Peintre'] ?? [];
  }
  
  // "Tout corps d'état" gets all tasks
  if (profession == "Tout corps d'état") {
    final allTasks = <TaskCategory>[];
    professionTasksData.forEach((key, value) {
      if (key != "Tout corps d'état") {
        allTasks.addAll(value);
      }
    });
    return allTasks;
  }
  
  return professionTasksData[profession] ?? professionTasksData['Peintre'] ?? [];
}
