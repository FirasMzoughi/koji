import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koji/providers/company_provider.dart';

class DomainSelectionScreen extends ConsumerStatefulWidget {
  const DomainSelectionScreen({super.key});

  @override
  ConsumerState<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends ConsumerState<DomainSelectionScreen> {
  final List<String> _domains = [
    'Peintre',
    'Électricien',
    'Carreleur',
    'Menuisier',
    'Plombier',
    'Tout corps d\'état',
  ];

  final Set<String> _selectedDomains = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Veuillez choisir votre profession',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un ou plusieurs domaines.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _domains.length,
                  itemBuilder: (context, index) {
                    final domain = _domains[index];
                    final isSelected = _selectedDomains.contains(domain);
                    return _DomainCard(
                      label: domain,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDomains.remove(domain);
                          } else {
                            _selectedDomains.add(domain);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedDomains.isEmpty
                    ? null
                    : () {
                        ref.read(companyProfileProvider.notifier).setDomains(_selectedDomains.toList());
                        context.push('/room-selection');
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DomainCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIconForDomain(String domain) {
    switch (domain) {
      case 'Peintre':
        return Icons.format_paint;
      case 'Électricien':
        return Icons.electric_bolt;
      case 'Carreleur':
        return Icons.grid_view;
      case 'Menuisier':
        return Icons.carpenter;
      case 'Plombier':
        return Icons.water_drop;
      case 'Tout corps d\'état':
        return Icons.construction;
      default:
        return Icons.domain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForDomain(label),
              size: 32,
              color: isSelected ? Colors.white : const Color(0xFF1A237E),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
