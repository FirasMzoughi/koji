import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:koji/design/koji_icons.dart';
import 'package:koji/design/koji_page.dart';
import 'package:koji/design/koji_tokens.dart';
import 'package:koji/design/koji_widgets.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

/// Schedule a RDV (visite/appointment) for a marketplace offer.
/// Web equiv: /api/marketplace/offres/[id]/visite
class MarketplaceOfferRdvScreen extends ConsumerStatefulWidget {
  final String offerId;
  const MarketplaceOfferRdvScreen({super.key, required this.offerId});

  @override
  ConsumerState<MarketplaceOfferRdvScreen> createState() =>
      _MarketplaceOfferRdvScreenState();
}

class _MarketplaceOfferRdvScreenState
    extends ConsumerState<MarketplaceOfferRdvScreen> {
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedHour = 10;
  int _selectedMinute = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _requestRdv() async {
    if (_selectedDate.isBefore(DateTime.now())) {
      setState(() => _error = 'Veuillez sélectionner une date future');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(marketplaceRepositoryProvider).requestRdv(
            offerId: widget.offerId,
            proposedDateTime: _selectedDate.copyWith(
              hour: _selectedHour,
              minute: _selectedMinute,
            ),
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de RDV envoyée')),
      );
      context.pop();
    } catch (err) {
      if (!mounted) return;
      setState(() =>
          _error = 'Erreur lors de la demande. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KojiPage(
      title: 'Demander une visite',
      main: [SingleChildScrollView(
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
                  style: const TextStyle(color: Color(0xffc62828), fontSize: 14),
                ),
              ),

            // Date picker
            Text('Date proposée', style: context.koji.typography.labelLarge),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffe0e6ed)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time picker
            Text('Heure proposée', style: context.koji.typography.labelLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heure',
                          style: context.koji.typography.bodySmall?.copyWith(
                              color: const Color(0xff718096))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffe0e6ed)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedHour,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (h) =>
                              setState(() => _selectedHour = h ?? 10),
                          items: List.generate(24, (i) => i)
                              .map((h) => DropdownMenuItem(
                                    value: h,
                                    child: Text('${h.toString().padLeft(2, '0')}:00'),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Minutes',
                          style: context.koji.typography.bodySmall?.copyWith(
                              color: const Color(0xff718096))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffe0e6ed)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedMinute,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (m) =>
                              setState(() => _selectedMinute = m ?? 0),
                          items: [0, 15, 30, 45]
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Note
            Text('Message (optionnel)',
                style: context.koji.typography.labelLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Après 18h, accès par la cour...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: KojiButton(
                label: 'Demander la visite',
                onPressed: _saving ? null : _requestRdv,
                loading: _saving,
              ),
            ),
          ],
        ),
      )],
    );
  }
}
