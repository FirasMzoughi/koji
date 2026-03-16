import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const darkNavy = Color(0xFF0A1227);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          // Watermark KJ logo in background
          Positioned(
            right: -30,
            top: MediaQuery.of(context).size.height * 0.30,
            child: Opacity(
              opacity: 0.04,
              child: SvgPicture.asset(
                'assets/icons/LOGO.svg',
                height: 280,
                colorFilter: const ColorFilter.mode(
                  darkNavy,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // ─── HEADER ───────────────────
              Container(
                color: darkNavy,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/LOGO.svg',
                    height: 56,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFEAD8B1),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─── NAVIGATION ITEMS ─────────
              _DrawerItem(
                icon: Icons.calendar_month_outlined,
                label: 'Calendrier',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/planning');
                },
              ),
              _DrawerItem(
                icon: Icons.build_outlined,
                label: 'Fournitures',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/fournitures');
                },
              ),
              _DrawerItem(
                icon: Icons.group_outlined,
                label: 'Équipe',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/synchronization');
                },
              ),
              _DrawerItem(
                icon: Icons.draw_outlined,
                label: 'Signature',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/signature'); // Or wherever the global user signature will be
                },
              ),
              _DrawerItem(
                icon: Icons.archive_outlined,
                label: 'Archives',
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              
            

              const Spacer(),

              // ─── DIVIDER ──────────────────
              const Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1,
                indent: 24,
                endIndent: 24,
              ),

              const SizedBox(height: 4),

              // ─── BOTTOM ITEMS ─────────────
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Paramètres',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/pricing');
                },
              ),
              _DrawerItem(
                icon: Icons.person,
                label: 'Compte',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile/company');
                },
              ),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Déconnexion',
                isDisabled: true,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    const darkNavy = Color(0xFF0A1227);

    final Color iconColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : isActive
            ? darkNavy
            : const Color(0xFF475569);

    final Color textColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : isActive
            ? darkNavy
            : darkNavy;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
