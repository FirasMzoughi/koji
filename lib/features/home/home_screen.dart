import 'package:flutter/material.dart';

import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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
      // Handle "Plus" or "Menu" tab
      // For now we can show a bottom sheet or navigate to a settings page
      // context.push('/settings'); 
      // Or just switch to it if we have a view for it
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreateProject() {
     // TODO: Navigate to create project flow
     // context.push('/create-project');
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
              
              // Chantier Tab (Index 2) - Placeholder
              const Center(child: Text("Chantiers (Coming Soon)")),
              
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
