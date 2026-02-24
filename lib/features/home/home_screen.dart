import 'package:flutter/material.dart';

import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:koji/features/quote/chantier_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


// Import widgets
import 'package:koji/features/home/widgets/bottom_nav_item.dart';
import 'package:koji/features/home/widgets/home_header.dart';
import 'package:koji/features/home/widgets/dashboard_section.dart';
import 'package:koji/features/home/widgets/create_project_button.dart';
import 'package:koji/features/home/widgets/app_drawer.dart';

/// Main home screen - STATEFUL for tab management
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    if (index == 3) {
      _showToolsSheet();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreateProject() {
    context.push('/chantier/create');
  }

  void _showToolsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlusActionItem(
                      label: 'Photo',
                      icon: Icons.photo_camera,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/quote/visual-proofs');
                      },
                    ),
                    _buildPlusActionItem(
                      label: 'Tâche',
                      icon: Icons.fact_check,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tâches bientôt disponibles')),
                        );
                      },
                    ),
                    _buildPlusActionItem(
                      label: 'Dépense',
                      icon: Icons.payments,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dépenses bientôt disponibles')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlusActionItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF0F3995)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3995),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Content Layer
          IndexedStack(
            index: _selectedIndex,
            children: [
              // Home Tab (Index 0)
              _buildHomeContent(responsive),
              
              // Devis Tab (Index 1)
              const QuoteListScreen(),
              
              // Chantier Tab (Index 2)
              const ChantierListScreen(),
              
              // Plus/Menu Tab (Index 3) - Placeholder
              const Center(child: Text("Menu (Updates coming)")),
            ],
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // Light greyish background for nav bar area
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: BottomNavItem(
                      icon: Icons.home_filled,
                      label: 'Accueil',
                      isActive: _selectedIndex == 0,
                      activeColor: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: BottomNavItem(
                      icon: Icons.description_outlined,
                      label: 'Devis',
                      isActive: _selectedIndex == 1,
                      activeColor: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: BottomNavItem(
                      icon: Icons.handyman_outlined,
                      label: 'Chantier',
                      isActive: _selectedIndex == 2,
                      activeColor: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(3),
                    child: BottomNavItem(
                      icon: Icons.more_horiz, // Three dots
                      label: 'Plus',
                      isActive: _selectedIndex == 3,
                       activeColor: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(ResponsiveHelper responsive) {
    return Column(
      children: [
        // Header
        HomeHeader(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Create Project Button
                CreateProjectButton(onTap: _onCreateProject),

                const SizedBox(height: 32),

                // A faire maintenant
                const DashboardSection(
                  title: 'A faire maintenant',
                  child: DashboardEmptyState(
                    title: 'Aucune action pour le moment',
                    subtitle: 'Commencez par créer un chantier',
                  ),
                ),

                const SizedBox(height: 24),

                // Devis en cours
                const DashboardSection(
                  title: 'Devis en cours',
                  child: DashboardEmptyState(
                    title: 'Aucun devis en cours',
                    subtitle: 'Les devis non envoyés apparaîtront ici',
                  ),
                ),

                 const SizedBox(height: 24),

                // Chiffre d'affaires
                const DashboardSection(
                  title: 'Chiffre d\'affaires',
                  child: Column(
                    children: [
                      DashboardStatRow(
                        label: 'Facturé',
                        value: '0 €',
                        isBold: true,
                      ),
                      SizedBox(height: 16),
                      DashboardStatRow(
                        label: 'En attente (de signature)',
                        value: '0 €',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Bottom padding for Nav Bar
              ],
            ),
          ),
        ),
      ],
    );
  }
}
