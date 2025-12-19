class Room {
  final String id;
  final String name;
  final WallCondition wallCondition;
  final String? floor;
  final bool hasDressing;
  final bool hasKitchenFurniture;

  Room({
    required this.id,
    required this.name,
    required this.wallCondition,
    this.floor,
    this.hasDressing = false,
    this.hasKitchenFurniture = false,
  });

  Room copyWith({
    String? id,
    String? name,
    WallCondition? wallCondition,
    String? floor,
    bool? hasDressing,
    bool? hasKitchenFurniture,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      wallCondition: wallCondition ?? this.wallCondition,
      floor: floor ?? this.floor,
      hasDressing: hasDressing ?? this.hasDressing,
      hasKitchenFurniture: hasKitchenFurniture ?? this.hasKitchenFurniture,
    );
  }
}

enum WallCondition {
  grave,
  moyen,
  simple;

  String get displayName {
    switch (this) {
      case WallCondition.grave:
        return 'Grave';
      case WallCondition.moyen:
        return 'Moyen';
      case WallCondition.simple:
        return 'Simple';
    }
  }

  String get description {
    switch (this) {
      case WallCondition.grave:
        return 'Rénovation complète nécessaire';
      case WallCondition.moyen:
        return 'Quelques réparations requises';
      case WallCondition.simple:
        return 'Bon état général';
    }
  }
}
