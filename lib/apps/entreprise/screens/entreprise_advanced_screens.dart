import 'package:flutter/material.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_widgets.dart';

// === PLANNING ===
class EntreprisePlanningScreen extends StatelessWidget {
  const EntreprisePlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Planning',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Intervention ${i + 1}'),
                subtitle: Text('2026-11-${15 + i}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// === ARCHIVES ===
class EntrepriseArchivesScreen extends StatelessWidget {
  const EntrepriseArchivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Archives',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Projet archivé ${i + 1}'),
                subtitle: const Text('Complété'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// === MARKETPLACE (Entreprise Browse) ===
class EntrepriseMarketplaceScreen extends StatelessWidget {
  const EntrepriseMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Opportunités',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Chantier #${1000 + i}'),
                subtitle: Text('Budget: €${5000 + (i * 2000)}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// === FOURNITURES (Supplies) ===
class EntrepriseFournituresScreen extends StatelessWidget {
  const EntrepriseFournituresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Fournitures',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text('Fourniture ${i + 1}'),
                subtitle: Text('Stock: ${100 - (i * 10)} unités'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// === COMPTABILITÉ (Accounting) ===
class EntrepriseComptabiliteScreen extends StatelessWidget {
  const EntrepriseComptabiliteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Comptabilité',
      appBarOnPhone: true,
      main: [
        KojiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Résumé financier',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Revenus'),
                trailing: const Text('€250,000',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              ListTile(
                title: const Text('Dépenses'),
                trailing: const Text('€80,000',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              ListTile(
                title: const Text('Bénéfice'),
                trailing: const Text('€170,000',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.green,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
