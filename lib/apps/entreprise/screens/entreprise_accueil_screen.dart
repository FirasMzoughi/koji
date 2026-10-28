import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_widgets.dart';

/// Entreprise dashboard with KPIs and quick actions.
class EntrepriseAccueilScreen extends ConsumerWidget {
  const EntrepriseAccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Accueil Koji Pro',
      appBarOnPhone: true,
      main: [
        // KPIs grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KpiCard('Devis', '5', Colors.orange),
            _KpiCard('Chantiers', '12', Colors.blue),
            _KpiCard('Factures', '€45K', Colors.green),
            _KpiCard('Messages', '23', Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Actions rapides',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KojiButton(
                label: 'Créer devis',
                onPressed: () => context.push('/entreprise/devis'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: KojiButton(
                label: 'Nouveau client',
                variant: KojiButtonVariant.secondary,
                onPressed: () => context.push('/entreprise/clients'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Activité récente',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Devis #${1000 + i} créé',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Client: SARL Dupont',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
