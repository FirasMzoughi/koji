
// --- Enums & Logic Models ---

enum InputType {
  number,
  text,
  toggle,
}

enum ConsumptionRuleType {
  fixed,        // Quantity is fixed
  perM2,        // Qty = ceil(surface * factor)
  perLinearMeter, // Qty = ceil(length * factor)
  perPiece,     // Qty = ceil(pieces * factor)
  custom,
}

class ConsumptionRule {
  final ConsumptionRuleType type;
  final double factor; // e.g. 0.1 liters per m2 -> 10m2 needs 1 liter.
  
  const ConsumptionRule({
    required this.type,
    this.factor = 1.0,
  });
}

// --- Data Models ---

/// Defines a dynamic input field required by a task (e.g. Surface, Length)
class TaskInputField {
  final String id;
  final String label;
  final String suffix; // e.g. "m²", "ml", "u"
  final InputType type;
  final double? defaultValue;

  const TaskInputField({
    required this.id,
    required this.label,
    required this.suffix,
    this.type = InputType.number,
    this.defaultValue,
  });
}

/// Represents a physical product or supply
class Product {
  final String id;
  final String name;
  final String imageUrl; // Asset or Network
  final double priceHT; 
  final String unit; // "L", "kg", "unit"
  final String packaging; // "15L", "Sac 25kg"
  final ConsumptionRule consumptionRule;
  
  // Tag/Category for filtering (Paint, Tools, etc.)
  final String category;
  final String brand;

  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.priceHT,
    required this.unit,
    this.packaging = '',
    this.consumptionRule = const ConsumptionRule(type: ConsumptionRuleType.fixed),
    this.category = 'Materiaux',
    this.brand = 'Generic',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse Consumption Rule (defaults if missing)
    final ruleTypeStr = json['consumption_rule_type'] as String? ?? 'fixed';
    final ruleFactor = (json['consumption_rule_factor'] as num?)?.toDouble() ?? 1.0;

    ConsumptionRuleType type;
    switch (ruleTypeStr) {
      case 'perM2': type = ConsumptionRuleType.perM2; break;
      case 'perLinearMeter': type = ConsumptionRuleType.perLinearMeter; break;
      case 'perPiece': type = ConsumptionRuleType.perPiece; break;
      case 'custom': type = ConsumptionRuleType.custom; break;
      default: type = ConsumptionRuleType.fixed;
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '', 
      priceHT: (json['price_ht'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'u',
      packaging: json['packaging'] as String? ?? '',
      category: json['category'] as String? ?? 'Materiaux',
      brand: json['brand'] as String? ?? 'Generic',
      consumptionRule: ConsumptionRule(type: type, factor: ruleFactor),
    );
  }
}

/// Holds the state of a specific selected task in a room
class RoomTaskState {
  final String taskId;
  final String label; 
  bool isExpanded; // UI state
  
  // Dynamic User Inputs (key: inputId, value: value)
  final Map<String, dynamic> inputs; 
  
  // Notes & Photos
  String? note;
  final List<String> photoPaths;
  
  // Selected Products for this task (with quantity overrides)
  // Map<ProductId, quantity>
  final Map<String, double> selectedProducts;

  RoomTaskState({
    required this.taskId,
    required this.label,
    this.isExpanded = false,
    Map<String, dynamic>? inputs,
    this.note,
    List<String>? photoPaths,
    Map<String, double>? selectedProducts,
  }) : 
    this.inputs = inputs ?? {},
    this.photoPaths = photoPaths ?? [],
    this.selectedProducts = selectedProducts ?? {};
    
