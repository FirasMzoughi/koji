import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

class ClientQuotesScreen extends ConsumerStatefulWidget {
  const ClientQuotesScreen({super.key});

  @override
  ConsumerState<ClientQuotesScreen> createState() => _ClientQuotesScreenState();
}

class _ClientQuotesScreenState extends ConsumerState<ClientQuotesScreen>
    with SingleTickerProviderStateMixin {
  static const _darkNavy = Color(0xFF0F172A);
  static const _blue = Color(0xFF1D74FF);
  static const _slate = Color(0xFF64748B);

  late TabController _tabController;
  List<Map<String, dynamic>> _quotes = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      final quotes =
          await ref.read(userRepositoryProvider).getClientQuotes(user.id);
      if (mounted) setState(() { _quotes = quotes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return _quotes.where((quote) {
      if (q.isEmpty) return true;
      final ref2 = (quote['quoteNumber'] ?? quote['reference'] ?? '').toString().toLowerCase();
      final client = quote['client'] as Map<String, dynamic>? ?? {};
      final name = (client['name'] ?? '').toString().toLowerCase();
      return ref2.contains(q) || name.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _byStatus(String type) {
    return _filtered.where((q) {
      final s = (q['status'] ?? '').toString().toLowerCase();
      if (type == 'pending') {
        return s == 'generated' || s == 'en_cours' || s == 'draft' ||
            s == 'pending' || s.contains('attente') || s.contains('envoy');
      } else if (type == 'signed') {
        return s == 'signed' || s == 'accepted' || s == 'validated' ||
            s.contains('sign') || s.contains('accept');
      }
      return true; // all
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style:
                      const TextStyle(fontSize: 14, color: _darkNavy),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un devis...',
                    hintStyle: TextStyle(fontSize: 14, color: _slate),
                    prefixIcon:
                        Icon(Icons.search, color: _slate, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Tabs ──
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: _slate,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Tous'),
                  Tab(text: 'À signer'),
                  Tab(text: 'Signés'),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_byStatus('all')),
                        _buildList(_byStatus('pending')),
                        _buildList(_byStatus('signed')),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          const Text(
            'Mes Devis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_quotes.length} devis',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aucun devis',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vos devis apparaîtront ici',
              style:
                  TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _quoteCard(items[i]),
      ),
    );
  }

  Widget _quoteCard(Map<String, dynamic> quote) {
    final status = (quote['status'] ?? '').toString().toLowerCase();
    final isPending = status == 'generated' || status == 'en_cours' ||
        status == 'draft' || status == 'pending' ||
        status.contains('attente') || status.contains('envoy');
    final isSigned = status == 'signed' || status == 'accepted' ||
        status == 'validated' || status.contains('sign') ||
        status.contains('accept');

    final ref2 =
        (quote['quoteNumber'] ?? quote['reference'] ?? 'Devis').toString();
    final client = quote['client'] as Map<String, dynamic>? ?? {};
    final artisanName =
        (client['company'] as String?) ?? (client['name'] as String?) ?? 'Artisan';
    final totals = quote['totals'] as Map<String, dynamic>? ?? {};
    final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;
    final createdAt = quote['created_at'] as String?;
    final dateStr = createdAt != null
        ? _formatDate(DateTime.tryParse(createdAt))
        : '';

    Color statusColor;
    String statusLabel;
    Color statusBg;
    IconData statusIcon;

    if (isSigned) {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      statusLabel = 'Signé';
      statusIcon = Icons.check_circle_outline;
    } else if (isPending) {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFEF3C7);
      statusLabel = 'À signer';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = _slate;
      statusBg = const Color(0xFFF1F5F9);
      statusLabel = 'Brouillon';
      statusIcon = Icons.edit_outlined;
    }

    return GestureDetector(
      onTap: isPending ? () => context.push('/signature/list') : null,
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
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
                        artisanName,
                        style: const TextStyle(
                            fontSize: 12, color: _slate),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _darkNavy,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: _slate),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isPending)
                  GestureDetector(
                    onTap: () => context.push('/signature/list'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.draw_outlined,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Signer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
