import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:koji/providers/estimate_provider.dart';

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
    final provider = ref.read(estimateProvider);
    _surfaceController = TextEditingController(text: provider.tempSurface > 0 ? provider.tempSurface.toString() : '');
    _priceController = TextEditingController(text: provider.tempPricePerSqMeter > 0 ? provider.tempPricePerSqMeter.toString() : '');
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
    ref.read(estimateProvider).updateLabor(surface, price);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(estimateProvider);
    
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
                  NumberFormat.simpleCurrency(locale: 'fr_FR').format(provider.tempLaborCost),
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
