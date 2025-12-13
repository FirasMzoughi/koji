import 'package:uuid/uuid.dart';

class Estimate {
  final String id;
  final String clientId;
  final ClientInfo client;
  final DateTime date;
  String status; // 'En cours', 'Validé'
  String description;
  double surfaceArea; // m2
  double pricePerSqMeter;
  List<SupplyItem> supplies;

  Estimate({
    String? id,
    required this.clientId,
    required this.client,
    required this.date,
    this.status = 'En cours',
    this.description = '',
    this.surfaceArea = 0.0,
    this.pricePerSqMeter = 0.0,
    this.supplies = const [],
  }) : id = id ?? const Uuid().v4();

  double get laborCost => surfaceArea * pricePerSqMeter;
  
  double get suppliesCost => supplies.fold(0, (sum, item) => sum + item.totalPrice);
  
  double get totalCost => laborCost + suppliesCost;
}

class ClientInfo {
  String name;
  String address;
  String phone;

  ClientInfo({
    required this.name,
    required this.address,
    required this.phone,
  });
}

class SupplyItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  SupplyItem({
    String? id,
    required this.name,
    required this.price,
    this.quantity = 1,
  }) : id = id ?? const Uuid().v4();

  double get totalPrice => price * quantity;
}
