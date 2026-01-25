import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';

/// Custom room input widget
/// STATELESS & CONST for performance
class CustomRoomInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const CustomRoomInput({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.input, size: 20, color: AppTheme.darkNavy),
              const SizedBox(width: 12),
              Text(
                "Ajouter une pièce personnalisée",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.darkNavy,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Ex: Buanderie, Garage...',
                    hintStyle: TextStyle(fontFamily: 'Outfit', 
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.darkNavy),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF6B7280)),
                  onPressed: onAdd,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
