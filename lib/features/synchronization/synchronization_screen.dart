import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SynchronizationScreen extends StatelessWidget {
  const SynchronizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors based on design
    final darkText = const Color(0xFF031229);
    final greyText = const Color(0xFF8B95A5);
    final appBg = const Color(0xFFFBFBFC);
    
    return Scaffold(
      backgroundColor: appBg,
      body: Stack(
        children: [
          // Background Gradient (Peach glow at top right)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFBE4D2).withOpacity(0.8),
                    const Color(0xFFFBE4D2).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, darkText),
                  const SizedBox(height: 32),
                  // Title Section
                  Text(
                    "État de synchronisation",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Assurez-vous que toutes les heures sont à jour",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: greyText,
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
                    childAspectRatio: 0.92,
                    children: [
                      _buildSyncOptionCard(
                        context,
                        title: "Profils\nOuvriers",
                        icon: Icons.person,
                        onTap: () => context.push('/workers'),
                        iconSize: 34,
                      ),
                      _buildSyncOptionCard(
                        context,
                        title: "Affectation\nChantiers",
                        icon: Icons.groups,
                        onTap: () => context.push('/projects'),
                        iconSize: 34,
                      ),
                      _buildSyncOptionCard(
                        context,
                        title: "Planning\nIndividuel",
                        icon: Icons.calendar_month_outlined,
                        onTap: () => context.push('/planning'),
                        iconSize: 30,
                      ),
                      _buildSyncOptionCard(
                        context,
                        title: "Pointage et\nHeurs",
                        icon: Icons.access_time,
                        onTap: () => context.push('/synchronization/pointage'),
                        iconSize: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Aujourd'hui Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: darkText.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            Text(
                              "Janvier 2026",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                color: greyText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Blue Team Hours Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1227), // Deep navy
                            borderRadius: BorderRadius.circular(16),
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
                                      color: Color(0xFFB3B9C5),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "123.4 h",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
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
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                label: "Actifs",
                                value: "12/20",
                                darkText: darkText,
                                greyText: greyText,
                                valueSize: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatBox(
                                label: "Retards",
                                value: "02",
                                darkText: darkText,
                                greyText: greyText,
                                valueSize: 24,
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color darkText) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: darkText.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.chevron_left, color: darkText, size: 28),
          ),
        ),
        Expanded(
          child: Text(
            "Synchronisation",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: darkText.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none, color: darkText, size: 26),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4848),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required double iconSize,
  }) {
    final darkText = const Color(0xFF031229);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: darkText.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: darkText,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color darkText,
    required Color greyText,
    required double valueSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }
}