  /// Creates a copy for immutability updates (optional if using Riverpod/State objects, 
  /// but helpers are good for setState)
  RoomTaskState copyWith({
    bool? isExpanded,
    Map<String, dynamic>? inputs,
    String? note,
    List<String>? photoPaths,
    Map<String, double>? selectedProducts,
  }) {
    return RoomTaskState(
      taskId: this.taskId,
      label: this.label,
      isExpanded: isExpanded ?? this.isExpanded,
      inputs: inputs != null ? Map.from(inputs) : Map.from(this.inputs),
      note: note ?? this.note,
      photoPaths: photoPaths != null ? List.from(photoPaths) : List.from(this.photoPaths),
      selectedProducts: selectedProducts != null ? Map.from(selectedProducts) : Map.from(this.selectedProducts),
    );
  }
}

// --- Mock Data Helpers ---


final List<Product> _allProducts = [
  // --- Peintre ---
  const Product(
    id: 'p_peinture_blanc_mat',
    name: 'Peinture Blanche Mat Premium',
    imageUrl: 'https://picsum.photos/id/10/200/200',
    priceHT: 45.90,
    unit: 'L',
    packaging: 'Pot 10L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.12),
    brand: 'Seigneurie',
    category: 'Peinture',
  ),
  const Product(
    id: 'p_peinture_velours',
    name: 'Peinture Velours Garnissante',
    imageUrl: 'https://picsum.photos/id/11/200/200',
    priceHT: 52.50,
    unit: 'L',
    packaging: 'Pot 10L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.1),
    brand: 'Tollens',
    category: 'Peinture',
  ),
  const Product(
    id: 'p_enduit_lissage',
    name: 'Enduit de Lissage en Pâte',
    imageUrl: 'https://picsum.photos/id/12/200/200',
    priceHT: 28.90,
    unit: 'kg',
    packaging: 'Seau 25kg',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.5),
    brand: 'Toupret',
    category: 'Enduit',
  ),
  const Product(
    id: 'p_rouleau',
    name: 'Rouleau Microfibre 180mm',
    imageUrl: 'https://picsum.photos/id/13/200/200',
    priceHT: 12.50,
    unit: 'u',
    brand: 'L\'Outil Parfait',
    category: 'Outillage',
  ),
  const Product(
    id: 'p_scocth',
    name: 'Ruban de Masquage Pro',
    imageUrl: 'https://picsum.photos/id/14/200/200',
    priceHT: 4.50,
    unit: 'u',
    brand: '3M',
    category: 'Consommable',
  ),
  const Product(
    id: 'p_peinture_satinee',
    name: 'Peinture Satinée Lessivable',
    imageUrl: 'https://picsum.photos/id/15/200/200',
    priceHT: 48.00,
    unit: 'L',
    packaging: 'Pot 5L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.11),
    brand: 'Dulux Valentine',
    category: 'Peinture',
  ),
  const Product(
    id: 'p_enduit_rebouchage',
    name: 'Enduit de Rebouchage Poudre',
    imageUrl: 'https://picsum.photos/id/16/200/200',
    priceHT: 12.50,
    unit: 'kg',
    packaging: 'Sac 5kg',
    brand: 'Semin',
    category: 'Enduit',
  ),
  const Product(
    id: 'p_sous_couche',
    name: 'Sous-Couche Universelle',
    imageUrl: 'https://picsum.photos/id/17/200/200',
    priceHT: 35.00,
    unit: 'L',
    packaging: 'Pot 10L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.1),
    brand: 'Julien',
    category: 'Peinture',
  ),
  const Product(
    id: 'p_pinceau',
    name: 'Pinceau Plat Professionnel 50mm',
    imageUrl: 'https://picsum.photos/id/18/200/200',
    priceHT: 8.90,
    unit: 'u',
    brand: 'Purdy',
    category: 'Outillage',
  ),
  const Product(
    id: 'p_bache_protection',
    name: 'Bâche de Protection 4x5m',
    imageUrl: 'https://picsum.photos/id/19/200/200',
    priceHT: 15.00,
    unit: 'u',
    brand: 'Tesa',
    category: 'Consommable',
  ),

