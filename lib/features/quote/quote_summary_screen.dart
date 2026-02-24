
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/features/quote/model/expense_item.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';


class QuoteSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const QuoteSummaryScreen({super.key, this.data = const {}});

  @override
  ConsumerState<QuoteSummaryScreen> createState() => _QuoteSummaryScreenState();
}

class _QuoteSummaryScreenState extends ConsumerState<QuoteSummaryScreen> {
  // Local state for editing before saving
  late Map<String, List<ExpenseItem>> _localEstimations;
  String _selectedRoomId = '';
  
  @override
  void initState() {
    super.initState();
    // Initialize from provider
    final state = ref.read(quoteCreationProvider);
    _localEstimations = {};
    
    // Deep copy for editing
    state.roomEstimations.forEach((key, value) {
      if (value is List) {

        // value is List<ExpenseItem> (or dynamic list needing cast)
        _localEstimations[key] = value.map((e) {
             if (e is ExpenseItem) {
               return ExpenseItem(
                 id: e.id, title: e.title, subtitle: e.subtitle, icon: e.icon,
                 quantity: e.quantity, laborCost: e.laborCost, materialCost: e.materialCost, tax: e.tax
               );
             }
             return e as ExpenseItem; 
        }).toList();
      }
    });

    if (state.selectedRoomIds.isNotEmpty) {
      _selectedRoomId = state.selectedRoomIds.first;
    }
  }

