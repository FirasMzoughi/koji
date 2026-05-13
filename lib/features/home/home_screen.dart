import 'package:flutter/material.dart';

import 'package:koji/core/responsive_helper.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:koji/features/quote/chantier_list_screen.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
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
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
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
                    color: AppTheme.borderColor(context),
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
                          color: AppTheme.mutedSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.textPrimary(context),
                        ),
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
                        context.push('/quote/room-selection', extra: <String>[]);
                      },
                    ),
                    _buildPlusActionItem(
                      label: 'Tâche',
                      icon: Icons.fact_check,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/chantier/add-task', extra: <String, dynamic>{});
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
              color: AppTheme.mutedSurface(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                color: Theme.of(context).colorScheme.surface, // Fixed for dark mode
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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
                      activeColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: BottomNavItem(
                      icon: Icons.description_outlined,
                      label: 'Devis',
                      isActive: _selectedIndex == 1,
                      activeColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: BottomNavItem(
                      icon: Icons.handyman_outlined,
                      label: 'Chantier',
                      isActive: _selectedIndex == 2,
                      activeColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(3),
                    child: BottomNavItem(
                      icon: Icons.more_horiz, // Three dots
                      label: 'Plus',
                      isActive: _selectedIndex == 3,
                      activeColor: Theme.of(context).colorScheme.onSurface,
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context),
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
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      (t['label'] as String?)?.trim().isNotEmpty == true
                                          ? (t['label'] as String)
                                          : 'Tâche',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary(context),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
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
                  onTap: () => setState(() => _selectedIndex = 2),
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
                              direction: chantierId != null ? DismissDirection.endToStart : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.archive_outlined,
                                  color: AppTheme.surface(context),
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (chantierId == null) return false;
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Archiver ce chantier ?'),
                                        content: const Text('Il sera masqué de la liste active.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Archiver'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (direction) async {
                                if (chantierId != null) {
                                  try {
                                    await ref.read(chantierRepositoryProvider).updateChantierStatus(chantierId, 'archived');
                                    ref.invalidate(userChantiersProvider(user.id));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Chantier archivé')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
                                  }
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
                                    color: AppTheme.mutedSurface(context),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.handyman_outlined,
                                        size: 18,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary(context),
                                              ),
                                            ),
                                            if (reference.isNotEmpty)
                                              Text(
                                                reference,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary(context),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary(context),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
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
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: quotesAsync.when(
                    data: (quotes) {
                      if (user == null) {
                        return const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos devis',
                        );
                      }

                      // Deduplicate by quoteNumber — keep only the first occurrence
                      // (stream is ordered by created_at desc, so first = most recent)
                      final seenRefs = <String>{};
                      final uniqueQuotes = quotes.where((q) {
                        final ref = (q['quoteNumber'] ?? q['reference'] ?? q['id'] ?? '').toString();
                        if (ref.isEmpty) return true;
                        return seenRefs.add(ref);
                      }).toList();

                      final inProgress = uniqueQuotes.where((q) {
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
                              direction: quoteId != null ? DismissDirection.endToStart : DismissDirection.none,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.archive_outlined,
                                  color: AppTheme.surface(context),
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (quoteId == null) return false;
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Archiver ce devis ?'),
                                        content: const Text('Il sera masqué de la liste en cours.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Archiver'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (direction) async {
                                if (quoteId != null) {
                                  try {
                                    await ref.read(quoteRepositoryProvider).updateQuoteStatus(quoteId, 'archived');
                                    ref.invalidate(userQuotesProvider(user.id));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Devis archivé')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: quoteId == null
                                      ? null
                                      : () async {
                                          // Seed the create-quote flow from
                                          // this saved devis, then drop the
                                          // user into the room/task editor so
                                          // tasks, fournitures and inputs are
                                          // all editable — not just recap
                                          // numbers.
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final router = GoRouter.of(context);
                                          try {
                                            ref
                                                .read(quoteCreationProvider
                                                    .notifier)
                                                .reset();
                                            await ref
                                                .read(quoteCreationProvider
                                                    .notifier)
                                                .seedFromSavedQuote(q);
                                            final state = ref.read(
                                                quoteCreationProvider);
                                            if (state.selectedRoomIds
                                                .isEmpty) {
                                              // No rooms persisted — fall
                                              // back to the recap so the user
                                              // can at least adjust numbers.
                                              router.push('/quote/detail',
                                                  extra: q);
                                              return;
                                            }
                                            router.push(
                                              '/quote/room-details',
                                              extra: {
                                                'roomIds':
                                                    state.selectedRoomIds,
                                                'images': const <String>[],
                                              },
                                            );
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Erreur de chargement du devis: $e'),
                                              ),
                                            );
                                          }
                                        },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mutedSurface(context),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 18,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clientName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary(context),
                                              ),
                                            ),
                                            if (refQ.isNotEmpty)
                                              Text(
                                                refQ,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary(context),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _formatEuro(amount),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ],
                                  ),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary(context),
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

                      // Deduplicate by quoteNumber before summing
                      final seenSumRefs = <String>{};
                      final uniqueForSum = quotes.where((q) {
                        final ref = (q['quoteNumber'] ?? q['reference'] ?? q['id'] ?? '').toString();
                        if (ref.isEmpty) return true;
                        return seenSumRefs.add(ref);
                      }).toList();

                      for (final q in uniqueForSum) {
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
                            status == 'pending' ||
                            status.contains('attente');

                        if (isSigned) {
                          factured += amount;
                        } else if (isAwaiting) {
                          awaitingSignature += amount;
                        }
                        // Archived or unknown statuses are not counted
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
