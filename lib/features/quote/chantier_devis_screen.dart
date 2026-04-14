import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/route_args.dart';
import 'package:koji/features/quote/providers/chantier_provider.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';

class ChantierDevisScreen extends ConsumerWidget {
  final Map<String, dynamic> data;
  const ChantierDevisScreen({super.key, required this.data});

  static const _kDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chantierId = data['id'] as String?;

    if (chantierId == null) {
      return const Scaffold(body: Center(child: Text('ID Chantier manquant')));
    }

    final quotesAsync = ref.watch(chantierQuotesProvider(chantierId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: quotesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (quotes) => quotes.isEmpty
                    ? _buildEmptyState(context, ref, chantierId)
                    : _buildDevisList(context, ref, chantierId, quotes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0EB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _kDark, size: 30),
            ),
          ),
          const Text(
            'Devis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, String chantierId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Aucun Devis',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _createDevis(context, ref, chantierId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Créer un devis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
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

  Widget _buildDevisList(BuildContext context, WidgetRef ref, String chantierId,
      List<Map<String, dynamic>> quotes) {
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          itemCount: quotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildDevisTile(context, quotes[i]),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () => _createDevis(context, ref, chantierId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _kDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Créer un devis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevisTile(BuildContext context, Map<String, dynamic> devis) {
    final String ref = devis['reference'] as String? ?? 'D-????';
    final double amount = (devis['total_ht'] as num?)?.toDouble() ?? 0;
    final String status = devis['status'] as String? ?? 'Draft';
    final String date = devis['date'] as String? ?? '';
    final client = devis['client'] as Map<String, dynamic>? ?? {};
    final String clientName = client['name'] as String? ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'Signed':
        statusColor = const Color(0xFF22C55E);
        statusLabel = 'Devis signé';
        break;
      case 'Sent':
        statusColor = const Color(0xFF64748B);
        statusLabel = 'En attente signature';
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'En cours';
    }

    return GestureDetector(
      onTap: () {
        context.push('/quote/detail', extra: QuoteDetailArgs(data: devis));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined,
                  color: _kDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (clientName.isNotEmpty) clientName,
                      if (date.isNotEmpty) date,
                      '${_fmt(amount)} € HT',
                    ].join('  ·  '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createDevis(BuildContext context, WidgetRef ref, String chantierId) {
    // Store chantierId in quote creation state so it gets saved with the quote
    ref.read(quoteCreationProvider.notifier).reset();
    ref.read(quoteCreationProvider.notifier).setChantierId(chantierId);
    context.push('/quote/visual-proofs');
  }

  String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }
}