  double _calculateRoomTotal(String roomId) {
    final items = _localEstimations[roomId] ?? [];
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  Map<String, double> _calculateRoomRatio(String roomId) {
    final items = _localEstimations[roomId] ?? [];
    if (items.isEmpty) {
      return {'labor': 0.0, 'material': 0.0};
    }

    double totalLabor = 0.0;
    double totalMaterial = 0.0;

    for (final item in items) {
      totalLabor += item.laborCost * item.quantity * (1 + item.tax / 100);
      totalMaterial += item.materialCost * item.quantity * (1 + item.tax / 100);
    }

    final total = totalLabor + totalMaterial;
    if (total == 0.0) {
      return {'labor': 0.0, 'material': 0.0};
    }

    return {
      'labor': (totalLabor / total) * 100,
      'material': (totalMaterial / total) * 100,
    };
  }

  void _updateItem(String roomId, int index, ExpenseItem newItem) {
    setState(() {
      _localEstimations[roomId]?[index] = newItem;
    });
  }

  void _removeItem(String roomId, int index) {
    setState(() {
      _localEstimations[roomId]?.removeAt(index);
    });
  }

  void _saveAndContinue() {
    // Save back to provider
    _localEstimations.forEach((roomId, items) {
      ref.read(quoteCreationProvider.notifier).updateRoomEstimation(roomId, items);
    });
    

    // Navigate
    context.push('/quote/detail', extra: ref.read(quoteCreationProvider).toMap());
  }

  void _navigateToRoom(String roomId) {
    // Save current room data before switching
    _localEstimations.forEach((roomId, items) {
      ref.read(quoteCreationProvider.notifier).updateRoomEstimation(roomId, items);
    });
    
    setState(() {
      _selectedRoomId = roomId;
    });
  }

  void _nextRoom() {
    final roomIds = ref.read(quoteCreationProvider).selectedRoomIds;
    final currentIndex = roomIds.indexOf(_selectedRoomId);
    if (currentIndex < roomIds.length - 1) {
      _navigateToRoom(roomIds[currentIndex + 1]);
    }
  }

  void _previousRoom() {
    final roomIds = ref.read(quoteCreationProvider).selectedRoomIds;
    final currentIndex = roomIds.indexOf(_selectedRoomId);
    if (currentIndex > 0) {
      _navigateToRoom(roomIds[currentIndex - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomIds = ref.read(quoteCreationProvider).selectedRoomIds;
    // Safety check if rooms changed or init issue
    if (roomIds.isEmpty) {
      return const Scaffold(body: Center(child: Text("Aucune pièce sélectionnée")));
    }
    if (_selectedRoomId.isEmpty && roomIds.isNotEmpty) {
      _selectedRoomId = roomIds.first;
    }

    final currentTotal = _calculateRoomTotal(_selectedRoomId);
    final currentItems = _localEstimations[_selectedRoomId] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            _buildHeader(context),
            
            // 2. Room Tabs
            _buildRoomTabs(roomIds),
            
            // 3. Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Total Card
                    _buildTotalCard(currentTotal),
                    const SizedBox(height: 24),
                    
                    // Room Title Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _getRoomLabel(_selectedRoomId),
                        style: AppTheme.headingStyle(context).copyWith(color: AppTheme.darkNavy, fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Définissez les postes de dépenses et les estimations pour cette pièce ou bien ajouter une poste personnalisée.",
                        style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tasks List
                    ...currentItems.asMap().entries.map((entry) {
                       return _buildEditableTaskCard(_selectedRoomId, entry.key, entry.value);
                    }),
                    
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.darkNavy, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Détails de la Pièce(s)',
                  style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Etape 5/6',
                  style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
             icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.darkNavy, size: 20),
             onPressed: () {}, // Next room?
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTabs(List<String> roomIds) {
    return Container(
      color: AppTheme.darkNavy,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: roomIds.map((id) {
            final isSelected = id == _selectedRoomId;
            return GestureDetector(
              onTap: () => setState(() => _selectedRoomId = id),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1D74FF) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(_getRoomIcon(id), size: 18, color: isSelected ? Colors.white : AppTheme.darkNavy),
                    const SizedBox(width: 8),
                    Text(
                      _getRoomLabel(id),
                      style: TextStyle(
                        fontFamily: 'Outfit', 
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.darkNavy,
                      ),
                    ),
                    if (isSelected && (_localEstimations[id]?.isNotEmpty ?? false)) ...[
                       const SizedBox(width: 6),
                       Container(
                         padding: const EdgeInsets.all(5),
                         decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                         child: Text(
                           '${_localEstimations[id]?.length}',
                           style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D74FF)),
                         ),
                       )
                    ]
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    final ratio = _calculateRoomRatio(_selectedRoomId);
    final laborPercentage = ratio['labor']!.toStringAsFixed(0);
    final materialPercentage = ratio['material']!.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2648), // Dark Navy
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: const Color(0xFF0F2648).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total estimé de la pièce',
            style: TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.toStringAsFixed(2)} €',
            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Real MO/Mat ratio visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(const Color(0xFF1D74FF), "MO: $laborPercentage%"),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.white, "Mat: $materialPercentage%"),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 11)),
      ],
    );
  }
  
  Widget _buildEditableTaskCard(String roomId, int index, ExpenseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
         children: [
           // Header
           Padding(
             padding: const EdgeInsets.all(16),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(
                     color: const Color(0xFF93C5FD).withOpacity(0.3),
                     borderRadius: BorderRadius.circular(10),
                   ),
                   child: Icon(item.icon, color: const Color(0xFF1E3A8A), size: 20),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(item.title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                       Text(item.subtitle, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF64748B))),
                     ],
                   ),
                 ),
                 IconButton(
                   icon: Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                       border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.3)),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF6B7280))
                   ),
                   onPressed: () => _removeItem(roomId, index),
                 )
               ],
             ),
           ),
           Container(height: 1, color: Colors.white),
           
           // Inputs Grid
           Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 // Row 1: Quantity & Unit
                 Row(
                   children: [
                     Expanded(
                       child: _buildInput(
                         label: 'Quantité',
                         value: item.quantity.toStringAsFixed(0),
                         onChanged: (val) {
                           final v = double.tryParse(val) ?? 0;
                           _updateItem(roomId, index, ExpenseItem(
                              id: item.id, title: item.title, subtitle: item.subtitle, icon: item.icon,
                              quantity: v, laborCost: item.laborCost, materialCost: item.materialCost, tax: item.tax
                           ));
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: _buildInput(
                         label: 'Unité',
                         value: 'm² (Surface)', // Mock unit selector
                         isReadOnly: true,
                         hasDropdown: true,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 
                 // Row 2: M.O & Mat
                 Row(
                   children: [
                     Expanded(
                       child: _buildInput(
                         label: 'M.O. / Hour',
                         value: item.laborCost.toStringAsFixed(2),
                         onChanged: (val) {
                           final v = double.tryParse(val) ?? 0;
                           _updateItem(roomId, index, ExpenseItem(
                              id: item.id, title: item.title, subtitle: item.subtitle, icon: item.icon,
                              quantity: item.quantity, laborCost: v, materialCost: item.materialCost, tax: item.tax
                           ));
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: _buildInput(
                         label: 'Mat. / Unité (€)',
                         value: item.materialCost.toStringAsFixed(2),
                         suffix: '€',
                         onChanged: (val) {
                           final v = double.tryParse(val) ?? 0;
                           _updateItem(roomId, index, ExpenseItem(
                              id: item.id, title: item.title, subtitle: item.subtitle, icon: item.icon,
                              quantity: item.quantity, laborCost: item.laborCost, materialCost: v, tax: item.tax
                           ));
                         },
                       ),
                     ),
                   ],
                 ),
                 
                 // Row 3: Tax & Total button?
                 // Design shows Tax input at bottom, then huge Plus button at very bottom right
               ],
             ),
           ),
           
           // Tax Row
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: const BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  const Text('Taxe sur la valeur ajoutée (TVA)', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                     child: Text('${item.tax.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  )
               ],
             ),
           )
         ],
      ),
    );
  }

  Widget _buildInput({required String label, String? value, bool isReadOnly = false, bool hasDropdown = false, String? suffix, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Very light grey
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: isReadOnly 
                ? Align(alignment: Alignment.centerLeft, child: Text(value ?? '', style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)))
                : TextField(
                    controller: TextEditingController.fromValue(TextEditingValue(text: value ?? '', selection: TextSelection.collapsed(offset: (value ?? '').length))),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                    onChanged: onChanged,
                  ),
              ),
              if (suffix != null) Text(suffix, style: const TextStyle(color: Color(0xFF94A3B8))),
              if (hasDropdown) const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B))
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          // Room Navigation
          if (ref.read(quoteCreationProvider).selectedRoomIds.length > 1) ...[
            Row(
              children: [
                IconButton(
                  onPressed: _previousRoom,
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${ref.read(quoteCreationProvider).selectedRoomIds.indexOf(_selectedRoomId) + 1} / ${ref.read(quoteCreationProvider).selectedRoomIds.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _nextRoom,
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: AppTheme.darkNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/rooms'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkNavy,
                    side: const BorderSide(color: AppTheme.darkNavy),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Créer un projet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Valider le Devis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // -- Icons Helpers
   String _getRoomLabel(String id) {
    if (id.toLowerCase().contains('salon')) return 'Salon';
    if (id.toLowerCase().contains('cuisine')) return 'Cuisine';
    if (id.toLowerCase().contains('chambre')) return 'Chambre';
    if (id.toLowerCase().contains('bain')) return 'Salle de bain';
    if (id.toLowerCase().contains('wc')) return 'WC';
    if (id.toLowerCase().contains('entree')) return 'Entrée';
    return id.substring(0, 1).toUpperCase() + id.substring(1);
  }
  
   IconData _getRoomIcon(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('salon')) return Icons.weekend;
    if (lower.contains('cuisine')) return Icons.soup_kitchen;
    if (lower.contains('chambre')) return Icons.bed;
    if (lower.contains('bain')) return Icons.bathtub;
    if (lower.contains('wc')) return Icons.wc;
    if (lower.contains('entree')) return Icons.door_front_door;
    return Icons.widgets;
  }
}
