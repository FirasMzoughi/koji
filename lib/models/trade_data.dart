// Énumération des métiers disponibles
enum Trade {
  painter,
  electrician,
  plumber,
  tiler,
  carpenter,
  tce,
  drywall,
  masonry,
  other;

  String get displayName {
    switch (this) {
      case Trade.painter:
        return 'Peintre';
      case Trade.electrician:
        return 'Électricien';
      case Trade.plumber:
        return 'Plombier';
      case Trade.tiler:
        return 'Carreleur';
      case Trade.carpenter:
        return 'Menuisier';
      case Trade.tce:
        return 'Tout Corps d\'État';
      case Trade.drywall:
        return 'Plaquiste';
      case Trade.masonry:
        return 'Maçonnerie';
      case Trade.other:
        return 'Autre';
    }
  }
}

// Spécialisations par métier
class TradeSpecializations {
  static const Map<Trade, List<String>> specializations = {
    Trade.painter: [
      'Murs intérieurs',
      'Plafonds',
      'Finitions',
      'Ravalement de façade',
      'Sols (résine, garage)',
    ],
    Trade.electrician: [
      'Logement',
      'Tertiaire',
      'Courant fort',
      'Courant faible',
      'Domotique',
    ],
    Trade.plumber: [
      'Sanitaire',
      'Chauffage',
      'Climatisation',
      'Évacuation',
      'Gaz',
    ],
    Trade.tiler: [
      'Pose sol',
      'Pose mur',
      'Faïence',
      'Mosaïque',
    ],
    Trade.carpenter: [
      'Portes',
      'Fenêtres',
      'Placards',
      'Parquet',
      'Agencement',
    ],
    Trade.tce: [
      'Démolition',
      'Second œuvre',
      'Coordination',
      'Finitions',
    ],
    Trade.drywall: [
      'Cloisons',
      'Faux plafonds',
      'Isolation',
      'Jointage',
    ],
    Trade.masonry: [
      'Petits travaux',
      'Ouverture/Rebouchage',
      'Chape',
      'Reprises',
    ],
  };

  static List<String> getSpecializations(Trade trade) {
    return specializations[trade] ?? [];
  }
}

// Unités de mesure pour les postes
enum JobUnit {
  squareMeter,
  linearMeter,
  unit,
  flatRate;

  String get displayName {
    switch (this) {
      case JobUnit.squareMeter:
        return 'm²';
      case JobUnit.linearMeter:
        return 'ml';
      case JobUnit.unit:
        return 'unité';
      case JobUnit.flatRate:
        return 'forfait';
    }
  }
}

// Modèle pour un poste de travail
class JobPost {
  final String id;
  final String name;
  final JobUnit unit;
  final double quantity;
  final double laborPrice;
  final double suppliesPrice;

  JobPost({
    required this.id,
    required this.name,
    required this.unit,
    this.quantity = 0,
    this.laborPrice = 0,
    this.suppliesPrice = 0,
  });

  double get totalHT => (laborPrice + suppliesPrice) * quantity;

  JobPost copyWith({
    String? id,
    String? name,
    JobUnit? unit,
    double? quantity,
    double? laborPrice,
    double? suppliesPrice,
  }) {
    return JobPost(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      laborPrice: laborPrice ?? this.laborPrice,
      suppliesPrice: suppliesPrice ?? this.suppliesPrice,
    );
  }
}

// Postes par défaut par métier
class DefaultJobPosts {
  static List<String> getPainterPosts() => [
        'Murs intérieurs',
        'Plafonds',
        'Boiseries / Portes',
        'Façades / Ravalement',
        'Sols (résine, garage)',
      ];

  static List<String> getPlumberPosts() => [
        'Points d\'eau',
        'Salle de bain',
        'WC',
        'Chauffe-eau',
        'Évacuation',
      ];

  static List<String> getElectricianPosts() => [
        'Installation neuve',
        'Rénovation',
        'Prises électriques',
        'Points lumineux',
        'Tableau électrique',
      ];

  static List<String> getTilerPosts() => [
        'Pose sol',
        'Pose mur',
        'Dépose ancienne',
        'Plinthes',
      ];

