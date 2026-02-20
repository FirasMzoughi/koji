import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/home/widgets/stat_card.dart'; // Reuse if applicable, or build custom

class SynchronizationScreen extends StatelessWidget {
  const SynchronizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors extracted from design/home_screen
    final darkBlue = const Color(0xFF0F3995);
    final primaryBlue = const Color(0xFF1D74FF);
    final scaffoldBg = const Color(0xFFF5F8FF); // Light blueish grey from image hint
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context, darkBlue),

              const SizedBox(height: 32),

              // Title Section
              Text(
                "État de synchronisation",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Assurez-vous que toutes les heures sont à jour",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: darkBlue.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 24),

              // Grid Options
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0, // Square cards
                children: [
                   _buildSyncOptionCard(
                    context,
                    title: "Profils Ouvriers",
                    icon: Icons.person,
                    onTap: () => context.push('/workers'), 
                  ),
                   _buildSyncOptionCard(
                    context,
                    title: "Affectation Chantiers",
                    icon: Icons.assignment_ind,
                    onTap: () => context.push('/projects'),
                  ),
                   _buildSyncOptionCard(
                    context,
                    title: "Planning Individuel",
                    icon: Icons.calendar_month,
                    onTap: () => context.push('/planning'),
                  ),
                   _buildSyncOptionCard(
                    context,
                    title: "Pointage et Heures",
                    icon: Icons.access_time,
                    onTap: () => context.push('/synchronization/pointage'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Aujourd'hui Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Aujourd'hui",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        Text(
                          "Janvier 2026",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // Blue Team Hours Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0F3995),
                            primaryBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total heures équipe",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "123.4 h",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.access_time_filled,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Row (Actifs / Retards)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            label: "Actifs",
                            value: "12/20",
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatBox(
                            label: "Retards",
                            value: "02",
                            color: darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color darkBlue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.chevron_left, color: darkBlue, size: 24),
          ),
        ),
        
        // Title
        Text(
          "Synchronisation",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),

        // Notification Bell
        Stack(
          children: [
             Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.notifications_none, color: darkBlue, size: 24),
            ),
            Positioned(
              right: 12, // Adjusted for container padding
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5252), // Red dot
                  shape: BoxShape.circle,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildSyncOptionCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    final darkBlue = const Color(0xFF0F3995);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Subtle shadow
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF), // Very light blue bg for icon
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EEFF)),
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFF0F3995), // Dark blue icon
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slight grey/blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: const Color(0xFF64748B), // Slate grey
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
