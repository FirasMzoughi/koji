import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChantierDevisScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierDevisScreen({super.key, required this.data});

  @override
  State<ChantierDevisScreen> createState() => _ChantierDevisScreenState();
}

class _ChantierDevisScreenState extends State<ChantierDevisScreen> {
  static const _kDark = Color(0xFF0F172A);

  // Sample devis list — in a real app these would come from widget.data / backend
  late List<Map<String, dynamic>> _devisList;

  @override
  void initState() {
    super.initState();
    _devisList = List<Map<String, dynamic>>.from(
      (widget.data['devis'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child:
                  _devisList.isEmpty ? _buildEmptyState() : _buildDevisList(),
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
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Empty card
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
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // "Créer un devis" button
          GestureDetector(
            onTap: _createDevis,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Créer un devis',
                    style: TextStyle(
                      fontFamily: 'Outfit',
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

  Widget _buildDevisList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: _devisList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildDevisTile(_devisList[i]),
    );
  }

  Widget _buildDevisTile(Map<String, dynamic> devis) {
    final String ref = devis['ref'] as String? ?? 'D-????';
    final String label = devis['label'] as String? ?? 'Estimé';
    final double amount = (devis['amount'] as num?)?.toDouble() ?? 0;
    final String status = devis['status'] as String? ?? 'En cours';

    Color statusColor;
    switch (status) {
      case 'En cours':
        statusColor = const Color(0xFF3B82F6); // blue
        break;
      case 'Devis signé':
        statusColor = const Color(0xFF22C55E); // green
        break;
      default: // 'En attente signature'
        statusColor = const Color(0xFF64748B); // slate
    }

    return Container(
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
            child:
                const Icon(Icons.description_outlined, color: _kDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$label   ${_fmt(amount)} €',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _createDevis() async {
    await context.push('/quote/visual-proofs');
    // Demo: add a fake devis when returning so the list state shows
    if (mounted) {
      setState(() {
        final refs = ['D-2405', 'D-2506', 'D-2522', 'D-2601'];
        final statuses = ['En cours', 'En attente signature', 'Devis signé'];
        final labels = ['Estimé', 'Estimé', 'Validé'];
        final i = _devisList.length;
        _devisList.add({
          'ref': refs[i % refs.length],
          'label': labels[i % labels.length],
          'amount': 8000.0,
          'status': statuses[i % statuses.length],
        });
        widget.data['devis'] = _devisList;
      });
    }
  }

  String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }
}
