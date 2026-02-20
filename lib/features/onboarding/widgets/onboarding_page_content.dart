import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';

/// Onboarding page content widget
/// STATELESS & CONST for performance
class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    // RepaintBoundary to prevent unnecessary repaints during page transitions
    return RepaintBoundary(
      child: Padding(
        padding: responsive.paddingSymmetric(horizontalPercent: 6.4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Expanded(
              flex: 3,
              child: Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback placeholder if image doesn't exist
                    return Container(
                      width: responsive.width(80),
                      height: responsive.width(80),
                      decoration: BoxDecoration(
                        color: AppTheme.cream,
                        borderRadius: BorderRadius.circular(responsive.borderRadius(20)),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: responsive.iconSize(80),
                        color: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Text content
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: responsive.height(2.5)),
                  Text(
                    title,
                    style: AppTheme.headingStyle(context).copyWith(color: const Color(0xFF111827)), // Force darkNavy
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: responsive.height(2)),
                  Text(
                    description,
                    style: AppTheme.bodyStyle(context).copyWith(color: const Color(0xFF6B7280)), // Force textLight
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
