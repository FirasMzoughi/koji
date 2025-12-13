import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:koji/providers/estimate_provider.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = ref.watch(estimateProvider);

    // Temp variables for easier access
    final client = provider.tempClient;
    final total = provider.tempTotalCost;

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
                      Text(client?.name ?? 'Nom du client', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(client?.address ?? ''),
                      Text(client?.phone ?? ''),
                      
                      const SizedBox(height: 32),
                      
                      // Description
                      const Text('DESCRIPTION :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(provider.tempDescription.isNotEmpty ? provider.tempDescription : 'Aucune description'),
                      
                      const SizedBox(height: 32),
                      
                      // Breakdowns
                      _buildSectionHeader('Main d\'œuvre', theme),
                      _buildLineItem(
                        context, 
                        'Surface ${provider.tempSurface}m² x ${provider.tempPricePerSqMeter}€', 
                        provider.tempLaborCost
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildSectionHeader('Fournitures', theme),
                      ...provider.tempSupplies.map((s) => 
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
                                NumberFormat.simpleCurrency(locale: 'fr_FR').format(total),
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
                onPressed: () {
                  provider.finalizeEstimate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Devis validé et enregistré ! 📄'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).popUntil((route) => route.settings.name == '/dashboard');
                },
                icon: const Icon(Icons.check_circle_outline),
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
