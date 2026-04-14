import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:koji/features/quote/model/expense_item.dart';

class RoomEstimationScreen extends ConsumerStatefulWidget {
  final List<String> selectedRoomIds;
  final List<String> images;

  const RoomEstimationScreen({
    super.key,
    this.selectedRoomIds = const [],
    this.images = const [],
  });

  @override
  ConsumerState<RoomEstimationScreen> createState() => _RoomEstimationScreenState();
}

class _RoomEstimationScreenState extends ConsumerState<RoomEstimationScreen> {
  int _selectedTabIndex = 0;
  late List<String> _tabs;
  
  // State storage: RoomID -> List<ExpenseItem>
  final Map<String, List<ExpenseItem>> _expensesByRoom = {};
  
  final TextEditingController _customPostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedRoomIds.isNotEmpty) {
      _tabs = widget.selectedRoomIds.map((id) => _getRoomLabel(id)).toList();
    } else {
      _tabs = ['Salon', 'Cuisine', 'Chambre'];
    }
    
    // Initialize empty expense lists - will be populated from selected tasks
    for (var room in _tabs) {
       _expensesByRoom[room] = [];
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read selected tasks from provider and generate expense items
    _initializeExpensesFromTasks();
  }
  
  void _initializeExpensesFromTasks() {
    final quoteState = ref.read(quoteCreationProvider);
    
    // Always reinitialize to get fresh data
    // This ensures we pick up tasks selected in the previous screen
    
    for (var i = 0; i < widget.selectedRoomIds.length; i++) {
      final roomId = widget.selectedRoomIds[i];
      final roomLabel = _getRoomLabel(roomId);
      final roomTaskData = quoteState.roomTasks[roomId];
      
      debugPrint('Room: $roomId, TaskData: $roomTaskData');
      
      // NEW: Check if we have calculated estimations from RoomTaskScreen
      final existingEstimations = quoteState.roomEstimations[roomId];
      if (existingEstimations != null && existingEstimations is List && existingEstimations.isNotEmpty) {
        debugPrint('Found existing estimations for $roomId');
        setState(() {
          _expensesByRoom[roomLabel] = existingEstimations.map((e) {
             if (e is ExpenseItem) return e;
             // Handle potential map serialization if persistence added later
             return e as ExpenseItem;
          }).toList().cast<ExpenseItem>();
        });
        continue;
      }
      
      if (roomTaskData == null) {
        // No tasks selected for this room, initialize with empty list
        if (!_expensesByRoom.containsKey(roomLabel) || _expensesByRoom[roomLabel]!.isEmpty) {
          setState(() {
            _expensesByRoom[roomLabel] = [];
          });
        }
        continue;
      }
      
      final selectedTasks = (roomTaskData['tasks'] as List<dynamic>?)?.cast<String>() ?? [];
      
      debugPrint('Selected tasks for $roomId: $selectedTasks');
      
      // Generate expense items - ONE ITEM PER TASK (no grouping/deduplication)
      final expenseList = <ExpenseItem>[];
      
      for (var taskId in selectedTasks) {
        final expenseItem = _createExpenseItemFromTask(taskId);
        if (expenseItem != null) {
          // Add every task as a separate expense item
          expenseList.add(expenseItem);
          debugPrint('Added expense item: ${expenseItem.id} for task: $taskId');
        } else {
          debugPrint('No expense item created for task: $taskId');
        }
      }
      
      setState(() {
        _expensesByRoom[roomLabel] = expenseList;
      });
      
      debugPrint('Final expenses for $roomLabel: ${_expensesByRoom[roomLabel]?.length} items');
    }
  }
  
  ExpenseItem? _createExpenseItemFromTask(String taskId) {
    // Map task IDs to expense items - ALL START AT 0.0
    switch (taskId) {
      // PEINTRE (Painter) tasks
      case 'prep_murs_plafonds':
      case 'poncage':
      case 'depoussierage':
      case 'sous_couche':
      case 'peinture_couche_1':
      case 'peinture_couche_2':
      case 'finition_supp':
        return ExpenseItem(
          id: 'murs',
          title: "Murs intérieurs",
          subtitle: "Peinture, enduit...",
          icon: Icons.format_paint_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'boiseries':
        return ExpenseItem(
          id: 'boiseries',
          title: "Boiseries (portes)",
          subtitle: "Peinture, Vernis...",
          icon: Icons.door_front_door_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'protection_sols':
        return ExpenseItem(
          id: 'sols',
          title: "Sols",
          subtitle: "Protection, Carrelage...",
          icon: Icons.grid_view,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'depose_elements':
      case 'finitions_nettes':
      case 'nettoyage':
      case 'evacuation':
      case 'reprises':
        return ExpenseItem(
          id: 'finitions',
          title: "Finitions et nettoyage",
          subtitle: "Retouches, nettoyage...",
          icon: Icons.cleaning_services_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      // ÉLECTRICIEN (Electrician) tasks
      case 'diag_elec':
      case 'protection_elec':
      case 'test_elec':
      case 'nettoyage_elec':
        return ExpenseItem(
          id: 'elec_services',
          title: "Services électriques",
          subtitle: "Diagnostic, tests...",
          icon: Icons.electrical_services_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'tableau_elec':
      case 'prises_elec':
      case 'luminaires':
      case 'cable_elec':
      case 'terre_elec':
      case 'differentiel':
        return ExpenseItem(
          id: 'elec_installation',
          title: "Installation électrique",
          subtitle: "Tableau, prises, câblage...",
          icon: Icons.power_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      // PLOMBIER (Plumber) tasks
      case 'diag_plomb':
      case 'protection_plomb':
      case 'test_etancheite':
      case 'nettoyage_plomb':
        return ExpenseItem(
          id: 'plomb_services',
          title: "Services plomberie",
          subtitle: "Diagnostic, tests...",
          icon: Icons.plumbing_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'wc_install':
      case 'lavabo_install':
      case 'douche_install':
      case 'robinet_install':
      case 'eau_froide':
      case 'eau_chaude':
      case 'evacuation_plomb':
        return ExpenseItem(
          id: 'plomb_installation',
          title: "Installation sanitaire",
          subtitle: "WC, lavabo, raccordements...",
          icon: Icons.water_drop_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      // CARRELEUR (Tiler) tasks
      case 'prep_sol':
      case 'ragreage':
      case 'primaire':
        return ExpenseItem(
          id: 'carrelage_prep',
          title: "Préparation supports",
          subtitle: "Ragréage, primaire...",
          icon: Icons.foundation_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'trace_carrelage':
      case 'pose_carreaux':
      case 'decoupe':
      case 'joints_carrelage':
      case 'silicone':
      case 'nettoyage_carrelage':
        return ExpenseItem(
          id: 'carrelage_pose',
          title: "Pose carrelage",
          subtitle: "Pose, joints, finitions...",
          icon: Icons.grid_on_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      // MENUISIER (Carpenter) tasks
      case 'mesures':
      case 'devis_menuiserie':
        return ExpenseItem(
          id: 'menuiserie_prep',
          title: "Préparation menuiserie",
          subtitle: "Mesures, devis...",
          icon: Icons.straighten_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      case 'porte_install':
      case 'fenetre_install':
      case 'placard_install':
      case 'parquet_install':
      case 'ajust_menuiserie':
      case 'quincaillerie':
      case 'vernis_menuiserie':
      case 'nettoyage_menuiserie':
        return ExpenseItem(
          id: 'menuiserie_install',
          title: "Installation menuiserie",
          subtitle: "Portes, fenêtres, placards...",
          icon: Icons.carpenter_outlined,
          quantity: 0,
          laborCost: 0.0,
          materialCost: 0.0,
        );
      
      default:
        // For custom tasks
        if (taskId.startsWith('custom_')) {
          return ExpenseItem(
            id: taskId,
            title: "Tâche personnalisée",
            subtitle: "Poste personnalisé",
            icon: Icons.edit,
            quantity: 0,
            laborCost: 0.0,
            materialCost: 0.0,
          );
        }
        return null;
    }
  }

  String _getRoomLabel(String id) {
    switch (id) {
      case 'salon': return 'Salon';
      case 'cuisine': return 'Cuisine';
      case 'chambre': return 'Chambre';
      case 'salle_de_bain': return 'Salle de bain';
      case 'bureau': return 'Bureau';
      case 'exterieur': return 'Extérieur';
      default: return id;
    }
  }
  
  void _addCustomPost() {
    final text = _customPostController.text.trim();
    if (text.isEmpty) return;
    
    final currentRoom = _tabs[_selectedTabIndex];
    setState(() {
      _expensesByRoom[currentRoom]?.add(ExpenseItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: text,
        subtitle: 'Poste personnalisé',
        icon: Icons.edit,
      ));
      _customPostController.clear();
    });
  }

  double _calculateTotal(String room) {
    if (_expensesByRoom[room] == null) return 0.0;
    return _expensesByRoom[room]!.fold(0.0, (sum, item) => sum + (item.quantity * (item.laborCost + item.materialCost)));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    if (_tabs.isEmpty) _tabs = ['Pièce'];
    final currentRoom = _tabs[_selectedTabIndex];
    final roomTotal = _calculateTotal(currentRoom);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkNavy, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Détails de la Pièce(s)',
              style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
            ),
             Text(
              'Etape 3/5',
              style: TextStyle( 
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
         child: Column(
           children: [
             // Tabs (Room Selector)
             Container(
               height: 60,
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: ListView.separated(
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 scrollDirection: Axis.horizontal,
                 itemCount: _tabs.length,
                 separatorBuilder: (context, index) => const SizedBox(width: 12),
                 itemBuilder: (context, index) {
                   final isSelected = index == _selectedTabIndex;
                   return GestureDetector(
                     onTap: () => setState(() => _selectedTabIndex = index),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? AppTheme.darkNavy : Colors.white,
                         borderRadius: BorderRadius.circular(30),
                         border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                       ),
                       alignment: Alignment.center,
                       child: Row(
                         children: [
                           Icon(
                             _getIconForLabel(_tabs[index]),
                             size: 18,
                             color: isSelected ? Colors.white : AppTheme.darkNavy,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             _tabs[index],
                             style: TextStyle( 
                               color: isSelected ? Colors.white : AppTheme.darkNavy,
                               fontWeight: FontWeight.w600,
                               fontSize: 14,
                             ),
                           ),
                           const SizedBox(width: 8),
                           Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${_expensesByRoom[_tabs[index]]?.length ?? 0}",
                                style: TextStyle( 
                                  fontSize: 10,
                                  color: isSelected ? Colors.white : AppTheme.textLight,
                                ),
                              ),
                           )
                         ],
                       ),
                     ),
                   );
                 },
               ),
             ),
             
             Expanded(
               child: SingleChildScrollView(
                 padding: EdgeInsets.all(responsive.width(6.4)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     // Estimate Card
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: AppTheme.darkNavy,
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(
                             color: AppTheme.darkNavy.withOpacity(0.3),
                             blurRadius: 20,
                             offset: const Offset(0, 10),
                           ),
                         ],
                       ),
                       child: Column(
                         children: [
                           Text(
                             'Total estimé de la pièce',
                             style: TextStyle( 
                               color: Colors.white.withOpacity(0.7),
                               fontSize: 14,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             '${roomTotal.toStringAsFixed(2)} €',
                             style: TextStyle( 
                               color: Colors.white,
                               fontSize: 32,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           const SizedBox(height: 16),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               _buildLegendItem(label: "MO: 60%", color: const Color(0xFF3B82F6)), // Light Blue
                               const SizedBox(width: 24),
                               _buildLegendItem(label: "Mat: 40%", color: const Color(0xFF9CA3AF)), // Grey
                             ],
                           ),
                         ],
                       ),
                     ),
                     
                     const SizedBox(height: 24),
                     
                     // Room Title (Dynamic)
                     Text(
                        currentRoom,
                        style: AppTheme.headingStyle(context).copyWith(fontSize: 20),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       'Définissez les postes de dépenses et les estimations pour cette pièce ou bien ajoutez un poste personnalisé.',
                       style: TextStyle( 
                         color: AppTheme.textLight,
                         fontSize: 13,
                         height: 1.4,
                       ),
                     ),
                     
                     const SizedBox(height: 24),
                     
                     // Expense Items List
                     if (_expensesByRoom[currentRoom] != null)
                      ..._expensesByRoom[currentRoom]!.map((item) => Column(
                        children: [
                          _buildInteractiveExpenseCard(item),
                          const SizedBox(height: 16),
                        ],
                      )),
                     
                     // Add Custom Post Input
                     Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.02),
                               blurRadius: 10,
                               offset: const Offset(0, 4),
                             ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ajouter un poste personnalisé",
                              style: TextStyle( 
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customPostController,
                                    decoration: InputDecoration(
                                      hintText: 'Nom du poste...',
                                      hintStyle: TextStyle( 
                                        color: const Color(0xFF9CA3AF),
                                        fontSize: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkNavy,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: _addCustomPost,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                     ),

                     const SizedBox(height: 80), // Space for bottom button
                   ],
                 ),
               ),
             ),
           ],
         ),
      ),
      
      // Bottom Floating Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
             // Save estimates to provider
             for (var entry in _expensesByRoom.entries) {
               ref.read(quoteCreationProvider.notifier).updateRoomEstimation(entry.key, entry.value);
             }
             
             context.push('/quote/summary');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Valider les pièces',
                style: TextStyle( 
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForLabel(String label) {
    if (label.contains('Salon')) return Icons.weekend;
    if (label.contains('Cuisine')) return Icons.soup_kitchen;
    if (label.contains('Chambre')) return Icons.bed;
    if (label.contains('Bain')) return Icons.bathtub;
    if (label.contains('Bureau')) return Icons.computer;
    if (label.contains('Ext')) return Icons.deck;
    return Icons.widgets;
  }

  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle( 
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveExpenseCard(ExpenseItem item) {
    // Current total for this item
    double total = item.quantity * (item.laborCost + item.materialCost);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: AppTheme.darkNavy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle( 
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle( 
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Row 1: Qty & Unit
          Row(
            children: [
              Expanded(
                child: _buildNumberInput("Quantité", item.quantity.toString(), (val) {
                  setState(() => item.quantity = double.tryParse(val) ?? 0);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownColumn("Unité", "m² (Surface)"),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 2: MO & Mat
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  "M.O. / Hour", 
                  item.laborCost.toString(), 
                  (val) => setState(() => item.laborCost = double.tryParse(val) ?? 0),
                  readOnly: item.subtitle.contains('Calculé') || item.subtitle.contains('Auto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberInput(
                  "Mat. / Unité (€)", 
                  item.materialCost.toString(), 
                  (val) => setState(() => item.materialCost = double.tryParse(val) ?? 0),
                  suffix: "€",
                  readOnly: item.subtitle.contains('Calculé') || item.subtitle.contains('Auto'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Row 3: Taxes
           // _buildInputColumn("Taxe sur la valeur ajoutée (TVA)", "11.00", suffix: "€"), // Placeholder

          const SizedBox(height: 20),
          
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Calculé ${item.subtitle.contains('Calculé') ? ' (Auto)' : ''}",
                style: TextStyle( 
                  color: AppTheme.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${total.toStringAsFixed(2)} €",
                style: TextStyle( 
                  color: AppTheme.darkNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(String label, String value, Function(String) onChanged, {String? suffix, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle( 
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            if (readOnly)
               const Icon(Icons.lock, size: 12, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFE5E7EB) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                  readOnly: readOnly,
                  enabled: !readOnly, // Visually disable
                  style: TextStyle( 
                    fontWeight: FontWeight.w600,
                    color: readOnly ? AppTheme.textLight : AppTheme.darkNavy,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    suffix,
                    style: TextStyle( color: AppTheme.textLight, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

   Widget _buildDropdownColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle( 
            fontSize: 12,
            fontWeight: FontWeight.bold,
             color: AppTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle( 
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkNavy,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.darkNavy),
            ],
          ),
        ),
      ],
    );
  }
}