  static List<String> getCarpenterPosts() => [
        'Portes',
        'Fenêtres',
        'Placards',
        'Parquet',
      ];

  static List<String> getTCEPosts() => [
        'Démolition',
        'Second œuvre',
        'Coordination',
        'Finitions',
        'Peinture',
        'Électricité',
        'Menuiserie',
        'Maçonnerie',
        'Plomberie',
        'Carrelage',
      ];

  static List<String> getDrywallPosts() => [
        'Cloisons',
        'Faux plafonds',
        'Jointage',
        'Ponçage',
        'Finitions',
      ];

  static List<String> getMasonryPosts() => [
        'Petits travaux',
        'Ouverture / Rebouchage',
        'Chape',
        'Reprises légères',
      ];

  static List<String> getPostsForTrade(Trade trade) {
    switch (trade) {
      case Trade.painter:
        return getPainterPosts();
      case Trade.plumber:
        return getPlumberPosts();
      case Trade.electrician:
        return getElectricianPosts();
      case Trade.tiler:
        return getTilerPosts();
      case Trade.carpenter:
        return getCarpenterPosts();
      case Trade.tce:
        return getTCEPosts();
      case Trade.drywall:
        return getDrywallPosts();
      case Trade.masonry:
        return getMasonryPosts();
      default:
        return [];
    }
  }
}

// Tâches détaillées par métier
class DefaultTasks {
  static List<String> getPainterTasks() => [
        'Protection des sols et meubles',
        'Préparation des surfaces',
        'Rebouchage et ponçage',
        'Application sous-couche',
        'Peinture (1ère couche)',
        'Peinture (2ème couche)',
        'Finitions',
        'Nettoyage du chantier',
      ];

  static List<String> getPlumberTasks() => [
        'Traçage et repérage',
        'Perçage et saignées',
        'Pose des canalisations',
        'Raccordements',
        'Tests d\'étanchéité',
        'Pose des équipements',
        'Mise en service',
        'Nettoyage',
      ];

  static List<String> getElectricianTasks() => [
        'Traçage du réseau',
        'Saignées et perçages',
        'Pose des gaines',
        'Tirage des câbles',
        'Pose des appareillages',
        'Raccordement au tableau',
        'Tests et vérifications',
        'Mise en conformité',
      ];

  static List<String> getTilerTasks() => [
        'Préparation du support',
        'Traçage et calepinage',
        'Préparation du mortier-colle',
        'Pose des carreaux',
        'Découpes',
        'Joints',
        'Nettoyage',
        'Protection',
      ];

  static List<String> getCarpenterTasks() => [
        'Prise de mesures',
        'Préparation des supports',
        'Pose des huisseries',
        'Réglages',
        'Finitions',
        'Quincaillerie',
        'Nettoyage',
      ];

  static List<String> getTCETasks() => [
        'Coordination des corps d\'état',
        'Démolition si nécessaire',
        'Gros œuvre',
        'Second œuvre',
        'Finitions',
        'Nettoyage général',
      ];

  static List<String> getDrywallTasks() => [
        'Traçage',
        'Pose des rails',
        'Pose des montants',
        'Pose des plaques',
        'Bandes et enduit',
        'Ponçage',
        'Finitions',
      ];

  static List<String> getMasonryTasks() => [
        'Préparation du chantier',
        'Démolition partielle si besoin',
        'Maçonnerie',
        'Chape / Ragréage',
        'Finitions',
        'Nettoyage',
      ];

  static List<String> getTasksForTrade(Trade trade) {
    switch (trade) {
      case Trade.painter:
        return getPainterTasks();
      case Trade.plumber:
        return getPlumberTasks();
      case Trade.electrician:
        return getElectricianTasks();
      case Trade.tiler:
        return getTilerTasks();
      case Trade.carpenter:
        return getCarpenterTasks();
      case Trade.tce:
        return getTCETasks();
      case Trade.drywall:
        return getDrywallTasks();
      case Trade.masonry:
        return getMasonryTasks();
      default:
        return [];
    }
  }
}

// Modèle pour une tâche
class Task {
  final String id;
  final String name;
  final bool isCompleted;
  final bool isCustom;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.isCustom = false,
  });

  Task copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    bool? isCustom,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
