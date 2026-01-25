import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';

// Import extracted widgets
import 'package:koji/features/home/widgets/stat_card.dart';
import 'package:koji/features/home/widgets/bottom_nav_item.dart';
import 'package:koji/features/home/widgets/home_header.dart';
import 'package:koji/features/home/widgets/home_menu_grid.dart';

/// Main home screen - STATEFUL for tab management
/// All child widgets are STATELESS for performance
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreateQuote() {
    ref.read(quoteCreationProvider.notifier).reset();
    context.push('/quote/client-details');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Content Layer
          IndexedStack(
            index: _selectedIndex,
            children: [
              // Home Tab (Index 0)
              _buildHomeContent(responsive),
              
              // Quotes List Tab (Index 1)
              const QuoteListScreen(),
              
              // Placeholders for other tabs
              const Center(child: Text("Discussion (Coming Soon)")),
              const Center(child: Text("Chantiers (Coming Soon)")),
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
                color: Theme.of(context).bottomAppBarTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
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
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: BottomNavItem(
                      icon: Icons.description_outlined,
                      label: 'Devis',
                      isActive: _selectedIndex == 1,
                    ),
                  ),
                  const SizedBox(width: 56), // Space for FAB
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: BottomNavItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'Discussion',
                      isActive: _selectedIndex == 2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(3),
                    child: BottomNavItem(
                      icon: Icons.handyman_outlined, // Chantier icon
                      label: 'Chantier',
                      isActive: _selectedIndex == 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Action Button (Camera)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D74FF), // Bright Blue
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D74FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  onPressed: () {
                    // Camera action
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(ResponsiveHelper responsive) {
    // Get primary color based on active theme
    
    return Stack(
      children: [
        // Background Header
        Container(
          height: 300,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F3995), // Deep Blue Top
                Color(0xFF1652C9), // Slightly lighter Blue Bottom
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (extracted widget)
              const HomeHeader(),

              const SizedBox(height: 24), 

              // Main Content (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  padding: responsive.paddingSymmetric(horizontalPercent: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // New Devis Button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D74FF).withOpacity(0.1), 
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onCreateQuote,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F3995), // Dark Blue Icon Bg
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Nouveau Devis',
                                    style: TextStyle(fontFamily: 'Outfit', 
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F3995), // Dark Blue Text
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Grid Menu
                      const HomeMenuGrid(),

                      const SizedBox(height: 32),
                      
                      // Stats
                      const Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.person,
                              number: '3',
                              label: 'Nombre des Cha...',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              icon: Icons.note_add_outlined, // Document icon
                              number: '2',
                              label: 'RDV Aujourd\'hui',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 120), // Bottom padding for Nav Bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
