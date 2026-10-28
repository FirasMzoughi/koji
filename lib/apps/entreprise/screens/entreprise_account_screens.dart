import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';

// === PROFIL ===

class EntrepriseProfilScreen extends ConsumerStatefulWidget {
  const EntrepriseProfilScreen({super.key});

  @override
  ConsumerState<EntrepriseProfilScreen> createState() =>
      _EntrepriseProfilScreenState();
}

class _EntrepriseProfilScreenState
    extends ConsumerState<EntrepriseProfilScreen> {
  final _raisonSocialeController = TextEditingController();
  final _siretController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _raisonSocialeController.text = 'SARL Mon Entreprise';
    _siretController.text = '12345678901234';
    _phoneController.text = '+33 1 23 45 67 89';
    _addressController.text = '123 Rue de la Paix, 75001 Paris';
  }

  @override
  void dispose() {
    _raisonSocialeController.dispose();
    _siretController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfil() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _success = 'Profil sauvegardé');
    } catch (err) {
      setState(() => _error = 'Erreur lors de la sauvegarde');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Profil entreprise',
      appBarOnPhone: true,
      main: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffffe0e0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xffc62828)),
                  ),
                ),
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffe8f5e9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _success!,
                    style: const TextStyle(color: Color(0xff2e7d32)),
                  ),
                ),
              _buildField('Raison sociale', _raisonSocialeController),
              const SizedBox(height: 16),
              _buildField('SIRET', _siretController),
              const SizedBox(height: 16),
              _buildField('Téléphone', _phoneController),
              const SizedBox(height: 16),
              _buildField('Adresse', _addressController, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: KojiButton(
                  label: 'Enregistrer',
                  onPressed: _saving ? null : _saveProfil,
                  loading: _saving,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// === PARAMÈTRES ===

class EntrepriseParametresScreen extends ConsumerWidget {
  const EntrepriseParametresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KojiPage(
      title: 'Paramètres',
      appBarOnPhone: true,
      main: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thème', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffe0e6ed)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile(
                      title: const Text('Clair'),
                      value: 'light',
                      groupValue: 'light',
                      onChanged: (_) {},
                    ),
                    RadioListTile(
                      title: const Text('Sombre'),
                      value: 'dark',
                      groupValue: 'light',
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Notifications',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Nouveaux devis'),
                value: true,
                onChanged: (_) {},
              ),
              CheckboxListTile(
                title: const Text('Nouveaux messages'),
                value: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: 32),
              Text('Compte',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Abonnement'),
                subtitle: const Text('Koji Pro - Annuel'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Déconnexion'),
                trailing: const Icon(KojiIcons.deconnexion),
                onTap: () {},
              ),
              const SizedBox(height: 32),
              Text('Zone dangereuse',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xffc62828),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffffe0e0),
                    foregroundColor: const Color(0xffc62828),
                  ),
                  onPressed: () {},
                  child: const Text('Supprimer le compte'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