  // --- Électricien ---
  const Product(
    id: 'e_cable_ro2v',
    name: 'Câble R2V 3G2.5mm²',
    imageUrl: 'https://picsum.photos/id/20/200/200',
    priceHT: 0.85,
    unit: 'm',
    packaging: 'Touret',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.1), // 10% waste
    brand: 'Nexans',
    category: 'Câblage',
  ),
  const Product(
    id: 'e_prise_courant',
    name: 'Prise de Courant 2P+T Blanche',
    imageUrl: 'https://picsum.photos/id/21/200/200',
    priceHT: 6.90,
    unit: 'u',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perPiece, factor: 1),
    brand: 'Legrand',
    category: 'Appareillage',
  ),
  const Product(
    id: 'e_interrupteur',
    name: 'Interrupteur Va-et-Vient',
    imageUrl: 'https://picsum.photos/id/22/200/200',
    priceHT: 5.50,
    unit: 'u',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perPiece, factor: 1),
    brand: 'Schneider',
    category: 'Appareillage',
  ),
  const Product(
    id: 'e_disjoncteur',
    name: 'Disjoncteur 16A Phase+Neutre',
    imageUrl: 'https://picsum.photos/id/23/200/200',
    priceHT: 9.90,
    unit: 'u',
    brand: 'Hager',
    category: 'Tableau',
  ),
  const Product(
    id: 'e_cable_1_5',
    name: 'Câble H07V-U 1.5mm²',
    imageUrl: 'https://picsum.photos/id/24/200/200',
    priceHT: 0.45,
    unit: 'm',
    packaging: 'Couronne 100m',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.1),
    brand: 'Nexans',
    category: 'Câblage',
  ),
  const Product(
    id: 'e_prise_usb',
    name: 'Prise avec USB Intégré',
    imageUrl: 'https://picsum.photos/id/25/200/200',
    priceHT: 18.50,
    unit: 'u',
    brand: 'Legrand Céliane',
    category: 'Appareillage',
  ),
  const Product(
    id: 'e_variateur',
    name: 'Variateur LED 400W',
    imageUrl: 'https://picsum.photos/id/26/200/200',
    priceHT: 24.90,
    unit: 'u',
    brand: 'Legrand',
    category: 'Appareillage',
  ),
  const Product(
    id: 'e_differentiel',
    name: 'Interrupteur Différentiel 30mA',
    imageUrl: 'https://picsum.photos/id/27/200/200',
    priceHT: 45.00,
    unit: 'u',
    brand: 'Schneider',
    category: 'Tableau',
  ),
  const Product(
    id: 'e_tableau',
    name: 'Coffret Électrique 3 Rangées',
    imageUrl: 'https://picsum.photos/id/28/200/200',
    priceHT: 85.00,
    unit: 'u',
    brand: 'Legrand',
    category: 'Tableau',
  ),
  const Product(
    id: 'e_spot_led',
    name: 'Spot LED Encastrable 7W',
    imageUrl: 'https://picsum.photos/id/29/200/200',
    priceHT: 12.90,
    unit: 'u',
    brand: 'Philips',
    category: 'Luminaire',
  ),
  const Product(
    id: 'e_plafonnier',
    name: 'Plafonnier LED 24W',
    imageUrl: 'https://picsum.photos/id/30/200/200',
    priceHT: 35.00,
    unit: 'u',
    brand: 'Osram',
    category: 'Luminaire',
  ),
  const Product(
    id: 'e_gaine_icta',
    name: 'Gaine ICTA Ø20mm',
    imageUrl: 'https://picsum.photos/id/31/200/200',
    priceHT: 0.35,
    unit: 'm',
    packaging: 'Couronne 25m',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.05),
    brand: 'Polypipe',
    category: 'Câblage',
  ),

  // --- Plombier ---
  const Product(
    id: 'pl_tuyau_cuivre',
    name: 'Tube Cuivre Ø14mm',
    imageUrl: 'https://picsum.photos/id/32/200/200',
    priceHT: 8.50,
    unit: 'm',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.05),
    brand: 'Generic',
    category: 'Tuyauterie',
  ),
  const Product(
    id: 'pl_raccord_laiton',
    name: 'Raccord Laiton à Souder',
    imageUrl: 'https://picsum.photos/id/33/200/200',
    priceHT: 2.30,
    unit: 'u',
    brand: 'Generic',
    category: 'Raccord',
  ),
  const Product(
    id: 'pl_mitigeur',
    name: 'Mitigeur Lavabo Chrome',
    imageUrl: 'https://picsum.photos/id/34/200/200',
    priceHT: 89.00,
    unit: 'u',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perPiece, factor: 1),
    brand: 'Grohe',
    category: 'Robinetterie',
  ),
  const Product(
    id: 'pl_wc_suspendu',
    name: 'Pack WC Suspendu Bati-Support',
    imageUrl: 'https://picsum.photos/id/35/200/200',
    priceHT: 250.00,
    unit: 'u',
    brand: 'Geberit',
    category: 'Sanitaire',
  ),
  const Product(
    id: 'pl_tuyau_per',
    name: 'Tube PER Ø16mm',
    imageUrl: 'https://picsum.photos/id/36/200/200',
    priceHT: 2.80,
    unit: 'm',
    packaging: 'Couronne 50m',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.05),
    brand: 'Comap',
    category: 'Tuyauterie',
  ),
  const Product(
    id: 'pl_raccord_per',
    name: 'Raccord PER à Glissement',
    imageUrl: 'https://picsum.photos/id/37/200/200',
    priceHT: 3.50,
    unit: 'u',
    brand: 'Comap',
    category: 'Raccord',
  ),
  const Product(
    id: 'pl_mitigeur_douche',
    name: 'Mitigeur Douche Thermostatique',
    imageUrl: 'https://picsum.photos/id/38/200/200',
    priceHT: 145.00,
    unit: 'u',
    brand: 'Hansgrohe',
    category: 'Robinetterie',
  ),
  const Product(
    id: 'pl_lavabo',
    name: 'Lavabo Céramique 60cm',
    imageUrl: 'https://picsum.photos/id/39/200/200',
    priceHT: 120.00,
    unit: 'u',
    brand: 'Villeroy & Boch',
    category: 'Sanitaire',
  ),
  const Product(
    id: 'pl_receveur',
    name: 'Receveur de Douche 90x90',
    imageUrl: 'https://picsum.photos/id/40/200/200',
    priceHT: 180.00,
    unit: 'u',
    brand: 'Allia',
    category: 'Sanitaire',
  ),
  const Product(
    id: 'pl_siphon',
    name: 'Siphon Lavabo Chromé',
    imageUrl: 'https://picsum.photos/id/41/200/200',
    priceHT: 15.50,
    unit: 'u',
    brand: 'Nicoll',
    category: 'Raccord',
  ),
  const Product(
    id: 'pl_chauffe_eau',
    name: 'Chauffe-eau Électrique 200L',
    imageUrl: 'https://picsum.photos/id/42/200/200',
    priceHT: 450.00,
    unit: 'u',
    brand: 'Atlantic',
    category: 'Sanitaire',
  ),

  // --- Carreleur ---
  const Product(
    id: 'c_colle_carrelage',
    name: 'Colle Carrelage Flex C2S1',
    imageUrl: 'https://picsum.photos/id/43/200/200',
    priceHT: 22.00,
    unit: 'kg',
    packaging: 'Sac 25kg',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 5.0), // 5kg/m2
    brand: 'Weber',
    category: 'Colle',
  ),
  const Product(
    id: 'c_joint',
    name: 'Mortier Joint Gris',
    imageUrl: 'https://picsum.photos/id/44/200/200',
    priceHT: 12.00,
    unit: 'kg',
    packaging: 'Sac 5kg',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.5),
    brand: 'Parexlanko',
    category: 'Joint',
  ),
  const Product(
    id: 'c_carrelage_gres',
    name: 'Carrelage Grès Cérame 60x60',
    imageUrl: 'https://picsum.photos/id/45/200/200',
    priceHT: 35.00,
    unit: 'm2',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.1),
    brand: 'Imola',
    category: 'Carrelage',
  ),
  const Product(
    id: 'c_colle_carrelage_blanc',
    name: 'Colle Carrelage Blanche C2',
    imageUrl: 'https://picsum.photos/id/46/200/200',
    priceHT: 28.00,
    unit: 'kg',
    packaging: 'Sac 25kg',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 5.0),
    brand: 'Mapei',
    category: 'Colle',
  ),
  const Product(
    id: 'c_joint_epoxy',
    name: 'Joint Époxy Blanc',
    imageUrl: 'https://picsum.photos/id/47/200/200',
    priceHT: 35.00,
    unit: 'kg',
    packaging: 'Kit 5kg',
    brand: 'Mapei',
    category: 'Joint',
  ),
  const Product(
    id: 'c_faience',
    name: 'Faïence Murale 25x40',
    imageUrl: 'https://picsum.photos/id/48/200/200',
    priceHT: 28.00,
    unit: 'm2',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.1),
    brand: 'Novoceram',
    category: 'Carrelage',
  ),
  const Product(
    id: 'c_ragreage',
    name: 'Ragréage Autolissant',
    imageUrl: 'https://picsum.photos/id/49/200/200',
    priceHT: 18.00,
    unit: 'kg',
    packaging: 'Sac 25kg',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.5),
    brand: 'Weber',
    category: 'Préparation',
  ),
  const Product(
    id: 'c_primaire',
    name: 'Primaire d\'Accrochage',
    imageUrl: 'https://picsum.photos/id/50/200/200',
    priceHT: 25.00,
    unit: 'L',
    packaging: 'Bidon 5L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.2),
    brand: 'Sika',
    category: 'Préparation',
  ),
  const Product(
    id: 'c_silicone',
    name: 'Silicone Sanitaire Transparent',
    imageUrl: 'https://picsum.photos/id/51/200/200',
    priceHT: 8.50,
    unit: 'u',
    brand: 'Rubson',
    category: 'Joint',
  ),
  const Product(
    id: 'c_croisillons',
    name: 'Croisillons Auto-Nivelants 2mm',
    imageUrl: 'https://picsum.photos/id/52/200/200',
    priceHT: 12.00,
    unit: 'u',
    packaging: 'Boîte 100pcs',
    brand: 'Rubi',
    category: 'Outillage',
  ),
  // --- Menuisier ---
  const Product(
    id: 'm_parquet',
    name: 'Parquet Contrecollé Chêne',
    imageUrl: 'https://picsum.photos/id/53/200/200',
    priceHT: 45.00,
    unit: 'm2',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.1),
    brand: 'Haro',
    category: 'Sol',
  ),
  const Product(
    id: 'm_plinthe',
    name: 'Plinthe Bois à Peindre',
    imageUrl: 'https://picsum.photos/id/54/200/200',
    priceHT: 5.50,
    unit: 'ml',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.05),
    brand: 'Orac',
    category: 'Finition',
  ),
  const Product(
    id: 'm_porte',
    name: 'Bloc Porte Intérieur',
    imageUrl: 'https://picsum.photos/id/55/200/200',
    priceHT: 120.00,
    unit: 'u',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perPiece, factor: 1),
    brand: 'Rozière',
    category: 'Ouverture',
  ),
  const Product(
    id: 'm_parquet_massif',
    name: 'Parquet Massif Chêne 14mm',
    imageUrl: 'https://picsum.photos/id/56/200/200',
    priceHT: 65.00,
    unit: 'm2',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.1),
    brand: 'Panaget',
    category: 'Sol',
  ),
  const Product(
    id: 'm_plinthe_mdf',
    name: 'Plinthe MDF Blanche 80mm',
    imageUrl: 'https://picsum.photos/id/57/200/200',
    priceHT: 3.80,
    unit: 'ml',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perLinearMeter, factor: 1.05),
    brand: 'Médium',
    category: 'Finition',
  ),
  const Product(
    id: 'm_porte_coulissante',
    name: 'Porte Coulissante avec Rail',
    imageUrl: 'https://picsum.photos/id/58/200/200',
    priceHT: 280.00,
    unit: 'u',
    brand: 'Mantion',
    category: 'Ouverture',
  ),
  const Product(
    id: 'm_fenetre_pvc',
    name: 'Fenêtre PVC 2 Vantaux',
    imageUrl: 'https://picsum.photos/id/59/200/200',
    priceHT: 450.00,
    unit: 'u',
    brand: 'Tryba',
    category: 'Ouverture',
  ),
  const Product(
    id: 'm_placard',
    name: 'Kit Placard Coulissant 2m',
    imageUrl: 'https://picsum.photos/id/60/200/200',
    priceHT: 380.00,
    unit: 'u',
    brand: 'Kazed',
    category: 'Rangement',
  ),
  const Product(
    id: 'm_sous_couche_parquet',
    name: 'Sous-Couche Parquet 3mm',
    imageUrl: 'https://picsum.photos/id/61/200/200',
    priceHT: 8.50,
    unit: 'm2',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 1.0),
    brand: 'Isover',
    category: 'Sol',
  ),
  const Product(
    id: 'm_vernis',
    name: 'Vernis Parquet Incolore',
    imageUrl: 'https://picsum.photos/id/62/200/200',
    priceHT: 42.00,
    unit: 'L',
    packaging: 'Pot 2.5L',
    consumptionRule: ConsumptionRule(type: ConsumptionRuleType.perM2, factor: 0.1),
    brand: 'Blanchon',
    category: 'Finition',
  ),
  const Product(
    id: 'm_colle_parquet',
    name: 'Colle Parquet MS Polymère',
    imageUrl: 'https://picsum.photos/id/63/200/200',
    priceHT: 35.00,
    unit: 'kg',
    packaging: 'Cartouche 290ml',
    brand: 'Sika',
    category: 'Sol',
  ),
  const Product(
    id: 'm_poignee',
    name: 'Poignée de Porte Inox',
    imageUrl: 'https://picsum.photos/id/64/200/200',
    priceHT: 18.50,
    unit: 'u',
    brand: 'Vachette',
    category: 'Quincaillerie',
  ),
  const Product(
    id: 'm_serrure',
    name: 'Serrure Encastrée 3 Points',
    imageUrl: 'https://picsum.photos/id/65/200/200',
    priceHT: 85.00,
    unit: 'u',
    brand: 'Bricard',
    category: 'Quincaillerie',
  ),
];

