import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          // Header with logo
          Container(
            color: const Color(0xFF0F172A),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
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

          const SizedBox(height: 24),

          // Navigation items
          _DrawerItem(
            icon: Icons.build_outlined,
            label: 'Fournitures',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/fournitures');
            },
          ),
          _DrawerItem(
            icon: Icons.archive_outlined,
            label: 'Archives',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          _DrawerItem(
            icon: Icons.group_outlined,
            label: 'Synchronisation',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/synchronization');
            },
          ),
          _DrawerItem(
            icon: Icons.edit_outlined,
            label: 'Signature',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/signature');
            },
          ),
          _DrawerItem(
            icon: Icons.calendar_month_outlined,
            label: 'Calendrier',
            onTap: () {
              Navigator.of(context).pop();
              context.go('/planning');
            },
          ),
          
          

          const Spacer(),

          // Divider
          const Divider(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            indent: 24,
            endIndent: 24,
          ),

          const SizedBox(height: 8),

          // Bottom items
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/settings/pricing');
            },
          ),
          _DrawerItem(
            icon: Icons.person_outline,
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
    final Color textColor = isDisabled
        ? const Color(0xFFCBD5E1)
        : isActive
            ? const Color(0xFF0F172A)
            : const Color(0xFF475569);

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
