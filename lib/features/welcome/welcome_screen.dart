import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // Track selected profile: 1 for Entreprise (Pro), 2 for Particulier (Regular)
  int? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      body: Stack(
        children: [
          // Background - changes when entreprise is selected
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _selectedProfile == 1
                ? Container(
                    key: const ValueKey('entreprise'),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage(
                            'assets/images/construction_bg.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          AppTheme.darkNavy.withAlpha((0.7 * 255).round()),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('default'),
                    color: const Color(0xFFF8F9FA),
                  ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: responsive.paddingSymmetric(
                horizontalPercent: 6.4,
                verticalPercent: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: responsive.height(3)),

                  // Title
                  Text(
                    'Bienvenue sur Kôji !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: responsive.fontSize(28),
                      fontWeight: FontWeight.w700,
                      color: _selectedProfile == 1
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: responsive.height(1.5)),

                  // Subtitle
                  Text(
                    'Choisissez votre type de compte pour\ncommencer l\'expérience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: responsive.fontSize(15),
                      fontWeight: FontWeight.w400,
                      color: _selectedProfile == 1
                          ? Colors.white.withAlpha((0.9 * 255).round())
                          : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),

                  // Profile Cards
                  _buildProfileCard(
                    id: 1,
                    title: 'Profil Entreprise',
                    subtitle: 'Pour les artisans et entreprises du\nbâtiment',
                    tag: 'Gérez devis, factures & clients',
                    icon: Icons.business_rounded,
                  ),

                  SizedBox(height: responsive.height(2)),

                  _buildProfileCard(
                    id: 2,
                    title: 'Profil Particulier',
                    subtitle:
                        'Pour les clients cherchant des artisans\nqualifiés.',
                    tag: 'Suivez vos travaux & devis',
                    icon: Icons.person_rounded,
                  ),

                  const Spacer(),

                  // Next Button
                  ElevatedButton(
                    onPressed: _selectedProfile != null
                        ? () {
                            final isPro = _selectedProfile == 1;
                            ref.read(accountTypeProvider.notifier).state =
                                isPro;
                            context.go('/login');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedProfile != null
                          ? AppTheme.primaryBlue
                          : const Color(0xFFD1D5DB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: responsive.height(2.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius(12)),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Suivant',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedProfile != null) ...[
                          SizedBox(width: responsive.width(2.1)),
                          Icon(Icons.arrow_forward,
                              size: responsive.iconSize(20)),
                        ]
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.height(3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required int id,
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
  }) {
    final responsive = context.responsive;
    final isSelected = _selectedProfile == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfile = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(responsive.width(5)),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withAlpha((0.3 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: EdgeInsets.all(responsive.width(3.5)),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppTheme.darkNavy,
                borderRadius:
                    BorderRadius.circular(responsive.borderRadius(12)),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                size: responsive.iconSize(28),
              ),
            ),

            SizedBox(width: responsive.width(4)),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.darkNavy,
                    ),
                  ),
                  SizedBox(height: responsive.height(0.5)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: responsive.fontSize(13),
                      color: isSelected
                          ? Colors.white.withAlpha((0.9 * 255).round())
                          : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: responsive.height(1)),
                  Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              size: responsive.iconSize(18),
            ),
          ],
        ),
      ),
    );
  }
}
