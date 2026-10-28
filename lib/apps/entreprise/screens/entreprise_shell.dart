import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/apps/entreprise/screens/entreprise_accueil_screen.dart';
import 'package:koji/apps/entreprise/screens/entreprise_list_screens.dart';
import 'package:koji/apps/entreprise/screens/entreprise_account_screens.dart';

export 'entreprise_accueil_screen.dart';
export 'entreprise_list_screens.dart';
export 'entreprise_account_screens.dart';

/// Shell layout for Entreprise app — responsive sidebar/bottom nav.
class EntrepriseShell extends StatefulWidget {
  final Widget child;
  const EntrepriseShell({super.key, required this.child});

  @override
  State<EntrepriseShell> createState() => _EntrepriseShellState();
}

class _EntrepriseShellState extends State<EntrepriseShell> {
  late double _screenWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.of(context).size.width;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _screenWidth < 768;
    final navItems = [
      ('Accueil', KojiIcons.home, '/entreprise'),
      ('Devis', KojiIcons.file, '/entreprise/devis'),
      ('Clients', KojiIcons.users, '/entreprise/clients'),
      ('Équipe', KojiIcons.people, '/entreprise/equipe'),
      ('Facturation', KojiIcons.receipt, '/entreprise/facturation'),
      ('Profil', KojiIcons.user, '/entreprise/profil'),
      ('Paramètres', KojiIcons.settings, '/entreprise/parametres'),
    ];

    if (isMobile) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          items: navItems.sublist(0, 5).map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.$2),
              label: item.$1,
            );
          }).toList(),
          onTap: (idx) => context.go(navItems[idx].$3),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationDrawer(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Koji Pro',
                  style: context.koji.typography.headlineSmall,
                ),
              ),
              const Divider(),
              for (final (label, icon, route) in navItems)
                NavigationDrawerDestination(
                  icon: Icon(icon),
                  label: Text(label),
                  onTap: () => context.go(route),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(KojiIcons.logout),
                title: const Text('Déconnexion'),
                onTap: () {
                  // TODO: logout
                },
              ),
            ],
          ),
          // Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
