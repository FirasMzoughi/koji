import 'package:flutter/material.dart';

import 'package:koji/core/responsive_helper.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:koji/features/quote/chantier_list_screen.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
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
                          const SnackBar(
                              content: Text('Tâches bientôt disponibles')),
                        );
                      },
                    ),
                    _buildPlusActionItem(
                      label: 'Dépense',
                      icon: Icons.payments,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Dépenses bientôt disponibles')),
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
                color: const Color(
                    0xFFF8F9FA), // Light greyish background for nav bar area
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
    final user = ref.watch(authRepositoryProvider).currentUser;
    final chantiersAsync = user == null
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(userChantiersProvider(user.id));
    final openTasksAsync = user == null
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(openChantierTasksProvider(user.id));
    final quotesAsync = user == null
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(userQuotesProvider(user.id));

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
                DashboardSection(
                  title: 'A faire maintenant',
                  onTap: () => context.push('/planning'),
                  child: openTasksAsync.when(
                    data: (tasks) {
                      if (user == null) {
                        return const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos tâches',
                        );
                      }

                      final now = DateTime.now();
                      final startOfToday = DateTime(now.year, now.month, now.day);
                      final endOfToday = startOfToday.add(const Duration(days: 1));

                      final todayTasks = tasks.where((t) {
                        final raw = t['created_at'];
                        DateTime? createdAt;
                        if (raw is String) createdAt = DateTime.tryParse(raw);
                        if (raw is DateTime) createdAt = raw;
                        return createdAt != null &&
                            createdAt.isAfter(startOfToday.subtract(const Duration(milliseconds: 1))) &&
                            createdAt.isBefore(endOfToday);
                      }).toList();

                      if (todayTasks.isEmpty) {
                        return const DashboardEmptyState(
                          title: 'Aucune tâche pour aujourd\'hui',
                          subtitle: 'Vous êtes à jour !',
                        );
                      }

                      int todayCount = todayTasks.length;
                      final visible = todayTasks.take(5).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Aujourd’hui : $todayCount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...visible.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F3995),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      (t['label'] as String?)?.trim().isNotEmpty == true
                                          ? (t['label'] as String)
                                          : 'Tâche',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (tasks.length > visible.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ ${tasks.length - visible.length} autres',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => DashboardEmptyState(
                      title: 'Erreur de chargement',
                      subtitle: err.toString(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                DashboardSection(
                  title: 'Chantiers',
                  child: chantiersAsync.when(
                    data: (chantiers) {
                      if (user == null) {
                        return const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos chantiers',
                        );
                      }

                      final activeChantiers = chantiers.where((c) {
                        final status = ((c['status'] as String?) ?? '').toLowerCase();
                        return status != 'termine' && 
                               status != 'terminé' && 
                               status != 'valide' && 
                               status != 'validé' && 
                               status != 'completed' &&
                               status != 'done' &&
                               status != 'archived';
                      }).toList();

                      if (activeChantiers.isEmpty) {
                        return const DashboardEmptyState(
                          title: 'Aucun chantier en cours',
                          subtitle: 'Créez votre premier chantier',
                        );
                      }

                      final visible = activeChantiers.take(3).toList();

                      return Column(
                        children: [
                          ...visible.map((c) {
                            final title = (c['title'] as String?)?.trim().isNotEmpty == true
                                ? (c['title'] as String)
                                : (c['reference'] as String?) ?? 'Chantier';
                            final status = (c['status'] as String?) ?? 'En attente';
                            final reference = (c['reference'] as String?) ?? '';
                            final chantierId = c['id'] as String?;

                            return Dismissible(
                              key: Key('chantier_$chantierId'),
                              direction: chantierId != null ? DismissDirection.horizontal : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.archive_outlined, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                if (chantierId != null) {
                                  ref.read(chantierRepositoryProvider).updateChantierStatus(chantierId, 'archived');
                                }
                              },
                              child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: chantierId == null
                                    ? null
                                    : () => context.push('/chantier/dashboard', extra: {'id': chantierId, 'reference': reference}),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.handyman_outlined, size: 18, color: Color(0xFF0F172A)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (reference.isNotEmpty)
                                              Text(
                                                reference,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        status,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                          if (activeChantiers.length > visible.length)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '+ ${chantiers.length - visible.length} autres',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => DashboardEmptyState(
                      title: 'Erreur de chargement',
                      subtitle: err.toString(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Devis en cours
                DashboardSection(
                  title: 'Devis en cours',
                  child: quotesAsync.when(
                    data: (quotes) {
                      if (user == null) {
                        return const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos devis',
                        );
                      }

                      final inProgress = quotes.where((q) {
                        final s = (q['status'] ?? '').toString().toLowerCase();
                        return s == 'en_cours' ||
                            s == 'generated' ||
                            s == 'draft' ||
                            s == 'pending' ||
                            s.contains('attente');
                      }).toList();

                      if (inProgress.isEmpty) {
                        return const DashboardEmptyState(
                          title: 'Aucun devis en cours',
                          subtitle: 'Les devis non finalisés apparaîtront ici',
                        );
                      }

                      final visible = inProgress.take(3).toList();

                      return Column(
                        children: [
                          ...visible.map((q) {
                            final client = q['client'] as Map<String, dynamic>? ?? {};
                            final clientName = (client['name'] as String?)?.trim().isNotEmpty == true
                                ? (client['name'] as String)
                                : 'Client';
                            final totals = q['totals'] as Map<String, dynamic>? ?? {};
                            final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;
                            final refQ = (q['quoteNumber'] ?? q['reference'] ?? '').toString();
                            final quoteId = q['id'] as String?;

                            return Dismissible(
                              key: Key('quote_$quoteId'),
                              direction: quoteId != null ? DismissDirection.horizontal : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.archive_outlined, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                if (quoteId != null) {
                                  ref.read(quoteRepositoryProvider).updateQuoteStatus(quoteId, 'archived');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.description_outlined, size: 18, color: Color(0xFF0F172A)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (refQ.isNotEmpty)
                                            Text(
                                              refQ,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _formatEuro(amount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                          if (inProgress.length > visible.length)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '+ ${inProgress.length - visible.length} autres',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => DashboardEmptyState(
                      title: 'Erreur de chargement',
                      subtitle: err.toString(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Chiffre d'affaires
                DashboardSection(
                  title: 'Chiffre d\'affaires',
                  child: quotesAsync.when(
                    data: (quotes) {
                      if (user == null) {
                        return const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos montants',
                        );
                      }

                      double factured = 0;
                      double awaitingSignature = 0;

                      for (final q in quotes) {
                        final totals = q['totals'] as Map<String, dynamic>? ?? {};
                        final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;
                        final status = (q['status'] ?? '').toString().toLowerCase();

                        final isSigned = status == 'accepted' ||
                            status == 'validated' ||
                            status == 'signed' ||
                            status.contains('sign') ||
                            status.contains('accept');

                        final isAwaiting = status == 'generated' ||
                            status == 'en_cours' ||
                            status == 'draft' ||
                            status.contains('attente');

                        if (isSigned) {
                          factured += amount;
                        } else if (isAwaiting) {
                          awaitingSignature += amount;
                        } else {
                          awaitingSignature += amount;
                        }
                      }

                      return Column(
                        children: [
                          DashboardStatRow(
                            label: 'Facturé',
                            value: _formatEuro(factured),
                            isBold: true,
                          ),
                          const SizedBox(height: 16),
                          DashboardStatRow(
                            label: 'En attente (de signature)',
                            value: _formatEuro(awaitingSignature),
                            isBold: true,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => DashboardEmptyState(
                      title: 'Erreur de chargement',
                      subtitle: err.toString(),
                    ),
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

  String _formatEuro(num value) {
    final rounded = value.round();
    final s = rounded.toString();
    final reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    final formatted = s.replaceAllMapped(reg, (m) => '${m[1]} ');
    return '$formatted €';
  }
}
