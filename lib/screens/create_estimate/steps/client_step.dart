import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/providers/estimate_provider.dart';

class ClientInfoStep extends ConsumerStatefulWidget {
  const ClientInfoStep({super.key});

  @override
  ConsumerState<ClientInfoStep> createState() => _ClientInfoStepState();
}

class _ClientInfoStepState extends ConsumerState<ClientInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final provider = ref.read(estimateProvider);
    _nameController = TextEditingController(text: provider.tempClient?.name ?? '');
    _addressController = TextEditingController(text: provider.tempClient?.address ?? '');
    _phoneController = TextEditingController(text: provider.tempClient?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateProvider() {
    ref.read(estimateProvider).updateClientInfo(
      _nameController.text,
      _addressController.text,
      _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du client',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: (_) => _updateProvider(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Adresse du chantier',
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: (_) => _updateProvider(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
          ),
          onChanged: (_) => _updateProvider(),
        ),
      ],
    );
  }
}