// Helper to get all products (for search)
List<Product> getAllProducts() => _allProducts;

/// Helper to get fields for a task category/type
List<TaskInputField> getFieldsForTask(String taskId) {
  if (taskId.contains('murs') || taskId.contains('peinture') || taskId.contains('enduit') || 
      taskId.contains('sol') || taskId.contains('carrelage') || taskId.contains('parquet') || taskId.contains('ragreage')) {
    return [
      const TaskInputField(id: 'surface', label: 'Surface', suffix: 'm²', defaultValue: 15.0),
    ];
  }
  if (taskId.contains('plinthe') || taskId.contains('cable') || taskId.contains('tuyau') || taskId.contains('froid') || taskId.contains('chaud') ) {
    return [
      const TaskInputField(id: 'length', label: 'Longueur', suffix: 'ml', defaultValue: 10.0),
    ];
  }
  if (taskId.contains('pose') || taskId.contains('install') || taskId.contains('wc') || taskId.contains('lavabo') || taskId.contains('prise') || taskId.contains('interrupteur')) {
    return [
      const TaskInputField(id: 'count', label: 'Nombre', suffix: 'u', defaultValue: 1.0),
    ];
  }
  // Default to surface if unsure, or nothing
  return [
    const TaskInputField(id: 'surface', label: 'Quantité', suffix: 'u', defaultValue: 1.0),
  ]; 
}

