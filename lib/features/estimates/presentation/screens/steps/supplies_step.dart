import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:koji/features/estimates/presentation/providers/estimate_provider.dart';

class SuppliesStep extends ConsumerStatefulWidget {
  const SuppliesStep({super.key});

  @override
  ConsumerState<SuppliesStep> createState() => _SuppliesStepState();
}

class _SuppliesStepState extends ConsumerState<SuppliesStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _addSupply() {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final name = _nameController.text;
      final price = double.tryParse(_priceController.text) ?? 0;
      final qty = int.tryParse(_qtyController.text) ?? 1;

      ref.read(draftEstimateProvider.notifier).addSupply(name, price, qty);

      _nameController.clear();
      _priceController.clear();
      _qtyController.text = '1';
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftEstimateProvider);

    return Column(
      children: [
        // Add Supply Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de la fourniture'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix Unit. (€)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qté'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addSupply,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // List of Supplies
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Liste des fournitures',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: draft.supplies.length,
          itemBuilder: (context, index) {
            final item = draft.supplies[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('${item.quantity} x ${NumberFormat.simpleCurrency(locale: 'fr_FR').format(item.price)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.simpleCurrency(locale: 'fr_FR').format(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref.read(draftEstimateProvider.notifier).removeSupply(item.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Fournitures :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              NumberFormat.simpleCurrency(locale: 'fr_FR').format(draft.suppliesCost),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
