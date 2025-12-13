import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:koji/features/estimates/data/pdf_service.dart';
import 'package:koji/features/estimates/presentation/providers/estimate_provider.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(draftEstimateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Aperçu du Devis")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Paper look
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DEVIS',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const Divider(height: 32, thickness: 2),
                      
                      // Client Info
                      const Text('CLIENT :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(draft.client?.name ?? 'Nom du client', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(draft.client?.address ?? ''),
                      Text(draft.client?.phone ?? ''),
                      
                      const SizedBox(height: 32),
                      
                      // Description
                      const Text('DESCRIPTION :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(draft.description.isNotEmpty ? draft.description : 'Aucune description'),
                      
                      const SizedBox(height: 32),
                      
                      // Breakdowns
                      _buildSectionHeader('Main d\'œuvre', theme),
                      _buildLineItem(
                        context, 
                        'Surface ${draft.surface}m² x ${draft.pricePerSqMeter}€', 
                        draft.laborCost
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSectionHeader('Fournitures', theme),
                      ...draft.supplies.map((s) => 
                        _buildLineItem(context, '${s.name} (x${s.quantity})', s.totalPrice)
                      ),
                      
                      const Divider(height: 48, thickness: 2),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('TOTAL TTC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(
                                NumberFormat.simpleCurrency(locale: 'fr_FR').format(draft.totalCost),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Generate and save PDF to Downloads
                  final filePath = await PdfService.generateAndSaveEstimatePdf(
                    draft.client,
                    draft.description,
                    draft.surface,
                    draft.pricePerSqMeter,
                    draft.laborCost,
                    draft.supplies,
                    draft.suppliesCost,
                    draft.totalCost,
                  );
                  
                  // Save the estimate
                  ref.read(draftEstimateProvider.notifier).finalizeAndSave();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF enregistré dans Downloads ! 📄\n$filePath'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    context.go('/dashboard');
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Valider et Exporter en PDF'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLineItem(BuildContext context, String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            NumberFormat.simpleCurrency(locale: 'fr_FR').format(price),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
