import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/provider/account_type_provider.dart';

class AccountTypeSelectionScreen extends ConsumerStatefulWidget {
  const AccountTypeSelectionScreen({super.key});

  @override
  ConsumerState<AccountTypeSelectionScreen> createState() =>
      _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState
    extends ConsumerState<AccountTypeSelectionScreen> {
  String? _selectedType; // 'entreprise' or 'particulier'

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final hasSelection = _selectedType != null;

    return Scaffold(
      body: Stack(
        children: [
          // Background - changes when entreprise is selected
          if (_selectedType == 'entreprise')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                        const AssetImage('assets/images/construction_bg.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      AppTheme.darkNavy.withValues(alpha: 0.7),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF8F9FA),
              ),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: responsive.paddingSymmetric(
                    horizontalPercent: 6.4,
                    verticalPercent: 2.5,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: responsive.height(2)),
                      Text(
                        'Bienvenue sur Kôji !',
                        style: TextStyle(
                          fontSize: responsive.fontSize(28),
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'entreprise'
                              ? Colors.white
                              : AppTheme.darkNavy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: responsive.height(1.5)),
                      Text(
                        'Choisissez votre type de compte pour\ncommencer l\'expérience',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          color: _selectedType == 'entreprise'
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF9CA3AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Account Type Cards
                Padding(
                  padding: responsive.paddingSymmetric(horizontalPercent: 6.4),
                  child: Column(
                    children: [
                      // Profil Entreprise Card
                      _buildAccountTypeCard(
                        type: 'entreprise',
                        title: 'Profil Entreprise',
                        subtitle:
                            'Pour les artisans et entreprises du\nbâtiment',
                        tagline: 'Gérez devis, factures & clients',
                        icon: Icons.business,
                        isSelected: _selectedType == 'entreprise',
                        responsive: responsive,
                      ),

                      SizedBox(height: responsive.height(2)),

                      // Profil Particulier Card
                      _buildAccountTypeCard(
                        type: 'particulier',
                        title: 'Profil Particulier',
                        subtitle:
                            'Pour les clients cherchant des artisans\nqualifiés.',
                        tagline: 'Suivez vos travaux & devis',
                        icon: Icons.person,
                        isSelected: _selectedType == 'particulier',
                        responsive: responsive,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Continue Button
                Padding(
                  padding: responsive.paddingSymmetric(
                    horizontalPercent: 6.4,
                    verticalPercent: 3,
                  ),
                  child: ElevatedButton(
                    onPressed: hasSelection ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSelection
                          ? AppTheme.primaryBlue
                          : const Color(0xFFD1D5DB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.height(2.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(responsive.borderRadius(12)),
                      ),
                      minimumSize: Size(double.infinity, responsive.height(7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Suivant',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: responsive.width(2)),
                        Icon(
                          Icons.arrow_forward,
                          size: responsive.iconSize(20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required String tagline,
    required IconData icon,
    required bool isSelected,
    required ResponsiveHelper responsive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
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
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.darkNavy,
                    ),
                  ),
                  SizedBox(height: responsive.height(0.5)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: responsive.height(1)),
                  Text(
                    tagline,
                    style: TextStyle(
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

  void _handleContinue() {
    if (_selectedType == null) return;

    // Set the account type in the provider
    final isPro = _selectedType == 'entreprise';
    ref.read(accountTypeProvider.notifier).state = isPro;

    // Navigate to login screen with the chosen type
    context.go('/login?type=$_selectedType');
  }
}
