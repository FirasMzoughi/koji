import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koji/models/estimate_model.dart';
import 'package:koji/providers/estimate_provider.dart';
import 'package:go_router/go_router.dart';

class EstimatesListScreen extends ConsumerWidget {
  const EstimatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimates = ref.watch(estimateProvider).estimates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Devis'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: estimates.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: estimates.length,
              itemBuilder: (context, index) {
                return _buildEstimateCard(context, estimates[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(estimateProvider).startNewEstimate();
          context.push('/create-estimate');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Devis'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun devis',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier devis',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard(BuildContext context, Estimate estimate) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du devis
          context.push('/preview');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      estimate.client.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estimate.status == 'Validé'
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: estimate.status == 'Validé'
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      estimate.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: estimate.status == 'Validé'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (estimate.description.isNotEmpty) ...[
                Text(
                  estimate.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(estimate.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFormat.format(estimate.totalCost),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
