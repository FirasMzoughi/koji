import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:koji/core/notification_service.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/quote/quote_list_screen.dart';
import 'package:koji/features/quote/chantier_list_screen.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:koji/features/quote/providers/quote_message_provider.dart';
import 'package:koji/features/quote/models/quote_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import widgets
import 'package:koji/features/home/widgets/bottom_nav_item.dart';
import 'package:koji/features/home/widgets/home_header.dart';
import 'package:koji/features/home/widgets/dashboard_section.dart';
import 'package:koji/features/home/widgets/create_project_button.dart';
import 'package:koji/features/home/widgets/app_drawer.dart';
import 'package:koji/features/home/widgets/home_today_tasks.dart';
import 'package:koji/features/home/notifications/app_notification.dart';
import 'package:koji/features/home/notifications/notifications_provider.dart';
import 'package:koji/features/home/notifications/notifications_panel.dart';
import 'package:koji/features/subscription/providers/subscription_provider.dart';
import 'package:koji/features/subscription/data/subscription_repository.dart';
import 'package:koji/features/subscription/paywall_screen.dart';

/// Main home screen - STATEFUL for tab management
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _notifiedSignaturesKey = 'notified_signed_quote_ids';
  // Guards the very first stream emission: on cold start every already-signed
  // quote would otherwise look "new". We seed the persisted set on first run
  // instead of spamming the user with historical signatures.
  bool _signatureBaselineDone = false;

  // Same idea for inbound client messages: remember the latest client-message
  // timestamp we have already alerted per quote, and skip the noisy toast on
  // the first emission after launch.
  static const _notifiedMessagesKey = 'notified_client_message_at';
  bool _messageBaselineDone = false;
  // The company's own email, used to tell our outbound messages from the
  // client's so we only get notified about the client's replies.
  String _companyEmail = '';
  // The quotes stream emits on quote changes, not on new messages — so it can't
  // be the only trigger for message notifications. We cache the latest quotes
  // and poll for new client messages on a timer while the app is open.
  List<Map<String, dynamic>> _latestQuotes = const [];
  Timer? _messagePollTimer;
  // Guards against the stream listener and the poll timer running the message
  // check at the same time (which could double-notify or race on prefs).
  bool _handlingMessages = false;

  @override
  void initState() {
    super.initState();
    // Watch the live quotes stream and raise a notification + banner the moment
    // a client signs (status -> 'accepte' / signed_at set by the web app) or
    // sends a new message on a devis.
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      _loadCompanyEmail(user.id);
      // Start the 7-day trial (first time) and resolve trial/subscription
      // status so the banner + gate know whether access is active.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(subscriptionStatusProvider.notifier).load();
      });
      ref.listenManual<AsyncValue<List<Map<String, dynamic>>>>(
        userQuotesProvider(user.id),
        (previous, next) {
          final quotes = next.valueOrNull;
          if (quotes != null) {
            _latestQuotes = quotes;
            _handleSignedQuotes(quotes);
            _handleNewMessages(quotes);
          }
        },
        fireImmediately: true,
      );

      // Poll for new client messages independently of the quotes stream so a
      // message raises a notification even when no quote field changes.
      _messagePollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        if (_latestQuotes.isNotEmpty) _handleNewMessages(_latestQuotes);
      });
    }
  }

  @override
  void dispose() {
    _messagePollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCompanyEmail(String userId) async {
    // Fall back to the auth email until the business profile resolves.
    _companyEmail = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    try {
      final userData = await ref.read(userRepositoryProvider).getUser(userId);
      final biz = userData?['business_info'] as Map<String, dynamic>?;
      final emailPro = (biz?['emailPro'] as String?)?.trim() ?? '';
      if (emailPro.isNotEmpty) _companyEmail = emailPro;
    } catch (_) {
      // Keep the auth-email fallback.
    }
  }

  /// Detect quotes that became signed since we last looked, notify once each.
  ///
  /// Two layers, intentionally separate:
  ///  - The in-app bell notification is created for *every* signed quote that
  ///    doesn't already have one. `NotificationsNotifier.add` is idempotent by
  ///    id (`sign_<quoteId>`), so replays are harmless. This is what makes a
  ///    signature visible when the user opens the app — even if the client
  ///    signed while the app was closed.
  ///  - The noisy OS toast + in-app snackbar only fire for signatures detected
  ///    *while the app is open* (i.e. after the first stream emission), so we
  ///    don't pop a banner for every historical signature on cold start.
  Future<void> _handleSignedQuotes(List<Map<String, dynamic>> quotes) async {
    final signed = quotes.where((q) => QuoteStatus.isSigned(q)).toList();

    // First emission after launch establishes the baseline of what was already
    // signed; those get a bell entry but no toast/snackbar.
    final isBaseline = !_signatureBaselineDone;
    _signatureBaselineDone = true;

    final prefs = await SharedPreferences.getInstance();
    final alerted = prefs.getStringList(_notifiedSignaturesKey)?.toSet() ?? {};

    for (final q in signed) {
      final id = (q['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final client = q['client'] as Map<String, dynamic>? ?? {};
      final clientName = (client['name'] as String?)?.trim().isNotEmpty == true
          ? (client['name'] as String)
          : 'Un client';
      final totals = q['totals'] as Map<String, dynamic>? ?? {};
      final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;
      final amountLabel = amount > 0 ? _formatEuro(amount) : null;

      // Persistent in-app notification — lights up the header bell badge and
      // appears in the notifications panel on Home. Idempotent by id, so this
      // safely fires for every signed quote on every emission.
      await ref.read(notificationsProvider.notifier).add(
            AppNotification(
              id: 'sign_$id',
              title: 'Devis signé ✍️',
              body: amountLabel != null
                  ? '$clientName a signé le devis ($amountLabel).'
                  : '$clientName a signé le devis.',
              createdAt: DateTime.now(),
            ),
          );

      // Only show the loud OS notification + snackbar for fresh signatures
      // (detected while the app is open and not yet alerted).
      if (!isBaseline && !alerted.contains(id)) {
        await NotificationService.instance.notifySignature(
          quoteId: id,
          clientName: clientName,
          amountLabel: amountLabel,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$clientName a signé un devis ✍️'),
              action: SnackBarAction(
                label: 'Voir',
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
            ),
          );
        }
      }

      alerted.add(id);
    }

    await prefs.setStringList(_notifiedSignaturesKey, alerted.toList());
  }

  /// Detect new inbound (client-authored) messages on the user's devis and
  /// raise a notification once per new message.
  ///
  /// Mirrors [_handleSignedQuotes]: an idempotent bell entry per message
  /// (`msg_<quoteId>_<createdAt>`) plus a one-time toast for messages that
  /// arrive while the app is open. We persist the latest alerted client-message
  /// timestamp per quote so reopening the app doesn't re-notify, and seed that
  /// baseline silently on the first emission after launch.
  Future<void> _handleNewMessages(List<Map<String, dynamic>> quotes) async {
    if (_handlingMessages) return;
    _handlingMessages = true;
    try {
      await _checkNewMessages(quotes);
    } finally {
      _handlingMessages = false;
    }
  }

  Future<void> _checkNewMessages(List<Map<String, dynamic>> quotes) async {
    // Without the company email we can't tell our own messages from the
    // client's, so we'd wrongly notify on outbound messages. Wait for it.
    if (_companyEmail.trim().isEmpty) return;

    final quoteIds = quotes
        .map((q) => (q['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (quoteIds.isEmpty) return;

    Map<String, String> latest;
    try {
      latest = await ref
          .read(quoteMessageRepositoryProvider)
          .latestClientMessageAtForQuotes(quoteIds, _companyEmail);
    } catch (_) {
      return; // messaging tables unavailable — fail quietly
    }
    if (latest.isEmpty) {
      _messageBaselineDone = true;
      return;
    }

    final isBaseline = !_messageBaselineDone;
    _messageBaselineDone = true;

    final prefs = await SharedPreferences.getInstance();
    // Stored as "<quoteId>=<iso>" entries (SharedPreferences has no map type).
    final stored = prefs.getStringList(_notifiedMessagesKey) ?? <String>[];
    final seenAt = <String, String>{};
    for (final e in stored) {
      final i = e.indexOf('=');
      if (i > 0) seenAt[e.substring(0, i)] = e.substring(i + 1);
    }

    // Map quote id -> client name for nicer notification copy.
    final nameById = <String, String>{};
    for (final q in quotes) {
      final id = (q['id'] ?? '').toString();
      final client = q['client'] as Map<String, dynamic>? ?? {};
      final name = (client['name'] as String?)?.trim();
      if (id.isNotEmpty) {
        nameById[id] = (name != null && name.isNotEmpty) ? name : 'Un client';
      }
    }

    latest.forEach((quoteId, createdAt) {
      final previous = seenAt[quoteId];
      final isNew = previous == null || createdAt.compareTo(previous) > 0;
      if (!isNew) return;

      final clientName = nameById[quoteId] ?? 'Un client';

      // Persistent bell entry, idempotent by id (includes the timestamp so each
      // new client message produces a distinct notification).
      ref.read(notificationsProvider.notifier).add(
            AppNotification(
              id: 'msg_${quoteId}_$createdAt',
              title: 'Nouveau message ✉️',
              body: '$clientName vous a envoyé un message sur un devis.',
              createdAt: DateTime.now(),
              type: 'message',
            ),
          );

      if (!isBaseline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$clientName vous a envoyé un message ✉️'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => context.push('/quote/messages', extra: {
                'quoteId': quoteId,
                'clientName': clientName,
              }),
            ),
          ),
        );
      }

      seenAt[quoteId] = createdAt;
    });

    await prefs.setStringList(
      _notifiedMessagesKey,
      seenAt.entries.map((e) => '${e.key}=${e.value}').toList(),
    );
  }

  /// Open the notifications panel; tapping a notification jumps to the Devis tab.
  Future<void> _openNotifications() async {
    final tapped = await NotificationsPanel.show(context);
    if (tapped == true && mounted) {
      setState(() => _selectedIndex = 1);
    }
  }

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
    _guard(() => context.push('/chantier/create'));
  }

  /// Run [action] only if the entreprise still has access (trial active or
  /// subscribed). Once the 7-day trial has expired, open the paywall instead.
  /// While the status is still loading/unknown we allow the action (we never
  /// block on a transient state — only the explicit `expired` state gates).
  void _guard(VoidCallback action) {
    final status = ref.read(subscriptionStatusProvider).valueOrNull;
    if (status != null && status.state == AccessState.expired) {
      _openPaywall();
      return;
    }
    action();
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
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
                        _guard(() => context.push('/quote/room-selection',
                            extra: <String>[]));
                      },
                    ),
                    _buildPlusActionItem(
                      label: 'Tâche',
                      icon: Icons.fact_check,
                      onTap: () {
                        Navigator.pop(context);
                        _guard(() => context.push('/chantier/add-task',
                            extra: <String, dynamic>{}));
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
                    _buildPlusActionItem(
                      label: 'Messages',
                      icon: Icons.forum_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/messages');
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

  /// Trial countdown / subscribe banner. Hidden when subscribed or while the
  /// status is still loading; an empty SizedBox keeps the layout clean.
  Widget _buildSubscriptionBanner() {
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();

    if (status.state == AccessState.trial) {
      final days = status.trialDaysLeft;
      return _bannerCard(
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF0A1227),
        icon: Icons.hourglass_bottom,
        title: 'Essai gratuit',
        subtitle: days <= 1
            ? "Dernier jour d'essai"
            : '$days jours restants',
        cta: "S'abonner",
      );
    }

    if (status.state == AccessState.expired) {
      return _bannerCard(
        bg: const Color(0xFFFEF2F2),
        fg: const Color(0xFFB91C1C),
        icon: Icons.lock_outline,
        title: 'Essai terminé',
        subtitle: 'Abonnez-vous pour continuer à utiliser Koji.',
        cta: "S'abonner",
      );
    }

    return const SizedBox.shrink();
  }

  Widget _bannerCard({
    required Color bg,
    required Color fg,
    required IconData icon,
    required String title,
    required String subtitle,
    required String cta,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: fg, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: _openPaywall,
            style: TextButton.styleFrom(
              backgroundColor: fg,
              foregroundColor: bg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(cta,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final quotesAsync = user == null
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(userQuotesProvider(user.id));

    return Column(
      children: [
        // Header
        HomeHeader(
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationsTap: _openNotifications,
        ),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Trial / subscription banner (only while trial or expired).
                _buildSubscriptionBanner(),

                // Create Project Button
                CreateProjectButton(onTap: _onCreateProject),

                const SizedBox(height: 32),

                // A faire maintenant — today's + overdue scheduled tasks,
                // grouped by chantier (see HomeTodayTasks).
                DashboardSection(
                  title: 'A faire maintenant',
                  onTap: () => context.push('/planning'),
                  child: user == null
                      ? const DashboardEmptyState(
                          title: 'Connexion requise',
                          subtitle: 'Connectez-vous pour voir vos tâches',
                        )
                      : const HomeTodayTasks(),
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
                                '+ ${activeChantiers.length - visible.length} autres',
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

                      final inProgress = uniqueQuotes
                          .where((q) => QuoteStatus.isInProgress(q))
                          .toList();

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

                        if (QuoteStatus.isSigned(q)) {
                          factured += amount;
                        } else if (QuoteStatus.isInProgress(q)) {
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
