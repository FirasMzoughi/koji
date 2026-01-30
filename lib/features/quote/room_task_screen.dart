import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/profession_tasks_data.dart'; // Still using for categories structure
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:koji/features/quote/product_details_screen.dart';
import 'package:koji/features/quote/product_selection_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/features/auth/repository/user_repository.dart';

import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:koji/features/quote/model/expense_item.dart';

class RoomTaskScreen extends ConsumerStatefulWidget {
  final List<String> selectedRoomIds;
  final List<String> images;

  const RoomTaskScreen({
    super.key,
    this.selectedRoomIds = const [],
    this.images = const [],
  });

  @override
  ConsumerState<RoomTaskScreen> createState() => _RoomTaskScreenState();
}

class _RoomTaskScreenState extends ConsumerState<RoomTaskScreen> {
  // --- UI State ---
  int _selectedRoomTab = 0;
  late List<String> _roomIds;
  
  // Trade Tabs
  List<String> _trades = [];
  String _selectedTrade = '';
  bool _isLoadingProfessions = true;
  
  final TextEditingController _searchController = TextEditingController();
  
  // Logic State
  final Map<String, RoomTaskState> _taskStates = {};

  @override
  void initState() {
    super.initState();
    _roomIds = widget.selectedRoomIds.isNotEmpty 
        ? widget.selectedRoomIds 
        : ['salon', 'cuisine', 'chambre'];
        
    _loadUserProfessions();
  }
  
  Future<void> _loadUserProfessions() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        final userData = await ref.read(userRepositoryProvider).getUser(user.id);
        
        // Handle 'profession' which might be List<dynamic> (from recent change) or String (legacy)
        List<String> userTrades = [];
        final rawProf = userData?['profession'];
        
        if (rawProf is List) {
          userTrades = rawProf.map((e) => e.toString()).toList();
        } else if (rawProf is String) {
           userTrades = [rawProf];
        }
        
        if (userTrades.isEmpty) {
           userTrades = ['Peintre']; // Default fallback
        }
        
