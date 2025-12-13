import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:koji/features/estimates/data/models/estimate_model.dart';

class EstimateCard extends StatelessWidget {
  final Estimate estimate;

  const EstimateCard({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final statusColor = estimate.status == 'Validé' ? Colors.green : Colors.orange;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              estimate.client.name.isNotEmpty ? estimate.client.name[0] : '?',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            estimate.client.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd MMM yyyy', 'fr_FR').format(estimate.date)),
              Text(
                estimate.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                NumberFormat.simpleCurrency(locale: 'fr_FR').format(estimate.totalCost),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estimate.status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          onTap: () {
            // Can add Detail View later
          },
        ),
      ),
    );
  }
}
