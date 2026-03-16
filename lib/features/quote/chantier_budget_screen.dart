import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/features/quote/repositories/chantier_repository.dart';

class ChantierBudgetScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const ChantierBudgetScreen({super.key, required this.data});

  @override
  State<ChantierBudgetScreen> createState() => _ChantierBudgetScreenState();
}

class _ChantierBudgetScreenState extends State<ChantierBudgetScreen> {
  static const _kDark = Color(0xFF0F172A);

  final _repository = ChantierRepository();
  bool _isLoading = true;

  double _mainOeuvreReal = 0;
  double _mainOeuvreEst = 0;
  double _fournitureReal = 0;
  double _fournitureEst = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final chantierId = widget.data['id'] as String?;
    if (chantierId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final budget = await _repository.getBudget(chantierId);
      if (mounted && budget != null) {
        setState(() {
          _mainOeuvreReal =
              num.tryParse(budget['main_oeuvre_real']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _mainOeuvreEst =
              num.tryParse(budget['main_oeuvre_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _fournitureReal =
              num.tryParse(budget['fourniture_real']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _fournitureEst =
              num.tryParse(budget['fourniture_estimated']?.toString() ?? '0')
                      ?.toDouble() ??
                  0;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kDark))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: _buildBudgetCard(
                        mainOeuvreReal: _mainOeuvreReal,
                        mainOeuvreEst: _mainOeuvreEst,
                        fournitureReal: _fournitureReal,
                        fournitureEst: _fournitureEst,
                      ),
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
            'Budget',
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

  Widget _buildBudgetCard({
    required double mainOeuvreReal,
    required double mainOeuvreEst,
    required double fournitureReal,
    required double fournitureEst,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildBudgetRow(
            label: "Main d'œuvre",
            real: mainOeuvreReal,
            estimated: mainOeuvreEst,
          ),
          const SizedBox(height: 20),
          _buildBudgetRow(
            label: 'Fourniture',
            real: fournitureReal,
            estimated: fournitureEst,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow({
    required String label,
    required double real,
    required double estimated,
  }) {
    final bool overBudget = real > estimated;
    final double progress =
        estimated > 0 ? (real / estimated).clamp(0.0, 1.0) : 0.0;
    final Color barColor = overBudget ? const Color(0xFFEF4444) : _kDark;

    final String realStr = _fmt(real);
    final String estStr = _fmt(estimated);

    return GestureDetector(
      onTap: () {
        if (label == "Main d'œuvre") {
          _editBudget(
              label, 'mainOeuvreReal', 'mainOeuvreEstimated', real, estimated);
        } else {
          _editBudget(
              label, 'fournitureReal', 'fournitureEstimated', real, estimated);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kDark,
                ),
              ),
              Text(
                '$realStr / $estStr €',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: overBudget ? const Color(0xFFEF4444) : _kDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  void _editBudget(String title, String dataKeyReal, String dataKeyEst,
      double currentReal, double currentEst) {
    final realCtrl =
        TextEditingController(text: currentReal.toStringAsFixed(0));
    final estCtrl = TextEditingController(text: currentEst.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Modifier $title',
          style: const TextStyle(
              fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: _kDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: estCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Estimé (€)',
                labelStyle: TextStyle(fontFamily: 'Outfit'),
              ),
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: realCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Coût Réel (€)',
                labelStyle: TextStyle(fontFamily: 'Outfit'),
              ),
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style:
                    TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newReal = double.tryParse(realCtrl.text) ?? 0;
              final newEst = double.tryParse(estCtrl.text) ?? 0;
              final chantierId = widget.data['id'] as String?;

              if (chantierId != null) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  final updates = <String, dynamic>{};
                  if (dataKeyReal == 'mainOeuvreReal') {
                    updates['main_oeuvre_real'] = newReal;
                    updates['main_oeuvre_estimated'] = newEst;
                  } else {
                    updates['fourniture_real'] = newReal;
                    updates['fourniture_estimated'] = newEst;
                  }

                  await _repository.updateBudget(chantierId, updates);
                  await _loadBudget(); // Refresh view
                } catch (e) {
                  debugPrint('Error updating budget: $e');
                  if (mounted) setState(() => _isLoading = false);
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Enregistrer',
                style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    // e.g. 2400 → "2 400"
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }
}
