import 'package:flutter/material.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/onboarding/widgets/dot_indicator.dart';

/// Navigation controls for onboarding (dots, skip, next button)
/// STATELESS & CONST for performance
class OnboardingNavigationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const OnboardingNavigationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.width(6.4),
        vertical: responsive.height(2.5),
      ),
      child: Column(
        children: [
          // Row with Dots and Next Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dot indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(
                  totalPages,
                  (index) => DotIndicator(isActive: index == currentPage),
                ),
              ),

              // Next/Arrow button
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: EdgeInsets.all(responsive.width(4.3)),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded, // Slightly different arrow
                    color: Colors.white,
                    size: responsive.iconSize(24),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: responsive.height(3)),
          
          // Skip button / "Passer cette étape" centered at bottom
          if (!isLastPage)
            TextButton(
              onPressed: onSkip,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Passer cette étape',
                    style: TextStyle(
                      fontFamily: 'Outfit', 
                      fontSize: responsive.fontSize(16),
                      color: const Color(0xFF7CA7F4), // Light blueish per screenshot, or use primaryBlueLight
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: responsive.width(1)),
                  Icon(
                    Icons.arrow_forward, 
                    size: responsive.iconSize(16),
                    color: const Color(0xFF7CA7F4),
                  ),
                ],
              ),
            )
          else
             // Maintain space or show a "Commencer" button if needed, but for now just SizedBox to keep layout stable
             SizedBox(height: responsive.height(6)), 
        ],
      ),
    );
  }
}
