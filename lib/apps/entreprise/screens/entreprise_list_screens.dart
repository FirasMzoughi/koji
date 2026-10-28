import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';

// === DEVIS ===

class EntrepriseDevisScreen extends ConsumerWidget {
  const EntrepriseDevisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Devis',
      appBarOnPhone: true,
      top: [
        Row(
          children: [
            Expanded(
              child: KojiButton(
                label: '+ Créer devis',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
      main: [
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Devis #${1000 + i}'),
                subtitle: Text('Client Dupont'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/entreprise/devis/${1000 + i}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EntrepriseDevisDetailScreen extends ConsumerWidget {
  final String devisId;
  const EntrepriseDevisDetailScreen({super.key, required this.devisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Devis #$devisId',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KojiSectionTitle('Détails'),
              Text('Client: SARL Dupont'),
              Text('Montant: €5,200'),
              Text('Statut: En attente'),
            ],
          ),
        ),
      ],
    );
  }
}

// === CLIENTS ===

class EntrepriseClientsScreen extends ConsumerWidget {
  const EntrepriseClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Clients',
      appBarOnPhone: true,
      top: [
        Row(
          children: [
            Expanded(
              child: KojiButton(
                label: '+ Ajouter client',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
      main: [
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Client ${i + 1}'),
                subtitle: Text('contact@client$i.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/entreprise/clients/client-$i'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EntrepriseClientDetailScreen extends ConsumerWidget {
  final String clientId;
  const EntrepriseClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Client $clientId',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KojiSectionTitle('Informations'),
              Text('Nom: SARL $clientId'),
              Text('Email: contact@$clientId.com'),
              Text('Téléphone: +33 1 23 45 67 89'),
            ],
          ),
        ),
      ],
    );
  }
}

// === ÉQUIPE ===

class EntrepriseEquipeScreen extends ConsumerWidget {
  const EntrepriseEquipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Équipe',
      appBarOnPhone: true,
      top: [
        Row(
          children: [
            Expanded(
              child: KojiButton(
                label: '+ Ajouter membre',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
      main: [
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Membre ${i + 1}'),
                subtitle: Text('Rôle: Ouvrier'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/entreprise/equipe/member-$i'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EntrepriseEquipeMemberScreen extends ConsumerWidget {
  final String memberId;
  const EntrepriseEquipeMemberScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Membre $memberId',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KojiSectionTitle('Profil'),
              Text('Nom: Équipier $memberId'),
              Text('Rôle: Ouvrier'),
              Text('Email: member@koji.pro'),
            ],
          ),
        ),
      ],
    );
  }
}

// === FACTURATION ===

class EntrepriseFacturationScreen extends ConsumerWidget {
  const EntrepriseFacturationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Facturation',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Facture #${2000 + i}'),
                subtitle: Text('€${5000 + (i * 1000)}'),
                trailing: const Text('Payée'),
              );
            },
          ),
        ),
      ],
    );
  }
}
