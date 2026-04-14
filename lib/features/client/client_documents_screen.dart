import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

class ClientDocumentsScreen extends ConsumerStatefulWidget {
  const ClientDocumentsScreen({super.key});

  @override
  ConsumerState<ClientDocumentsScreen> createState() =>
      _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState
    extends ConsumerState<ClientDocumentsScreen> {
  static const _darkNavy = Color(0xFF0F172A);
  static const _blue = Color(0xFF1D74FF);
  static const _slate = Color(0xFF64748B);

  List<Map<String, dynamic>> _quotes = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    try {
      final quotes =
          await ref.read(userRepositoryProvider).getClientQuotes(user.id);
      // Only show finalized (signed / accepted) quotes as "documents"
      final docs = quotes.where((q) {
        final s = (q['status'] ?? '').toString().toLowerCase();
        return s == 'signed' || s == 'accepted' || s == 'validated' ||
            s.contains('sign') || s.contains('accept') || s == 'generated';
      }).toList();
      if (mounted) setState(() { _quotes = docs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _quotes;
    return _quotes.where((doc) {
      final ref2 =
          (doc['quoteNumber'] ?? doc['reference'] ?? '').toString().toLowerCase();
      return ref2.contains(q);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  const Text(
                    'Mes Documents',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkNavy,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_quotes.length} fichiers',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14, color: _darkNavy),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un document...',
                    hintStyle: TextStyle(fontSize: 14, color: _slate),
                    prefixIcon:
                        Icon(Icons.search, color: _slate, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Category chips ──
            _buildCategoryRow(),

            const SizedBox(height: 8),

            // ── List ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDocs,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _documentCard(_filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip('Tous', true),
          _chip('Devis', false),
          _chip('Factures', false),
          _chip('Contrats', false),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _blue : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : _slate,
        ),
      ),
    );
  }

  Widget _documentCard(Map<String, dynamic> doc) {
    final ref2 =
        (doc['quoteNumber'] ?? doc['reference'] ?? 'Document').toString();
    final client = doc['client'] as Map<String, dynamic>? ?? {};
    final artisan =
        (client['company'] as String?) ?? (client['name'] as String?) ?? 'Artisan';
    final totals = doc['totals'] as Map<String, dynamic>? ?? {};
    final amount = (totals['ttc'] as num?)?.toDouble() ?? 0;
    final createdAt = doc['created_at'] as String?;
    final date = createdAt != null
        ? _formatDate(DateTime.tryParse(createdAt))
        : '';
    final status = (doc['status'] ?? '').toString().toLowerCase();
    final isSigned = status.contains('sign') || status.contains('accept') ||
        status == 'validated';

    return Container(
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
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSigned
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSigned
                  ? Icons.picture_as_pdf_outlined
                  : Icons.description_outlined,
              color: isSigned
                  ? const Color(0xFF10B981)
                  : const Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
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
                const SizedBox(height: 2),
                Text(
                  artisan,
                  style: const TextStyle(fontSize: 12, color: _slate),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSigned
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSigned ? 'Signé' : 'En attente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSigned
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(
                            fontSize: 11, color: _slate),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Amount + download
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
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_outlined,
                    size: 16, color: _slate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucun document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos devis et factures signés\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
