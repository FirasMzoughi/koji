import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';

/// Dot indicator widget for onboarding pagination
/// STATELESS & CONST for performance
class DotIndicator extends StatelessWidget {
  final bool isActive;
  final double activeWidth;
  final double inactiveWidth;
  final double height;
  final double borderRadius;

  const DotIndicator({
    super.key,
    required this.isActive,
    this.activeWidth = 32.0,
    this.inactiveWidth = 8.0,
    this.height = 8.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? activeWidth : inactiveWidth,
      height: height,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryBlueDark
            : AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
