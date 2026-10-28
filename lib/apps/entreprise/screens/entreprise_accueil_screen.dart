import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';

/// Entreprise dashboard with KPIs and quick actions.
class EntrepriseAccueilScreen extends ConsumerWidget {
  const EntrepriseAccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Accueil',
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
            _KpiCard(
              label: 'Devis en attente',
              value: '5',
              color: const Color(0xffff9800),
              icon: KojiIcons.file,
            ),
            _KpiCard(
              label: 'Chantiers actifs',
              value: '12',
              color: const Color(0xff0052cc),
              icon: KojiIcons.briefcase,
            ),
            _KpiCard(
              label: 'Factures (mois)',
              value: '€45,200',
              color: const Color(0xff28a745),
              icon: KojiIcons.receipt,
            ),
            _KpiCard(
              label: 'Messages',
              value: '23',
              color: const Color(0xff9c27b0),
              icon: KojiIcons.message,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick actions
        Text(
          'Actions rapides',
          style: context.koji.typography.labelLarge,
        ),
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

        // Recent activity
        Text(
          'Activité récente',
          style: context.koji.typography.labelLarge,
        ),
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
                  Text(
                    'Devis #${1000 + i} créé',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Client: SARL Dupont',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.koji.muted,
                    ),
                  ),
                ];
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
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

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
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.koji.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
