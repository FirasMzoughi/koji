import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/onboarding/widgets/onboarding_page_content.dart';
import 'package:koji/features/onboarding/widgets/onboarding_navigation_controls.dart';

/// Data model for onboarding page
class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

/// Main onboarding screen - STATEFUL for page management
/// All child widgets are STATELESS for performance
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding pages data
  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Pilotez vos chantiers simplement',
      description:
          'Du premier rendez-vous client jusqu\'à la fin des travaux',
      imagePath: 'assets/images/onboarding_1.png',
    ),
    OnboardingPageData(
      title: 'Suivez le chantier au quotidien',
      description:
          'Photos, notes et avancement centralisés au même endroit',
      imagePath: 'assets/images/onboarding_2.png',
    ),
    OnboardingPageData(
      title: 'Des devis clairs, des clients satisfaits',
      description:
          'Vos informations terrain deviennent des devis professionnels',
      imagePath: 'assets/images/onboarding_3.png',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250), // Faster transition
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/welcome');
    }
  }

  void _skipToWelcome() {
    context.go('/welcome');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPageContent(
                    title: page.title,
                    description: page.description,
                    imagePath: page.imagePath,
                  );
                },
              ),
            ),

            // Bottom navigation area (extracted widget)
            OnboardingNavigationControls(
              currentPage: _currentPage,
              totalPages: _pages.length,
              onSkip: _skipToWelcome,
              onNext: _nextPage,
            ),
          ],
        ),
      ),
    );
  }
}
