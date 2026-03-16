import 'package:flutter/material.dart';

class ExpenseItem {
  String id;
  String title;
  String subtitle;
  IconData icon;
  double quantity;
  double laborCost;
  double materialCost;
  double tax;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.quantity = 0.0,
    this.laborCost = 0.0,
    this.materialCost = 0.0,
    this.tax = 0.0,
  });

  double get total => (laborCost + materialCost) * quantity * (1 + tax / 100);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'quantity': quantity,
      'laborCost': laborCost,
      'materialCost': materialCost,
      'tax': tax,
      // IconData is not serializable directly for JSON/Firestore usually,
      // but assuming we rebuild it or store code point.
      // For now we might skip icon in DB or store generic name.
    };
  }
}