        if (mounted) {
          setState(() {
            _trades = userTrades;
            _selectedTrade = userTrades.first;
            _isLoadingProfessions = false;
          });
        }
      } else {
         // Not logged in?
         if (mounted) setState(() { _trades = ['Peintre']; _selectedTrade = 'Peintre'; _isLoadingProfessions = false; });
      }
    } catch (e) {
      debugPrint('Error loading professions: $e');
      if (mounted) setState(() { _trades = ['Peintre']; _selectedTrade = 'Peintre'; _isLoadingProfessions = false; });
    }
  }

  String _getRoomLabel(String id) {
    if(id == 'salle_de_bain') return 'Sdb';
    return id[0].toUpperCase() + id.substring(1);
  }
  
  IconData _getRoomIcon(String id) {
     if (id.contains('salon')) return Icons.weekend_outlined;
     if (id.contains('cuisine')) return Icons.soup_kitchen_outlined;
     if (id.contains('chambre')) return Icons.bed_outlined;
     if (id.contains('bain')) return Icons.bathtub_outlined;
     return Icons.room_preferences_outlined;
  }

  // --- Logic Helpers ---

  String _getKey(String roomId, String taskId) => '${roomId}_$taskId';

  void _toggleTaskSelection(String roomId, String taskId, String label, bool value) {
    final key = _getKey(roomId, taskId);
    
    setState(() {
      if (!value) {
        // Deselecting: just checking false in UI often implies we stop tracking or remove? 
        // For now, we'll keep logic in memory but visually it is unchecked.
        // Actually, the requirement says "expandable task-details card... when enabled".
        // So we just toggle expansion off or maybe remove from list?
        // Let's assume unchecked = removed from quote.
        if (_taskStates.containsKey(key)) {
          // We can remove it or mark it inactive. Let's remove for cleaner state.
          _taskStates.remove(key);
        }
      } else {
        // Selecting
        if (!_taskStates.containsKey(key)) {
           // Initialize state
           final newState = RoomTaskState(taskId: taskId, label: label, isExpanded: true);
           // initialize inputs
           for(var field in getFieldsForTask(taskId)) {
             if(field.defaultValue != null) {
               newState.inputs[field.id] = field.defaultValue;
             }
           }
           // Do NOT initialize default products anymore
           _taskStates[key] = newState;
        } else {
          // Just expand
          _taskStates[key]!.isExpanded = true;
        }
      }
    });
  }

  double _calculateQuantity(Product product, Map<String, dynamic> inputs) {
    double qty = 0;
    final rule = product.consumptionRule;
    if (rule.type == ConsumptionRuleType.fixed) return 1.0;
    
    if (rule.type == ConsumptionRuleType.perM2) {
      final surface = inputs['surface'] as double? ?? 0.0;
      // factor e.g. 0.1L/m2. Qty = surface * factor.
      // Or if factor is coverage area per unit input (e.g. 10m2 per Liter), then surface / coverage.
      // Let's stick to factor = units required per 1 input unit.
      // Example: Painting needs 0.15L per m2. 15m2 * 0.15 = 2.25L.
      // Then ceiling to nearest packaging if needed, but here we just return raw qty or unit count.
      qty = surface * rule.factor;
    }
    if (rule.type == ConsumptionRuleType.perLinearMeter) {
      final length = inputs['length'] as double? ?? 0.0;
      qty = length * rule.factor;
    }
    if (rule.type == ConsumptionRuleType.perPiece) {
      final count = inputs['count'] as double? ?? 0.0;
      qty = count * rule.factor;
    }
    
    // Always round up to 2 decimals or ceil?
    // User asked: "ceil(surface / coverage)" logic.
    // Let's assume factor is "units per m2".
    return (qty * 100).ceil() / 100.0; // Round to 2 decimals
  }
  
  void _updateInput(String roomId, String taskId, String inputId, dynamic value) {
    final key = _getKey(roomId, taskId);
    if (_taskStates.containsKey(key)) {
      setState(() {
        _taskStates[key]!.inputs[inputId] = value;
        // Recalculate quantities for all products
        final products = _taskStates[key]!.selectedProducts.keys.toList();
        for (var prodId in products) {
           // Find product object (simulated lookup)
           final defaultProds = getDefaultProductsForTask(taskId);
           // We might need a better lookup if we added custom products.
           // For simplicity, we search in default + maybe a global registry?
           // We'll re-find it in defaults for now.
           try {
             final prod = defaultProds.firstWhere((p) => p.id == prodId, orElse: () => const Product(id: 'err', name: '', imageUrl: '', priceHT: 0, unit: '')); 
             if (prod.id != 'err') {
               _taskStates[key]!.selectedProducts[prodId] = _calculateQuantity(prod, _taskStates[key]!.inputs);
             }
           } catch(e) { }
        }
      });
    }
  }

  double _calculateTotal(RoomTaskState state) {
    double total = 0;
    
    state.selectedProducts.forEach((prodId, qty) {
       // Lookup product
       final allProds = getAllProducts();
       final prod = allProds.firstWhere((p) => p.id == prodId, orElse: () => const Product(id: 'err', name: '', imageUrl: '', priceHT: 0, unit: ''));
       if(prod.id != 'err') {
         total += prod.priceHT * qty;
       }
    });
    return total;
  }

  // --- UI Parts ---

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfessions) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentRoom = _roomIds[_selectedRoomTab];
    final tasksForTrade = getTasksForProfession(_selectedTrade);


    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFEFF6FF)],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left, color: Color(0xFF1D74FF), size: 28),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Détails de la Pièce(s)',
                          style: AppTheme.headingStyle(context).copyWith(
                            color: const Color(0xFF0F2648),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Etape 4/6',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right, color: Color(0xFF1D74FF), size: 28),
                    onPressed: () {}, // Future nav
                  ),
                ],
              ),
            ),

            // 2. Room Tabs (Dark Strip)
            Container(
               width: double.infinity,
               color: const Color(0xFF0F2648),
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Row(
                   children: List.generate(_roomIds.length, (index) {
                     final id = _roomIds[index];
                     final isSelected = index == _selectedRoomTab;
                     return GestureDetector(
                       onTap: () => setState(() => _selectedRoomTab = index),
                       child: Container(
                         margin: const EdgeInsets.only(right: 12),
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                         decoration: BoxDecoration(
                           color: isSelected ? const Color(0xFF1D74FF) : Colors.white,
                           borderRadius: BorderRadius.circular(30),
                           // No border for selected, maybe slight shadow?
                         ),
                         child: Row(
                           children: [
                             Icon(
                               _getRoomIcon(id), 
                               color: isSelected ? Colors.white : const Color(0xFF0F2648), 
                               size: 20
                             ),
                             const SizedBox(width: 8),
                             Text(
                               _getRoomLabel(id), 
                               style: TextStyle(
                                 fontFamily: 'Outfit',
                                 color: isSelected ? Colors.white : const Color(0xFF0F2648), 
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               )
                             ),
                             if (isSelected) ...[
                               const SizedBox(width: 8),
                               Container(
                                 padding: const EdgeInsets.all(4),
                                 decoration: const BoxDecoration(
                                   color: Colors.white,
                                   shape: BoxShape.circle,
                                 ),
                                 child: Text(
                                   '${index + 4}', // Mock badge number
                                   style: const TextStyle(
                                     color: Color(0xFF1D74FF),
                                     fontSize: 10,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                             ]
                           ],
                         ),
                       ),
                     );
                   }),
                 ),
               ),
            ),
          
          // 2. Trade Tabs (Segmented) - Only show if we have multiple trades or just header if 1
          if (_trades.isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _trades.map((trade) {
                  final isSelected = _selectedTrade == trade;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(trade),
                      selected: isSelected,
                      onSelected: (val) { if(val) setState(() => _selectedTrade = trade); },
                      selectedColor: const Color(0xFFE0E7FF),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontFamily: 'Outfit',
                        color: isSelected ? const Color(0xFF1D74FF) : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF1D74FF) : Colors.grey[300]!)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter des tâches',
                    style: AppTheme.headingStyle(context).copyWith(color: const Color(0xFF111827), fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  
                  // Search
                  TextField(
                     controller: _searchController,
                     decoration: InputDecoration(
                       hintText: 'Rechercher une tâche...',
                       prefixIcon: const Icon(Icons.search, color: Colors.grey),
                       filled: true,
                       fillColor: Colors.white,
                       contentPadding: const EdgeInsets.all(12),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                     ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Grouped Tasks
                  ...tasksForTrade.map((category) => _buildCategorySection(category, currentRoom)),
                  
                  const SizedBox(height: 100),
                ],
              ),

            ),
          ),
        ],
      ),
    ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SafeArea(

          child: ElevatedButton(
            onPressed: _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3557),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),

            child: const Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    // 1. Group tasks by room
    final tasksByRoom = <String, List<RoomTaskState>>{};
    
    // Group active tasks
    _taskStates.forEach((key, state) {
      // Key format is roomId_taskId
      // We need to parse roomId. 
      // Option: Iterate _taskStates and match prefix? 
      // Or store roomId in State? Yes, RoomTaskState doesn't have roomId, only taskId.
      // But we constructed the key as "${roomId}_${taskId}".
      // Let's rely on splitting key.
      final parts = key.split('_');
      if (parts.length >= 2) {
         final roomId = parts[0]; 
         // Handles cases where roomId might contain underscores if any, 
         // but our room IDs are simple 'salon', 'cuisine' etc.
         tasksByRoom.putIfAbsent(roomId, () => []).add(state);
      }
    });

       // 2. Process each room
    tasksByRoom.forEach((roomId, tasks) {
       final expenseItems = <ExpenseItem>[];
       final taskDetails = <String, dynamic>{}; // Store full details

       for (var taskState in tasks) {
          // Calculate Product Cost
          double totalProductCost = 0;
          taskState.selectedProducts.forEach((prodId, qty) {
             final product = getAllProducts().firstWhere(
               (p) => p.id == prodId, 
               orElse: () => const Product(id: 'err', name: '', imageUrl: '', priceHT: 0, unit: '')
             );
             if (product.id != 'err') {
               totalProductCost += product.priceHT * qty;
             }
          });

          // Determine Quantity (e.g. Surface)
          double quantity = 1.0;
          if (taskState.inputs.containsKey('surface')) {
             quantity = (taskState.inputs['surface'] as num).toDouble();
          }

          // Calculate Unit Material Cost
          // If quantity is 10 m2, and total product cost is 100€
          // Material Cost per unit = 10€
          double materialUnitCost = quantity > 0 ? totalProductCost / quantity : totalProductCost;
          
          // Determine Labor Cost (Mock for now, or 0)
          // User asked for product money mainly.
          double laborUnitCost = 0.0; 

          expenseItems.add(ExpenseItem(
             id: taskState.taskId,
             title: taskState.label,
             subtitle: totalProductCost > 0 ? 'Fournitures incluses' : 'Main d\'oeuvre',
             quantity: quantity,
             laborCost: laborUnitCost,
             materialCost: materialUnitCost,
             icon: _getRoomIcon(roomId), // Or task specific icon
             tax: 20.0, // Default tax
          ));
          
          // Serialize Task State for persistence
           taskDetails[taskState.taskId] = {
             'taskId': taskState.taskId,
             'label': taskState.label,
             'inputs': taskState.inputs,
             'selectedProducts': taskState.selectedProducts,
             'note': taskState.note,
             'photoPaths': taskState.photoPaths,
           };
       }
       
       // Update Provider
       ref.read(quoteCreationProvider.notifier).updateRoomEstimation(roomId, expenseItems);
       ref.read(quoteCreationProvider.notifier).updateRoomTasks(roomId, taskDetails);
    });

    // 3. Save User Profession if selected
    if (_selectedTrade.isNotEmpty) {
       ref.read(quoteCreationProvider.notifier).setProfession(_selectedTrade);
    }
    
    // 4. Navigate
    context.push('/quote/summary');
  }

  Widget _buildCategorySection(TaskCategory category, String roomId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            category.title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0, 
            ),
          ),
        ),
        ...category.tasks.map((taskItem) => _buildTaskCard(taskItem, roomId)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTaskCard(TaskItem taskItem, String roomId) {
    final key = _getKey(roomId, taskItem.id);
    final isSelected = _taskStates.containsKey(key);
    final state = isSelected ? _taskStates[key]! : null;
    final isExpanded = state?.isExpanded ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D3557) : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        boxShadow: [
           const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
           ),
        ],
      ),
      child: Column(
        children: [
          // Header (Checkbox + Title)
          InkWell(
            onTap: () {
              if (isSelected) {
                 // Toggle Expansion
                 setState(() {
                   _taskStates[key]!.isExpanded = !_taskStates[key]!.isExpanded;
                 });
              } else {
                 _toggleTaskSelection(roomId, taskItem.id, taskItem.label, true);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Checkbox custom
                  GestureDetector(
                    onTap: () => _toggleTaskSelection(roomId, taskItem.id, taskItem.label, !isSelected),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1D3557) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? const Color(0xFF1D3557) : Colors.grey[300]!),
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      taskItem.label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF1D3557),
                    ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (isSelected && isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   const Divider(height: 1, color: Color(0xFFE5E7EB)),
                   const SizedBox(height: 16),
                   
                   // Note Input Area
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF8FAFC),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFE2E8F0)),
                     ),
                     child: Column(
                       children: [
                         TextField(
                           controller: TextEditingController(text: state!.note),
                           onChanged: (val) => state.note = val,
                           decoration: const InputDecoration(
                             hintText: 'Ajouter une note, une remarque importante...',
                               hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Color(0xFF94A3B8)),
                               border: InputBorder.none,
                               isDense: true,
                           ),
                           maxLines: 3,
                           style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.end,
                           children: [
                             GestureDetector(
                               onTap: () async {
                                 final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                 if (xfile != null) setState(() => state.photoPaths.add(xfile.path));
                               },
                               child: const Icon(Icons.image_outlined, color: Color(0xFF64748B), size: 20),
                             ),
                             const SizedBox(width: 12),
                             GestureDetector(
                               onTap: () async {
                                 final xfile = await ImagePicker().pickImage(source: ImageSource.gallery); // Should be camera
                                 if (xfile != null) setState(() => state.photoPaths.add(xfile.path));
                               },
                               child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF64748B), size: 20),
                             ),
                           ],
                         )
                       ],
                     ),
                   ),

                   if (state.photoPaths.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     SizedBox(
                       height: 60,
                       child: ListView.separated(
                         scrollDirection: Axis.horizontal,
                         itemCount: state.photoPaths.length,
                         separatorBuilder: (_, __) => const SizedBox(width: 8),
                         itemBuilder: (context, index) {
                           return Stack(
                             clipBehavior: Clip.none,
                             children: [
                               ClipRRect(
                                 borderRadius: BorderRadius.circular(8),
                                 child: Image.file(File(state.photoPaths[index]), width: 60, height: 60, fit: BoxFit.cover),
                               ),
                               Positioned(
                                 top: -4, right: -4,
                                 child: GestureDetector(
                                   onTap: () => setState(() => state.photoPaths.removeAt(index)),
                                   child: Container(
                                     padding: const EdgeInsets.all(2),
                                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                     child: const Icon(Icons.close, size: 10, color: Colors.white),
                                   ),
                                 ),
                               ),
                             ],
                           );
                         },
                       ),
                     ),
                   ],
                   
                   const SizedBox(height: 20),
                   
                   // Dynamic Inputs + Add Product Button Row
                   _buildDynamicInputs(roomId, taskItem.id, state),
                   
                   const SizedBox(height: 20),
                   
                   // Products List
                   ...state.selectedProducts.entries.map((entry) {
                      final allProds = getAllProducts();
                      final prod = allProds.firstWhere(
                        (p) => p.id == entry.key, 
                        orElse: () => const Product(id: '?', name: '?', imageUrl: '', priceHT: 0, unit: '')
                      );
                      
                      return _buildProductRow(prod, entry.value, (newQty) {
                        setState(() {
                          state.selectedProducts[entry.key] = newQty;
                        });
                      });
                   }),
                   
                   // Total Calculated Bar
                   Container(
                     margin: const EdgeInsets.only(top: 8),
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFEFF6FF), // Light blue bg
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('Total Calculé', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                         Text('${_calculateTotal(state).toStringAsFixed(2)} €', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                       ],
                     ),
                   ),
                 ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDynamicInputs(String roomId, String taskId, RoomTaskState state) {
    final fields = getFieldsForTask(taskId);
    if (fields.isEmpty) {
        // Even if no fields, show Add Product button
        return Align(
          alignment: Alignment.centerRight,
          child: _buildAddProductButton(roomId, taskId),
        );
    }

    return Column(
      children: fields.map((field) {
         final currentVal = state.inputs[field.id]?.toString() ?? '';
         
         return Row(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             // Input Field
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(field.label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                   const SizedBox(height: 6),
                   Container(
                     height: 48,
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       border: Border.all(color: const Color(0xFFCBD5E1)),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       children: [
                         Expanded(
                           child: TextField(
                             keyboardType: TextInputType.numberWithOptions(decimal: true),
                             decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                             style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                             controller: TextEditingController.fromValue(TextEditingValue(text: currentVal, selection: TextSelection.collapsed(offset: currentVal.length))),
                             onChanged: (val) {
                               _updateInput(roomId, taskId, field.id, double.tryParse(val) ?? 0.0);
                             },
                           ),
                         ),
                         Text(field.suffix, style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF94A3B8))),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
             
             const SizedBox(width: 16),
             
             // Add Supply Button (Dashed style)
             _buildAddProductButton(roomId, taskId),
           ],
         );
      }).toList(),
    );
  }
  
  Widget _buildAddProductButton(String roomId, String taskId) {
    return GestureDetector(
       onTap: () => _showAddProductModal(roomId, taskId),
       child: Container(
         height: 48,
         padding: const EdgeInsets.symmetric(horizontal: 16),
         decoration: BoxDecoration(
           color: const Color(0xFFEFF6FF),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: const Color(0xFFBFDBFE), style: BorderStyle.none), // Can't do real dashed easily without package, solid light blue is fine as per modern trends or similar design
         ),
         child: const Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(Icons.add_circle, color: Color(0xFF3B82F6), size: 20),
             SizedBox(width: 8),
             Text('Fourniture', style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
           ],
         ),
       ),
    );
  }

  Widget _buildProductRow(Product prod, double quantity, Function(double) onQtyChanged) {
     return InkWell(
       onTap: () async {
          final newQty = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: prod, initialQuantity: quantity)),
          );
          if (newQty != null) onQtyChanged(newQty);
       },
       child: Container(
         margin: const EdgeInsets.only(bottom: 12),
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: Colors.white,
           border: Border.all(color: const Color(0xFFE2E8F0)),
           borderRadius: BorderRadius.circular(12),
           boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
           ],
         ),
         child: Row(
           children: [
             // Thumb
             Container(
               width: 50, height: 50,
               decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
               child: prod.imageUrl.isNotEmpty 

                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: prod.imageUrl.startsWith('http')
                        ? Image.network(prod.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 24, color: Colors.grey))
                        : Image.asset(prod.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 24, color: Colors.grey))
                    )
                  : const Icon(Icons.image, size: 24, color: Colors.grey),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(prod.name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                   const SizedBox(height: 2),
                   Text('${prod.priceHT} € / ${prod.unit}', style: const TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B), fontSize: 11)),
                 ],
               ),
             ),
             // Stepper Pill
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
               decoration: BoxDecoration(
                 color: const Color(0xFFF8FAFC),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: const Color(0xFFE2E8F0)),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   GestureDetector(
                     onTap: () => onQtyChanged(max(0, quantity - 1)),
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                       child: const Icon(Icons.remove, size: 14, color: Color(0xFF1E3A8A)),
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 10),
                     child: Text('${quantity.toInt().toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                   ),
                   GestureDetector(
                     onTap: () => onQtyChanged(quantity + 1),
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                       child: const Icon(Icons.add, size: 14, color: Color(0xFF1E3A8A)),
                     ),
                   ),
                 ],
               ),
             )
           ],
         ),
       ),
     );
  }
  

  Future<void> _showAddProductModal(String roomId, String taskId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductSelectionScreen(roomId: roomId, taskId: taskId),
      ),
    );

    if (result != null && result is Map) {
      final product = result['product'] as Product;
      final quantity = result['quantity'] as double;
      
      final key = _getKey(roomId, taskId);
      setState(() {
        if (!_taskStates.containsKey(key)) {
           // Should ideally be initialized by task selection but if somehow not:
           _taskStates[key] = RoomTaskState(taskId: taskId, label: '', selectedProducts: {});
        }
        
        // Add or Update product
        _taskStates[key]!.selectedProducts[product.id] = quantity;
      });
    }
  }
  

}
