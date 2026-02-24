
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
  final String roomId; // Added roomId to avoid parsing issues with underscores
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
    required this.roomId,
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
    
  RoomTaskState copyWith({
    bool? isExpanded,
    Map<String, dynamic>? inputs,
    String? note,
    List<String>? photoPaths,
    Map<String, double>? selectedProducts,
  }) {
    return RoomTaskState(
      taskId: this.taskId,
      roomId: this.roomId,
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

// Helper to get fields for a task category/type
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
List<Product> getDefaultProductsForTask(String taskId, List<Product> allProducts) {
  final tid = taskId.toLowerCase();
  
  if (tid.contains('peinture') || tid.contains('murs') || tid.contains('plafond') || tid.contains('impression')) {
    return allProducts.where((p) => p.category == 'Peinture' || p.category == 'Consommable' || p.category == 'Outillage').take(3).toList();
  }
  if (tid.contains('enduit') || tid.contains('poncage') || tid.contains('preparation')) {
    return allProducts.where((p) => p.category == 'Enduit' || p.category == 'Consommable').toList();
  }
  
  if (tid.contains('elec') || tid.contains('prise') || tid.contains('interrupteur') || tid.contains('cable') || tid.contains('tableau')) {
    return allProducts.where((p) => p.brand == 'Legrand' || p.brand == 'Schneider' || p.brand == 'Nexans' || p.brand == 'Hager').toList();
  }
  
  if (tid.contains('plomb') || tid.contains('eau') || tid.contains('wc') || tid.contains('lavabo') || tid.contains('robinet')) {
     return allProducts.where((p) => p.category == 'Tuyauterie' || p.category == 'Sanitaire' || p.category == 'Robinetterie').toList();
  }
  
  if (tid.contains('carrelage') || tid.contains('faience') || tid.contains('sol')) {
    return allProducts.where((p) => p.category == 'Colle' || p.category == 'Joint' || p.category == 'Carrelage').toList();
  }
  
  if (tid.contains('menuiserie') || tid.contains('porte') || tid.contains('fenetre') || tid.contains('parquet') || tid.contains('plinthe')) {
    return allProducts.where((p) => p.category == 'Sol' || p.category == 'Finition' || p.category == 'Ouverture').toList();
  }

  // Fallback: return a few random ones
  return allProducts.take(2).toList();
}

// --- Chantier (Project) Models ---

/// Represents a project/chantier address
class ChantierAddress {
  final String street;
  final String? complement;
  final String postalCode;
  final String city;
  final String? country;

  const ChantierAddress({
    required this.street,
    this.complement,
    required this.postalCode,
    required this.city,
    this.country = 'France',
  });

  factory ChantierAddress.fromJson(Map<String, dynamic> json) {
    return ChantierAddress(
      street: json['street'] as String,
      complement: json['complement'] as String?,
      postalCode: json['postal_code'] as String,
      city: json['city'] as String,
      country: json['country'] as String? ?? 'France',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'complement': complement,
      'postal_code': postalCode,
      'city': city,
      'country': country,
    };
  }

  String get fullAddress {
    final complementPart = complement != null && complement!.isNotEmpty ? '${complement!}, ' : '';
    return '$complementPart$street, $postalCode $city';
  }
}

/// Represents a client contact for the chantier
class ChantierContact {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;

  const ChantierContact({
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
  });

  factory ChantierContact.fromJson(Map<String, dynamic> json) {
    return ChantierContact(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company': company,
    };
  }

  String get fullName => '$firstName $lastName';
}

/// Main Chantier (Project) model
class Chantier {
  final String id;
  final String title;
  final String? description;
  final ChantierAddress address;
  final ChantierContact contact;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'draft', 'in_progress', 'completed', 'cancelled'
  final double? estimatedBudget;
  final String? notes;
  final List<String> photoPaths;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Chantier({
    required this.id,
    required this.title,
    this.description,
    required this.address,
    required this.contact,
    this.startDate,
    this.endDate,
    this.status = 'draft',
    this.estimatedBudget,
    this.notes,
    List<String>? photoPaths,
    required this.createdAt,
    this.updatedAt,
  }) : photoPaths = photoPaths ?? const [];

  factory Chantier.fromJson(Map<String, dynamic> json) {
    return Chantier(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      address: ChantierAddress.fromJson(json['address'] as Map<String, dynamic>),
      contact: ChantierContact.fromJson(json['contact'] as Map<String, dynamic>),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String? ?? 'draft',
      estimatedBudget: (json['estimated_budget'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      photoPaths: (json['photo_paths'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address.toJson(),
      'contact': contact.toJson(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'estimated_budget': estimatedBudget,
      'notes': notes,
      'photo_paths': photoPaths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Chantier copyWith({
    String? title,
    String? description,
    ChantierAddress? address,
    ChantierContact? contact,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? estimatedBudget,
    String? notes,
    List<String>? photoPaths,
    DateTime? updatedAt,
  }) {
    return Chantier(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Helper class for creating a new chantier
class ChantierCreationData {
  String title;
  String? description;
  ChantierAddress? address;
  ChantierContact? contact;
  DateTime? startDate;
  DateTime? endDate;
  double? estimatedBudget;
  String? notes;

  ChantierCreationData({
    this.title = '',
    this.description,
    this.address,
    this.contact,
    this.startDate,
    this.endDate,
    this.estimatedBudget,
    this.notes,
  });

  bool get isValid {
    return title.isNotEmpty && 
           address != null && 
           contact != null &&
           contact!.firstName.isNotEmpty &&
           contact!.lastName.isNotEmpty;
  }

  Chantier toChantier() {
    if (!isValid) {
      throw StateError('Cannot create Chantier from invalid data');
    }
    
    return Chantier(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      address: address!,
      contact: contact!,
      startDate: startDate,
      endDate: endDate,
      estimatedBudget: estimatedBudget,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}
