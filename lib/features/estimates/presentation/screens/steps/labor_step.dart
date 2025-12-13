import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:koji/features/estimates/presentation/providers/estimate_provider.dart';

class LaborStep extends ConsumerStatefulWidget {
  const LaborStep({super.key});

  @override
  ConsumerState<LaborStep> createState() => _LaborStepState();
}

class _LaborStepState extends ConsumerState<LaborStep> {
  late TextEditingController _surfaceController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftEstimateProvider);
    _surfaceController = TextEditingController(text: draft.surface > 0 ? draft.surface.toString() : '');
    _priceController = TextEditingController(text: draft.pricePerSqMeter > 0 ? draft.pricePerSqMeter.toString() : '');
  }

  @override
  void dispose() {
    _surfaceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _update() {
    final surface = double.tryParse(_surfaceController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    ref.read(draftEstimateProvider.notifier).updateLabor(surface, price);
  }

  @override
  Widget build(BuildContext context) {
    // Watch draft to get calculated cost
    final draft = ref.watch(draftEstimateProvider);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _surfaceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Surface (m²)',
                  suffixText: 'm²',
                ),
                onChanged: (_) => _update(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix / m²',
                  suffixText: '€',
                ),
                onChanged: (_) => _update(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Card(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Main d\'œuvre :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.simpleCurrency(locale: 'fr_FR').format(draft.laborCost),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