/// Helper to get default products for a task
List<Product> getDefaultProductsForTask(String taskId) {
  final tid = taskId.toLowerCase();
  
  if (tid.contains('peinture') || tid.contains('murs') || tid.contains('plafond') || tid.contains('impression')) {
    return _allProducts.where((p) => p.category == 'Peinture' || p.category == 'Consommable' || p.category == 'Outillage').take(3).toList();
  }
  if (tid.contains('enduit') || tid.contains('poncage') || tid.contains('preparation')) {
    return _allProducts.where((p) => p.category == 'Enduit' || p.category == 'Consommable').toList();
  }
  
  if (tid.contains('elec') || tid.contains('prise') || tid.contains('interrupteur') || tid.contains('cable') || tid.contains('tableau')) {
    return _allProducts.where((p) => p.brand == 'Legrand' || p.brand == 'Schneider' || p.brand == 'Nexans' || p.brand == 'Hager').toList();
  }
  
  if (tid.contains('plomb') || tid.contains('eau') || tid.contains('wc') || tid.contains('lavabo') || tid.contains('robinet')) {
     return _allProducts.where((p) => p.category == 'Tuyauterie' || p.category == 'Sanitaire' || p.category == 'Robinetterie').toList();
  }
  
  if (tid.contains('carrelage') || tid.contains('faience') || tid.contains('sol')) {
    return _allProducts.where((p) => p.category == 'Colle' || p.category == 'Joint' || p.category == 'Carrelage').toList();
  }
  
  if (tid.contains('menuiserie') || tid.contains('porte') || tid.contains('fenetre') || tid.contains('parquet') || tid.contains('plinthe')) {
    return _allProducts.where((p) => p.category == 'Sol' || p.category == 'Finition' || p.category == 'Ouverture').toList();
  }

  // Fallback: return a few random ones
  return _allProducts.take(2).toList();
}
