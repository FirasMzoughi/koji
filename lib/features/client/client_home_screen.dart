import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/client/client_quotes_screen.dart';
import 'package:koji/features/client/client_documents_screen.dart';
import 'package:koji/features/client/client_profile_screen.dart';
import 'package:koji/features/client/repository/client_repository.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  int _selectedIndex = 0;

  static const _blue = Color(0xFF1D74FF);
  static const _slate = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _ClientDashboard(),
          ClientQuotesScreen(),
          ClientDocumentsScreen(),
          ClientProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_filled, 'Accueil'),
          _navItem(1, Icons.description_outlined, 'Mes Devis'),
          _navItem(2, Icons.folder_outlined, 'Documents'),
          _navItem(3, Icons.person_outline, 'Mon Compte'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? _blue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: 22,
                color: isActive ? _blue : _slate),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? _blue : _slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────
class _ClientDashboard extends ConsumerStatefulWidget {
  const _ClientDashboard();

  @override
  ConsumerState<_ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<_ClientDashboard> {
  static const _darkNavy = Color(0xFF0F172A);
  static const _blue = Color(0xFF1D74FF);
  static const _slate = Color(0xFF64748B);

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentQuotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      final data = await ref.read(userRepositoryProvider).getUser(user.id);
      // Devis are matched by the client's email via their chantiers.
      final quotes = await ref.read(clientRepositoryProvider).getQuotes();
      if (mounted) {
        setState(() {
          _userData = data;
          _recentQuotes = quotes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final firstName = (_userData?['full_name'] as String?)?.split(' ').first ??
        user?.email?.split('@').first ??
        'Client';

    final pending =
        _recentQuotes.where((q) => _isPending(q['status'])).toList();
    final signed =
        _recentQuotes.where((q) => _isSigned(q['status'])).toList();

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(child: _buildHeader(firstName)),

                  // ── Stats Row ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Row(
                        children: [
                          _statCard(
                            icon: Icons.hourglass_top_rounded,
                            label: 'En attente',
                            value: '${pending.length}',
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            icon: Icons.check_circle_outline,
                            label: 'Signés',
                            value: '${signed.length}',
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            icon: Icons.folder_open_outlined,
                            label: 'Total',
                            value: '${_recentQuotes.length}',
                            color: _blue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Que souhaitez-vous faire ?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _darkNavy,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.description_outlined,
                                  title: 'Mes Devis',
                                  subtitle: 'Consulter et signer',
                                  color: _blue,
                                  onTap: () {
                                    // Switch to quotes tab
                                    final state = context
                                        .findAncestorStateOfType<
                                            _ClientHomeScreenState>();
                                    state?.setState(
                                        () => state._selectedIndex = 1);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.folder_outlined,
                                  title: 'Documents',
                                  subtitle: 'Factures & contrats',
                                  color: const Color(0xFF8B5CF6),
                                  onTap: () {
                                    final state = context
                                        .findAncestorStateOfType<
                                            _ClientHomeScreenState>();
                                    state?.setState(
                                        () => state._selectedIndex = 2);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.draw_outlined,
                                  title: 'Signer',
                                  subtitle: 'Devis en attente',
                                  color: const Color(0xFF10B981),
                                  onTap: () => context.push('/signature/list'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.construction_outlined,
                                  title: 'Suivi travaux',
                                  subtitle: 'Avancement',
                                  color: const Color(0xFFEF4444),
                                  onTap: () => context.push('/client/tasks'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.forum_outlined,
                                  title: 'Messages',
                                  subtitle: 'Contacter l\'artisan',
                                  color: const Color(0xFF0EA5E9),
                                  onTap: () => context.push('/client/messages'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _actionCard(
                                  icon: Icons.person_outline,
                                  title: 'Mon Profil',
                                  subtitle: 'Mes informations',
                                  color: const Color(0xFFF59E0B),
                                  onTap: () {
                                    final state = context
                                        .findAncestorStateOfType<
                                            _ClientHomeScreenState>();
                                    state?.setState(
                                        () => state._selectedIndex = 3);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Pending quotes section ──
                  if (pending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Row(
                          children: [
                            const Text(
                              'À signer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _darkNavy,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.push('/signature/list'),
                              child: const Text(
                                'Voir tout',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _pendingQuoteCard(pending[i]),
                        ),
                        childCount: pending.length.clamp(0, 3),
                      ),
                    ),
                  ],

                  // ── If no quotes at all ──
                  if (_recentQuotes.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: _emptyState(
                          icon: Icons.description_outlined,
                          title: 'Aucun devis pour l\'instant',
                          subtitle:
                              'Vos devis envoyés par votre artisan\napparaîtront ici.',
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/LOGO.svg',
                height: 32,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFEAD8B1),
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final state = context
                      .findAncestorStateOfType<_ClientHomeScreenState>();
                  state?.setState(() => state._selectedIndex = 3);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Bonjour, $firstName 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Suivez vos travaux et devis en temps réel',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _slate,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkNavy,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: _slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingQuoteCard(Map<String, dynamic> quote) {
    final ref2 = (quote['quoteNumber'] ?? quote['reference'] ?? 'Devis').toString();
    final client = quote['client'] as Map<String, dynamic>? ?? {};
    final artisan = (client['company'] as String?) ?? 'Artisan';
    final totals = quote['totals'] as Map<String, dynamic>? ?? {};
    final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () => context.push('/signature/list'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEF3C7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _darkNavy,
                    ),
                  ),
                  Text(
                    artisan,
                    style: const TextStyle(fontSize: 12, color: _slate),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${amount.round()} €',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkNavy,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'À signer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  bool _isPending(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    return s == 'generated' || s == 'en_cours' || s == 'draft' ||
        s == 'pending' || s.contains('attente') || s.contains('envoy');
  }

  bool _isSigned(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    return s == 'signed' || s == 'accepted' || s == 'validated' ||
        s.contains('sign') || s.contains('accept');
  }
}