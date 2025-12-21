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
      backgroundColor: const Color(0xFFF8F9FE), // Matching theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A237E)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quelle est votre profession ?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un ou plusieurs domaines pour personnaliser votre expérience.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDomains.isEmpty
                      ? null
                      : () {
                          ref.read(companyProfileProvider.notifier).setDomains(_selectedDomains.toList());
                          // Aller vers company_info, qui ira ensuite vers room_selection
                          context.go('/pro/company-info');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _selectedDomains.isEmpty ? 0 : 8,
                    shadowColor: const Color(0xFF1A237E).withOpacity(0.4),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Continuer'),
                ),
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF1A237E).withOpacity(0.4)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected 
              ? null
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFF8F9FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForDomain(label),
                color: isSelected ? Colors.white : const Color(0xFF1A237E),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A237E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDomain(String domain) {
    switch (domain) {
      case 'Peintre':
        return Icons.format_paint_outlined;
      case 'Électricien':
        return Icons.electric_bolt_outlined;
      case 'Carreleur':
        return Icons.grid_view_outlined;
      case 'Menuisier':
        return Icons.handyman_outlined;
      case 'Plombier':
        return Icons.water_drop_outlined;
      case 'Tout corps d\'état':
        return Icons.business_center_outlined;
      default:
        return Icons.work_outline;
    }
  }
}
