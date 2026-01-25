import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';

/// Bottom navigation item widget
/// STATELESS & CONST for performance
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : AppTheme.darkNavy;
    final inactiveColor = isDark ? Colors.grey[600] : AppTheme.textLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? activeColor : inactiveColor,
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
