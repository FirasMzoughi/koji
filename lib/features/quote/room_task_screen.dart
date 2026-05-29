
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koji/core/route_args.dart';
import 'package:koji/core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/quote/profession_tasks_data.dart'; // Still using for categories structure
import 'package:koji/features/quote/models/quote_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/quote/repository/product_repository.dart';
import 'package:koji/features/fournitures/fournitures_screen.dart';

import 'package:koji/features/auth/repository/auth_repository.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:koji/features/quote/model/expense_item.dart';

// NEW IMPORTS
import 'package:koji/features/quote/repository/task_repository.dart';
import 'package:koji/features/quote/model/custom_task.dart';
import 'package:koji/features/quote/create_task_screen.dart';
import 'package:koji/features/quote/ouvrage_library_screen.dart';
import 'package:koji/features/quote/model/library_ouvrage.dart';
import 'package:koji/features/pricing/models/pricing_models.dart';
import 'package:koji/features/pricing/repository/pricing_repository.dart';

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
  
  // Custom Tasks
  List<CustomTask> _customTasks = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // updated by _searchController listener
  
  // Logic State
  final Map<String, RoomTaskState> _taskStates = {};
  
  // Pricing State
  final Map<String, RealityFactors> _roomContexts = {};

  // Taux horaire loaded from user profile (default 56,25 €/h = 450/8)
  double _tauxHoraire = 56.25;

  @override
  void initState() {
    super.initState();
    _roomIds = widget.selectedRoomIds.isNotEmpty
        ? widget.selectedRoomIds
        : ['salon', 'cuisine', 'chambre'];

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });

    // Edit-mode rehydration: when the user re-enters this screen via
    // "modifier un devis", quoteCreationProvider.roomTasks holds the saved
    // state. Replay it into _taskStates so existing task selections (with
    // their inputs, fournitures, hours) show up checked and editable.
    _restoreTaskStatesFromProvider();

    _loadUserProfessions();
    _loadTauxHoraire();
  }

  void _restoreTaskStatesFromProvider() {
    final saved = ref.read(quoteCreationProvider).roomTasks;
    if (saved.isEmpty) return;

    saved.forEach((roomId, perRoomRaw) {
      if (perRoomRaw is! Map) return;
      final perRoom = Map<String, dynamic>.from(perRoomRaw);
      perRoom.forEach((taskId, dRaw) {
        if (dRaw is! Map) return;
        final d = Map<String, dynamic>.from(dRaw);
        final key = _getKey(roomId, taskId);

        final inputs = (d['inputs'] is Map)
            ? Map<String, dynamic>.from(d['inputs'] as Map)
            : <String, dynamic>{};
        final selectedProducts = (d['selectedProducts'] is Map)
            ? Map<String, double>.from(
                (d['selectedProducts'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                ),
              )
            : <String, double>{};
        final selectedFournitures = (d['selectedFournitures'] is Map)
            ? Map<String, Map<String, dynamic>>.from(
                (d['selectedFournitures'] as Map).map(
                  (k, v) => MapEntry(
                    k.toString(),
                    Map<String, dynamic>.from(v as Map),
                  ),
                ),
              )
            : <String, Map<String, dynamic>>{};

        // Make sure quantity is reachable from inputs['surface']/['quantity']
        // — _onContinue at line 886 reads inputs['surface'] for quantity.
        final qty = (d['quantity'] as num?)?.toDouble();
        if (qty != null) {
          inputs.putIfAbsent('quantity', () => qty);
          inputs.putIfAbsent('surface', () => qty);
        }

        _taskStates[key] = RoomTaskState(
          taskId: taskId.toString(),
          roomId: roomId.toString(),
          label: (d['label'] as String?) ?? '',
          isExpanded: false,
          inputs: inputs,
          note: d['note'] as String?,
          photoPaths: (d['photoPaths'] as List?)?.cast<String>(),
          selectedProducts: selectedProducts,
          selectedFournitures: selectedFournitures,
          hours: (d['hours'] as num?)?.toDouble() ?? 0.0,
          forfaitEnabled: d['forfaitEnabled'] as bool? ?? false,
          forfaitPrice: (d['forfaitPrice'] as num?)?.toDouble() ?? 0.0,
        );

        final cond = (d['conditionCoeff'] as num?)?.toDouble();
        if (cond != null && cond != 1.0) {
          _roomContexts[roomId.toString()] =
              RealityFactors(condition: cond);
        }
      });
    });
  }

  /// Load taux horaire: per-métier pricing profile first, fallback to business_info
  Future<void> _loadTauxHoraire({String? trade}) async {
    try {
      final profession = trade ?? _selectedTrade;

      // 1. Try per-métier pricing profile
      if (profession.isNotEmpty) {
        final profile = await ref
            .read(pricingRepositoryProvider)
            .getProfileForProfession(profession);
        if (profile != null && profile.hoursPerDay > 0) {
          if (mounted) setState(() => _tauxHoraire = profile.hourlyRate);
          return;
        }
      }

      // 2. Fallback: global business_info from user profile
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;
      final userData = await ref.read(userRepositoryProvider).getUser(user.id);
      final biz = userData?['business_info'] as Map<String, dynamic>?;
      if (biz != null) {
        final daily = (biz['dailyRate'] as num?)?.toDouble() ?? 450.0;
        final hours = (biz['hoursPerDay'] as num?)?.toDouble() ?? 8.0;
        if (mounted) setState(() => _tauxHoraire = hours > 0 ? daily / hours : 56.25);
      }
    } catch (_) {}
  }
  
  Future<void> _loadUserProfessions() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      
      // Load Custom Tasks concurrently
      _loadCustomTasks();

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

        // Split any comma-separated values into individual trades
        // e.g. ['Plombier,Peintre'] → ['Plombier', 'Peintre']
        userTrades = userTrades
            .expand((t) => t.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty))
            .toList();
        
        if (userTrades.isEmpty) {
           userTrades = ['Peintre']; // Default fallback
        }
        
        if (mounted) {
          setState(() {
            _trades = userTrades;
            _selectedTrade = userTrades.first;
            _isLoadingProfessions = false;
          });
          _fetchCustomTasksForTrade(_selectedTrade);
          _loadTauxHoraire(trade: _selectedTrade);
        }
      } else {
         // Not logged in?
         if (mounted) setState(() { _trades = ['Peintre']; _selectedTrade = 'Peintre'; _isLoadingProfessions = false; });
         _loadTauxHoraire(trade: 'Peintre');
      }
    } catch (e) {
      debugPrint('Error loading professions: $e');
      if (mounted) setState(() { _trades = ['Peintre']; _selectedTrade = 'Peintre'; _isLoadingProfessions = false; });
    }
  }

  Future<void> _loadCustomTasks() async {
      try {
        // Find current profession context if possible? Or fetch all.
        // For now, let's just fetch all tasks for this user (RLS handles filtering by user)
        // TaskRepository.getTasks filters by profession. Let's pass the selected trade later or just empty string if we want all?
        // Actually, let's fetch based on _selectedTrade when it changes. 
        // But for initState, we assume the first trade.
        // Let's create a separate method `_refetchCustomTasks` to call when tab changes.
      } catch(e) { debugPrint('err custom tasks: $e'); }
  }
  
  /// Prompts the user for coefficient & réduction to apply for THIS chantier,
  /// pre-filled with the library defaults. Returns null if cancelled.
  Future<(double, double)?> _askCoefficientReduction(LibraryOuvrage o) {
    final coeffCtrl =
        TextEditingController(text: _formatNum(o.coefficient));
    final reducCtrl =
        TextEditingController(text: _formatNum(o.reduction));

    double parse(String s) =>
        double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

    return showDialog<(double, double)>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final coeff = parse(coeffCtrl.text);
            final reduc = parse(reducCtrl.text);
            final preview =
                o.coutMoU * coeff * (1 - (reduc / 100.0));
            return AlertDialog(
              title: const Text('Adapter pour ce chantier'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${o.code} — ${o.designation}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Coefficient',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: coeffCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setSt(() {}),
                              decoration: const InputDecoration(
                                hintText: '1.00',
                                isDense: true,
                                border: OutlineInputBorder(),
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
                            const Text('Réduction (%)',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: reducCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setSt(() {}),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Prix MO/u : ${preview.toStringAsFixed(2)} €  '
                      '(base ${o.coutMoU.toStringAsFixed(2)} €)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    (parse(coeffCtrl.text), parse(reducCtrl.text)),
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _openLibraryPicker() async {
    final picked = await Navigator.push<LibraryOuvrage>(
      context,
      MaterialPageRoute(
        builder: (_) => const OuvrageLibraryScreen(pickMode: true),
      ),
    );
    if (picked == null || !mounted) return;

    // Ask the user to confirm / override coefficient and réduction for THIS
    // chantier — they change from one chantier to another even though the
    // library defaults stay the same.
    final overrides = await _askCoefficientReduction(picked);
    if (overrides == null || !mounted) return;

    final coeff = overrides.$1;
    final reduc = overrides.$2;
    final effectiveTemps =
        picked.tempsHU * coeff * (1 - (reduc / 100.0));

    try {
      final professionForTask = picked.famille?.trim().isNotEmpty == true
          ? picked.famille!.trim()
          : (_selectedTrade.isNotEmpty ? _selectedTrade : 'Autres');

      final created = await ref.read(taskRepositoryProvider).createTask(
            title: picked.designation,
            description: picked.commentaire,
            profession: professionForTask,
            code: picked.code,
            famille: picked.famille,
            unite: picked.unite,
            tempsHU: effectiveTemps,
            typePoste: 'POSTE',
          );

      if (!mounted) return;
      // Switch the trade tab so the new task is visible right away.
      if (_trades.contains(professionForTask) &&
          _selectedTrade != professionForTask) {
        setState(() => _selectedTrade = professionForTask);
      }
      await _fetchCustomTasksForTrade(_selectedTrade);
      if (!mounted) return;

      // Auto-select it for the current room with the library's temps.
      final currentRoom = _roomIds[_selectedRoomTab];
      _toggleTaskSelection(currentRoom, created.id, created.title, true);
      final key = _getKey(currentRoom, created.id);
      final state = _taskStates[key];
      if (state != null) {
        setState(() {
          state.hours = effectiveTemps;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ouvrage "${picked.code}" ajouté au chantier'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout ouvrage: $e')),
      );
    }
  }

  // Call this when trade changes or initially
  Future<void> _fetchCustomTasksForTrade(String trade) async {
    try {
       final tasks = await ref.read(taskRepositoryProvider).getTasks(trade);
       if (mounted) setState(() => _customTasks = tasks);
    } catch (e) {
      debugPrint('Error load custom tasks: $e');
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
        if (_taskStates.containsKey(key)) {
          _taskStates.remove(key);
        }
      } else {
        // Selecting
        if (!_taskStates.containsKey(key)) {
           // Initialize state
           final newState = RoomTaskState(taskId: taskId, roomId: roomId, label: label, isExpanded: true);
           
           // Check if Standard Task inputs need init
           for(var field in getFieldsForTask(taskId)) {
             if(field.defaultValue != null) {
               newState.inputs[field.id] = field.defaultValue;
             }
           }
           
           // Check if Custom Task defaults need init
           try {
             final custom = _customTasks.firstWhere((t) => t.id == taskId, orElse: () => CustomTask(id: '', title: '', profession: ''));
             if (custom.id.isNotEmpty) {
               if (custom.description != null) newState.note = custom.description!;
               // Add images (URLs)
               newState.photoPaths.addAll(custom.imageUrls);
             }
           } catch(e) {/* ignore */}

           _taskStates[key] = newState;
           
           // Show reality factors dialog after selection
           Future.microtask(() => _showRealityFactorsDialog(roomId, taskId, label));
        } else {
          // Just expand
          _taskStates[key]!.isExpanded = true;
        }
      }
    });
  }
  
  void _showRealityFactorsDialog(String roomId, String taskId, String label) {
    // Get current room context or default
    RealityFactors current = _roomContexts[roomId] ?? const RealityFactors();
    
    int conditionIndex = 0;
    if (current.condition == 1.20) conditionIndex = 1;
    if (current.condition == 1.40) conditionIndex = 2;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'État des supports - $label',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sélectionnez l\'état des supports pour ce chantier',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sain
                  RadioListTile<int>(
                    value: 0,
                    groupValue: conditionIndex,
                    onChanged: (v) => setStateDialog(() => conditionIndex = v!),
                    title: const Text('Sain', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('×1,00 - Supports en bon état'),
                  ),
                  
                  // Moyen
                  RadioListTile<int>(
                    value: 1,
                    groupValue: conditionIndex,
                    onChanged: (v) => setStateDialog(() => conditionIndex = v!),
                    title: const Text('Moyen', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('×1,20 - Supports moyens'),
                  ),
                  
                  // Dégradé
                  RadioListTile<int>(
                    value: 2,
                    groupValue: conditionIndex,
                    onChanged: (v) => setStateDialog(() => conditionIndex = v!),
                    title: const Text('Dégradé', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('×1,40 - Supports dégradés'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    double condition = 1.0;
                    if (conditionIndex == 1) condition = 1.20;
                    if (conditionIndex == 2) condition = 1.40;
                    
                    setState(() {
                      _roomContexts[roomId] = RealityFactors(
                        access: current.access,
                        condition: condition,
                        surface: current.surface,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
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
           // Find product object from ALL products, not just defaults
           final allProds = getAllProducts();
           try {
             final prod = allProds.firstWhere((p) => p.id == prodId, orElse: () => const Product(id: 'err', name: '', imageUrl: '', priceHT: 0, unit: '')); 
             if (prod.id != 'err') {
               _taskStates[key]!.selectedProducts[prodId] = _calculateQuantity(prod, _taskStates[key]!.inputs);
             }
           } catch(e) { }
        }
      });
    }
  }

  double _calculateTotal(RoomTaskState state) {
    if (state.forfaitEnabled) return state.forfaitPrice;

    // Fournitures HT
    double fournitures = 0;
    state.selectedFournitures.forEach((_, data) {
      final qty = (data['quantity'] as num?)?.toDouble() ?? 1;
      final unitPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0;
      fournitures += unitPrice * qty;
    });

    // Main d'œuvre HT = quantité × temps(h/u) × coefficient × taux horaire.
    // This MUST match the "TOTAL LIGNE HT" breakdown (see _buildHoursInput),
    // otherwise the bottom "Total Calculé" bar showed only fournitures and
    // displayed 0 € whenever the line was labour-only.
    final coeff =
        (_roomContexts[state.roomId] ?? const RealityFactors()).totalCoefficient;
    final qty = (state.inputs['quantity'] as num?)?.toDouble() ?? 0.0;
    final mo = qty * state.hours * coeff * _tauxHoraire;

    return mo + fournitures;
  }

  /// Toggle row that switches an ouvrage between detailed and flat-price modes.
  Widget _buildForfaitToggle(RoomTaskState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: state.forfaitEnabled
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: state.forfaitEnabled
              ? const Color(0xFF1D74FF)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.request_quote_outlined,
              size: 18, color: Color(0xFF1D74FF)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Forfait (prix fixe, sans détail)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155)),
            ),
          ),
          Switch(
            value: state.forfaitEnabled,
            activeColor: const Color(0xFF1D74FF),
            onChanged: (v) => setState(() => state.forfaitEnabled = v),
          ),
        ],
      ),
    );
  }

  /// Single flat-price input shown when forfait mode is on.
  Widget _buildForfaitPriceField(RoomTaskState state) {
    final txt = state.forfaitPrice == 0 ? '' : _formatNum(state.forfaitPrice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prix forfaitaire (HT)',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '0.00'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: txt,
                      selection: TextSelection.collapsed(offset: txt.length),
                    ),
                  ),
                  onChanged: (val) {
                    state.forfaitPrice =
                        double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                    setState(() {});
                  },
                ),
              ),
              const Text('€', style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ],
    );
  }

  List<Product> getAllProducts() {
    return ref.read(productsProvider).valueOrNull ?? [];
  }

  void _showContextDialog(String roomId) {
    RealityFactors current = _roomContexts[roomId] ?? const RealityFactors();
    
    // Convert logic for UI helpers (using index or labels)
    // Access: 0=House(1.0), 1=Apt(1.15), 2=Constrained(1.30)
    int accessIndex = 0;
    if (current.access == 1.15) accessIndex = 1;
    if (current.access == 1.30) accessIndex = 2;
    
    int conditionIndex = 0;
    if (current.condition == 1.20) conditionIndex = 1;
    if (current.condition == 1.40) conditionIndex = 2;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             return AlertDialog(
               title: const Text("Paramètres du chantier"),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("Accès / Logistique", style: TextStyle(fontWeight: FontWeight.bold)),
                   DropdownButton<int>(
                     value: accessIndex,
                     isExpanded: true,
                     items: const [
                       DropdownMenuItem(value: 0, child: Text("Maison (x1.00)")),
                       DropdownMenuItem(value: 1, child: Text("Appartement (x1.15)")),
                       DropdownMenuItem(value: 2, child: Text("Difficile / Etage sans asc. (x1.30)")),
                     ],
                     onChanged: (v) => setStateDialog(() => accessIndex = v!),
                   ),
                   const SizedBox(height: 16),
                   const Text("État des supports", style: TextStyle(fontWeight: FontWeight.bold)),
                   DropdownButton<int>(
                     value: conditionIndex,
                     isExpanded: true,
                     items: const [
                       DropdownMenuItem(value: 0, child: Text("Bon état (x1.00)")),
                       DropdownMenuItem(value: 1, child: Text("Moyen (x1.20)")),
                       DropdownMenuItem(value: 2, child: Text("Dégradé (x1.40)")),
                     ],
                     onChanged: (v) => setStateDialog(() => conditionIndex = v!),
                   ),
                 ],
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                 ElevatedButton(
                   onPressed: () {
                     // Map back to coefficients
                     double access = 1.0;
                     if (accessIndex == 1) access = 1.15;
                     if (accessIndex == 2) access = 1.30;
                     
                     double condition = 1.0;
                     if (conditionIndex == 1) condition = 1.20;
                     if (conditionIndex == 2) condition = 1.40;
                     
                     setState(() {
                       _roomContexts[roomId] = RealityFactors(
                         access: access,
                         condition: condition,
                         surface: 1.0, 
                       );
                     });
                     Navigator.pop(context);
                   },
                   child: const Text("Valider"),
                 )
               ],
             );
          }
        );
      }
    );
  }

  // --- UI Parts ---

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    
    if (_isLoadingProfessions || productsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentRoom = _roomIds[_selectedRoomTab];

    // Map trade chip label → famille values in DB (one trade can cover multiple familles)
    List<String> _tradeFamilles(String trade) {
      const map = <String, List<String>>{
        'Peintre':        ['Peinture intérieure'],
        'Plombier':       ['Plomberie'],
        'Carreleur':      ['Carrelage'],
        'Electricien':    ['Electricité'],
        'Menuisier':      ['Menuiseries intérieures'],
        'Plâtrier':       ['Cloisons / Plafonds'],
        'Isolation':      ['Isolation'],
        'Revêtement sol': ['Revêtements sols souples'],
        'Démolition':     ['Démolition / Dépose'],
        'Nettoyage':      ['Nettoyage'],
      };
      // Handle combined trades (e.g. 'Plombier,Peintre') by splitting
      final parts = trade.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
      final result = <String>{};
      for (final part in parts) {
        result.addAll(map[part] ?? [part]);
      }
      return result.toList();
    }

    final familles = _tradeFamilles(_selectedTrade);
    final isAllTrades = _selectedTrade.toLowerCase().contains("tout corps");

    final famillesLower = familles.map((f) => f.toLowerCase()).toList();
    
    // Filter _customTasks by trade BEFORE mapping to TaskItem
    final filteredCustomTasks = isAllTrades ? _customTasks : _customTasks.where((t) {
      final fam = (t.famille ?? '').toLowerCase();
      final prof = (t.profession ?? '').toLowerCase();
      final tradeLower = _selectedTrade.toLowerCase();
      
      // 1. Match by backend famille mapping
      if (famillesLower.contains(fam)) return true;
      
      // 2. Match by exact profession (ignoring accents)
      if (prof == tradeLower) return true;
      if (tradeLower == 'electricien' && prof == 'électricien') return true;
      if (tradeLower == 'électricien' && prof == 'electricien') return true;
      if (tradeLower == 'platrier' && prof == 'plâtrier') return true;
      if (tradeLower == 'plâtrier' && prof == 'platrier') return true;
      if (tradeLower == 'revêtement sol' && prof == 'revetement sol') return true;
      
      // 3. Fallback partial match
      if (prof.contains(tradeLower) || tradeLower.contains(prof)) return true;
      
      return false;
    });

    // Build task items (parents only — children attached as subTasks)
    final allTaskItems = filteredCustomTasks.map((t) => TaskItem(
      id: t.id,
      label: t.title,
      code: t.code,
      famille: t.famille ?? t.profession, // Use profession as category title if famille is null
      unite: t.unite,
      tempsHU: t.tempsHU,
      typePoste: t.typePoste,
      parentId: t.parentId,
      isGlobal: false,
      subTasks: t.subTasks.map((s) => TaskItem(
        id: s.id,
        label: s.title,
        code: s.code,
        famille: s.famille ?? s.profession,
        unite: s.unite,
        tempsHU: s.tempsHU,
        typePoste: s.typePoste,
        parentId: s.parentId,
      )).toList(),
    )).toList();

    final tradeFiltered = allTaskItems.toList();

    final backendTaskItems = _searchQuery.isEmpty
        ? tradeFiltered
        : tradeFiltered.where((t) {
            final code  = (t.code  ?? '').toLowerCase();
            final label = t.label.toLowerCase();
            return code.startsWith(_searchQuery) || label.contains(_searchQuery);
          }).toList();

    // Group filtered tasks by famille
    final Map<String, List<TaskItem>> byFamille = {};
    for (final t in backendTaskItems) {
      final fam = (t.famille?.isNotEmpty == true) ? t.famille! : _selectedTrade.toUpperCase();
      byFamille.putIfAbsent(fam, () => []).add(t);
    }
    final tasksForTrade = byFamille.entries
        .map((e) => TaskCategory(title: e.key, tasks: e.value))
        .toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          'Créer vos ouvrages',
                          style: AppTheme.headingStyle(context).copyWith(
                            color: const Color(0xFF0F2648),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
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
                                 color: isSelected ? Colors.white : const Color(0xFF0F2648), 
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               )
                             ),
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
            color: Theme.of(context).colorScheme.surface,
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
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedTrade = trade);
                          _fetchCustomTasksForTrade(trade);
                          _loadTauxHoraire(trade: trade);
                        }
                      },
                      selectedColor: const Color(0xFFE0E7FF),
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      labelStyle: TextStyle(
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
                    'Ajouter des ouvrages',
                    style: AppTheme.headingStyle(context).copyWith(color: const Color(0xFF111827), fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  
                  // Context Button
                  InkWell(
                     onTap: () => _showContextDialog(currentRoom),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       margin: const EdgeInsets.only(bottom: 16),
                       decoration: BoxDecoration(
                         color: const Color(0xFFFFF7ED), // Orange tint
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: const Color(0xFFFDBA74)),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.settings_input_component, color: Color(0xFFC2410C), size: 18),
                           const SizedBox(width: 8),
                           Text(
                             "Paramètres du chantier (Coeff: ${(_roomContexts[currentRoom]?.totalCoefficient ?? 1.0).toStringAsFixed(2)})",
                             style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                           ),
                         ],
                       ),
                     ),
                  ),
                  
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par code ou nom (ex: c → CAR)',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // BIBLIOTHÈQUE D'OUVRAGES BUTTON (pick from library)
                  InkWell(
                    onTap: _openLibraryPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, color: Color(0xFFEA580C)),
                          SizedBox(width: 8),
                          Text(
                            'Bibliothèque d\'ouvrages',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // CREATE TASK BUTTON
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateTaskScreen(profession: _selectedTrade))
                      );
                      if (result == true) {
                         _fetchCustomTasksForTrade(_selectedTrade);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1D74FF).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Color(0xFF1D74FF)),
                          SizedBox(width: 8),
                          Text(
                            'Créer une ouvrage',
                            style: TextStyle(
                              color: Color(0xFF1D74FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ADD FOURNITURE BUTTON (standalone material-only line)
                  InkWell(
                    onTap: () => _addStandaloneFourniture(currentRoom),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, color: Color(0xFF16A34A)),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter fourniture',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Tasks from backend
                  if (tasksForTrade.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucun résultat pour "$_searchQuery"'
                                  : 'Aucune tâche pour $_selectedTrade',
                              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Essayez un autre code ou nom.'
                                  : 'Créez une tâche via le bouton ci-dessus.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
        color: Theme.of(context).colorScheme.surface,
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

  void _onContinue() async {
    // 1. Group tasks by room
    final tasksByRoom = <String, List<RoomTaskState>>{};
    
    // Group active tasks
    _taskStates.forEach((key, state) {
       // Use safe roomId from state
       tasksByRoom.putIfAbsent(state.roomId, () => []).add(state);
    });

       // 2. Process each room
    // 2. Process each room
    for (var entry in tasksByRoom.entries) {
       final roomId = entry.key;
       final tasks = entry.value;

       final expenseItems = <ExpenseItem>[];
       final taskDetails = <String, dynamic>{}; // Store full details

       for (var taskState in tasks) {
          // Calculate Product Cost
          double totalProductCost = 0;
          taskState.selectedFournitures.forEach((_, data) {
             final qty = (data['quantity'] as num?)?.toDouble() ?? 1;
             final unitPrice = (data['unitPrice'] as num?)?.toDouble() ?? 0;
             totalProductCost += unitPrice * qty;
          });

          // Determine Quantity (e.g. Surface)
          double quantity = 1.0;
          if (taskState.inputs.containsKey('surface')) {
             quantity = (taskState.inputs['surface'] as num).toDouble();
          }

          // Determine Labor Cost & Material Cost
          double laborUnitCost = 0.0;
          double materialUnitCost = 0.0;

          // Get hourly rate from user's business profile
          final user = ref.read(authRepositoryProvider).currentUser;
          double dailyRate = 350.0;
          double hoursPerDay = 7.0;

          if (user != null) {
            final userData = await ref.read(userRepositoryProvider).getUser(user.id);
            final businessInfo = userData?['business_info'] as Map<String, dynamic>?;
            if (businessInfo != null) {
              dailyRate = (businessInfo['dailyRate'] as num?)?.toDouble() ?? 350.0;
              hoursPerDay = (businessInfo['hoursPerDay'] as num?)?.toDouble() ?? 7.0;
            }
          }

          final hourlyRate = hoursPerDay > 0 ? dailyRate / hoursPerDay : dailyRate / 7.0;
          // Full chantier coefficient (access × condition × surface) — matches
          // the badge shown to the user. Using only `.condition` here dropped
          // the access/surface factors from the price.
          final conditionCoeff =
              (_roomContexts[roomId] ?? const RealityFactors()).totalCoefficient;
          final hours = taskState.hours; // per-unit temps (h/u)

          // Labor unit cost = temps(h/u) × hourly rate × coefficient.
          // `hours` is already per-unit, so do NOT divide by quantity.
          if (hours > 0) {
            laborUnitCost = hours * hourlyRate * conditionCoeff;
          }

          // Material cost from fournitures
          if (quantity > 0) {
            materialUnitCost = totalProductCost / quantity;
          } else {
            materialUnitCost = totalProductCost;
          }

          // Forfait: bill a single flat price. Quantity = 1, the whole price
          // lives in laborCost, no temps/fournitures breakdown is emitted.
          if (taskState.forfaitEnabled) {
            quantity = 1.0;
            laborUnitCost = taskState.forfaitPrice;
            materialUnitCost = 0.0;
          }

          expenseItems.add(ExpenseItem(
             id: taskState.taskId,
             title: taskState.label,
             subtitle: taskState.forfaitEnabled
                 ? 'Forfait'
                 : (hours > 0 ? '${hours.toStringAsFixed(1)}h × ${hourlyRate.toStringAsFixed(2)} €/h' : (totalProductCost > 0 ? 'Fournitures incluses' : 'Main d\'oeuvre')),
             quantity: quantity,
             laborCost: laborUnitCost,
             materialCost: materialUnitCost,
             icon: _getRoomIcon(roomId),
             tax: 20.0,
             hourlyRate: taskState.forfaitEnabled ? 0.0 : hourlyRate,
             normativeTime: taskState.forfaitEnabled ? 0.0 : hours,
          ));
          
          // Update Provider with context
          if (_roomContexts.containsKey(roomId)) {
             ref.read(quoteCreationProvider.notifier).updateRoomContext(roomId, _roomContexts[roomId]!);
          }
          
          // Serialize Task State for persistence
          // Lookup custom task metadata (code, famille, unite)
          CustomTask? customTask;
          try {
            customTask = _customTasks.firstWhere(
              (t) => t.id == taskState.taskId,
              orElse: () => CustomTask(id: '', title: '', profession: ''),
            );
            if (customTask.id.isEmpty) customTask = null;
          } catch (_) {}

           taskDetails[taskState.taskId] = {
             'taskId': taskState.taskId,
             'label': taskState.label,
             'inputs': taskState.inputs,
             'selectedProducts': taskState.selectedProducts,
             'selectedFournitures': taskState.selectedFournitures,
             'note': taskState.note,
             'photoPaths': taskState.photoPaths,
             // KOJI fields for recap table
             'hours': taskState.hours,          // temps h/u entered by user
             'quantity': (taskState.inputs['quantity'] as num?)?.toDouble() ?? quantity,
             'tauxHoraire': hourlyRate,
             'conditionCoeff': conditionCoeff,
             'unite': customTask?.unite ?? 'u',
             'code': customTask?.code ?? '',
             'famille': customTask?.famille ?? '',
             'forfaitEnabled': taskState.forfaitEnabled,
             'forfaitPrice': taskState.forfaitPrice,
           };
       }
       
       // Update Provider
       ref.read(quoteCreationProvider.notifier).updateRoomEstimation(roomId, expenseItems);
       ref.read(quoteCreationProvider.notifier).updateRoomTasks(roomId, taskDetails);
    }

    // 3. Save User Profession if selected
    if (_selectedTrade.isNotEmpty) {
       ref.read(quoteCreationProvider.notifier).setProfession(_selectedTrade);
    }
    
    // 4. Navigate straight to the Récapitulatif. The recap recomputes all
    // totals from `roomTasks` (already saved above via updateRoomTasks), so the
    // intermediate summary step was redundant.
    if (!mounted) return;
    context.push(
      '/quote/detail',
      extra: QuoteDetailArgs(data: ref.read(quoteCreationProvider).toMap()),
    );
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

  Widget _kojiChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // Colour for a famille badge — mirrors CreateTaskScreen
  Color _familleColor(String? famille) {
    switch (famille) {
      case 'Carrelage':   return const Color(0xFFB45309);
      case 'Peinture':    return const Color(0xFF7C3AED);
      case 'Plomberie':   return const Color(0xFF0369A1);
      case 'Electricité': return const Color(0xFFD97706);
      case 'Menuiserie':  return const Color(0xFF166534);
      case 'Démolition':  return const Color(0xFFB91C1C);
      default:            return const Color(0xFF475569);
    }
  }

  Widget _buildTaskCard(TaskItem taskItem, String roomId) {
    final key = _getKey(roomId, taskItem.id);
    final isSelected = _taskStates.containsKey(key);
    final state = isSelected ? _taskStates[key]! : null;
    final isExpanded = state?.isExpanded ?? false;
    final hasKoji = taskItem.tempsHU != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D3557) : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        boxShadow: const [
           BoxShadow(
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
                 setState(() {
                   _taskStates[key]!.isExpanded = !_taskStates[key]!.isExpanded;
                 });
              } else {
                 _toggleTaskSelection(roomId, taskItem.id, taskItem.label, true);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox custom
                  GestureDetector(
                    onTap: () => _toggleTaskSelection(roomId, taskItem.id, taskItem.label, !isSelected),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1D3557) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? const Color(0xFF1D3557) : Colors.grey[300]!),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.surface,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Code + Famille badges (only when KOJI task)
                        if (hasKoji) ...[
                          Row(
                            children: [
                              if (taskItem.code != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _familleColor(taskItem.famille).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    taskItem.code!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _familleColor(taskItem.famille),
                                    ),
                                  ),
                                ),
                              if (taskItem.famille != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  taskItem.famille!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          taskItem.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        // KOJI metrics preview
                        if (taskItem.isParent && taskItem.subTasks.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _kojiChip(Icons.account_tree_outlined,
                              '${taskItem.subTasks.length} sous-postes • ${taskItem.effectiveTempsHU.toStringAsFixed(2)} h/${taskItem.unite ?? 'u'}',
                              const Color(0xFF0369A1)),
                        ] else if (hasKoji) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _kojiChip(Icons.access_time, '${taskItem.tempsHU} h/${taskItem.unite ?? 'u'}', const Color(0xFF3B82F6)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF1D3557),
                    ),
                  // Edit / delete menu — only for user-created postes (not global).
                  if (!taskItem.isGlobal)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert,
                            size: 20, color: Color(0xFF94A3B8)),
                        onSelected: (action) {
                          if (action == 'edit') {
                            _editTask(taskItem);
                          } else if (action == 'delete') {
                            _confirmDeleteTask(taskItem);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit,
                                  size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete,
                                  size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 8),
                              Text('Supprimer',
                                  style: TextStyle(color: Color(0xFFEF4444))),
                            ]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sub-tasks section — visible if parent has children OR if it's a top-level task (to let them add sub-tasks)
          if (taskItem.subTasks.isNotEmpty || !taskItem.isChild) ...[
            if (taskItem.subTasks.isNotEmpty)
              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...taskItem.subTasks.map((sub) => _buildSubTaskRow(sub, roomId)),
                  // Add sub-task button — only for user-created parents (not global)
                  if (!taskItem.isGlobal)
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateTaskScreen(
                            profession: _selectedTrade,
                            parentId: taskItem.id,
                            parentCode: taskItem.code,
                          )),
                        );
                        if (result == true) _fetchCustomTasksForTrade(_selectedTrade);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 14, color: Color(0xFF0369A1)),
                            SizedBox(width: 4),
                            Text('Ajouter un sous-poste', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

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
                               hintStyle: TextStyle( fontSize: 13, color: Color(0xFF94A3B8)),
                               border: InputBorder.none,
                               isDense: true,
                           ),
                           maxLines: 3,
                           style: const TextStyle( fontSize: 14),
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
                                  child: state.photoPaths[index].startsWith('http') 
                                     ? Image.network(state.photoPaths[index], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error)) 
                                     : Image.file(File(state.photoPaths[index]), width: 60, height: 60, fit: BoxFit.cover),
                                ),
                               Positioned(
                                 top: -4, right: -4,
                                 child: GestureDetector(
                                   onTap: () => setState(() => state.photoPaths.removeAt(index)),
                                   child: Container(
                                     padding: const EdgeInsets.all(2),
                                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                     child: Icon(
                                       Icons.close,
                                       size: 10,
                                       color: Theme.of(context).colorScheme.surface,
                                     ),
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

                   // ── Forfait toggle ──────────────────────────
                   // When ON, the ouvrage is billed as a flat price and the
                   // detailed quantité / fourniture / temps inputs are hidden.
                   _buildForfaitToggle(state),

                   if (state.forfaitEnabled) ...[
                     const SizedBox(height: 16),
                     _buildForfaitPriceField(state),
                   ] else ...[
                     const SizedBox(height: 20),

                     // Dynamic Inputs + Add Product Button Row
                     _buildDynamicInputs(roomId, taskItem.id, state),

                     const SizedBox(height: 20),

                     // Fournitures List
                     ...state.selectedFournitures.entries.map((entry) {
                        return _buildFournitureRow(
                          entry.value,
                          (newQty) {
                            setState(() {
                              state.selectedFournitures[entry.key]!['quantity'] = newQty;
                            });
                          },
                          () {
                            setState(() {
                              state.selectedFournitures.remove(entry.key);
                            });
                          },
                        );
                     }),

                     // NOTE: The "Main d'œuvre" (quantité + temps h/u) block used
                     // to live here, but the recap screen (quote_detail_screen)
                     // asks for those exact inputs again. We dropped it here to
                     // avoid the duplicate — labor is captured on the recap.
                     // When forfait is ON, the flat price flows straight through
                     // to the recap/devis instead.
                   ],

                   // Total Calculated Bar
                   Container(
                     margin: const EdgeInsets.only(top: 12),
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFEFF6FF), // Light blue bg
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(state.forfaitEnabled ? 'Forfait' : 'Total Calculé', style: const TextStyle( fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                         Text('${_calculateTotal(state).toStringAsFixed(2)} €', style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
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
  
  Widget _buildSubTaskRow(TaskItem sub, String roomId) {
    final key = _getKey(roomId, sub.id);
    final isSelected = _taskStates.containsKey(key);

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: InkWell(
        onTap: () => _toggleTaskSelection(roomId, sub.id, sub.label, !isSelected),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Tree branch icon
              const Text('└ ', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w300)),
              // Checkbox
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.surface,
                        size: 14,
                      )
                    : null,
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sub.code != null)
                      Text(
                        sub.code!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _familleColor(sub.famille).withValues(alpha: 0.8),
                        ),
                      ),
                    Text(
                      sub.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              // Temps badge
              if (sub.tempsHU != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${sub.tempsHU} h/${sub.unite ?? 'u'}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                  ),
                ),
              // Edit / delete menu — only for user-created sub-tasks (not global).
              if (!sub.isGlobal)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Color(0xFF94A3B8)),
                    onSelected: (action) {
                      if (action == 'edit') {
                        _editTask(sub);
                      } else if (action == 'delete') {
                        _confirmDeleteTask(sub);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete,
                              size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style: TextStyle(color: Color(0xFFEF4444))),
                        ]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Edit dialog — works for both parent postes and sous-postes.
  Future<void> _editTask(TaskItem item) async {
    final titleCtrl = TextEditingController(text: item.label);
    final codeCtrl = TextEditingController(text: item.code ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier la tâche',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Désignation'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              try {
                await ref.read(taskRepositoryProvider).updateTask(
                      id: item.id,
                      title: titleCtrl.text.trim(),
                      code: codeCtrl.text.trim().isEmpty
                          ? null
                          : codeCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Enregistrer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (saved == true) {
      _fetchCustomTasksForTrade(_selectedTrade);
    }
  }

  Future<void> _confirmDeleteTask(TaskItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cette tâche ?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text(
            '"${item.label}" sera définitivement supprimée${item.subTasks.isNotEmpty ? ", ainsi que ses ${item.subTasks.length} sous-poste(s)" : ""}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(taskRepositoryProvider).deleteTask(item.id);
      // Drop selection state if the user had selected this task in any room.
      // Keys are formatted as `<roomId>_<taskId>` (see _getKey).
      _taskStates.removeWhere((key, _) => key.endsWith('_${item.id}'));
      _fetchCustomTasksForTrade(_selectedTrade);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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
                   Text(field.label, style: const TextStyle( fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                   const SizedBox(height: 6),
                   Container(
                     height: 48,
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surface,
                       border: Border.all(color: const Color(0xFFCBD5E1)),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       children: [
                         Expanded(
                           child: TextField(
                             keyboardType: const TextInputType.numberWithOptions(decimal: true),
                             decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                             style: const TextStyle(fontWeight: FontWeight.bold,),
                             controller: TextEditingController.fromValue(TextEditingValue(text: currentVal, selection: TextSelection.collapsed(offset: currentVal.length))),
                             onChanged: (val) {
                               _updateInput(roomId, taskId, field.id, double.tryParse(val) ?? 0.0);
                             },
                           ),
                         ),
                         Text(field.suffix, style: const TextStyle( color: Color(0xFF94A3B8))),
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
             Text('Fourniture', style: TextStyle( color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
           ],
         ),
       ),
    );
  }

  Widget _buildFournitureRow(
    Map<String, dynamic> item,
    Function(double) onQtyChanged,
    VoidCallback onDelete,
  ) {
     final name = (item['name'] ?? 'Fourniture').toString();
     final fournisseur = (item['fournisseur'] ?? 'Sans fournisseur').toString();
     final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
     final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
     final conditionnement = (item['conditionnement'] ?? '').toString();

     return Container(
         margin: const EdgeInsets.only(bottom: 12),
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: Theme.of(context).colorScheme.surface,
           border: Border.all(color: const Color(0xFFE2E8F0)),
           borderRadius: BorderRadius.circular(12),
           boxShadow: [
             BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
           ],
         ),
         child: Row(
           children: [
             Container(
               width: 50, height: 50,
               decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
               child: const Icon(Icons.inventory_2_outlined, size: 24, color: Colors.grey),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(name, style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                   const SizedBox(height: 2),
                   Text('$fournisseur${conditionnement.isNotEmpty ? ' • $conditionnement' : ''}', style: const TextStyle( color: Color(0xFF64748B), fontSize: 11)),
                   Text('${unitPrice.toStringAsFixed(2)} € / u', style: const TextStyle( color: Color(0xFF64748B), fontSize: 11)),
                 ],
               ),
             ),
             Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text(
                   '${(quantity * unitPrice).toStringAsFixed(2)} €',
                   style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                 ),
                 const SizedBox(height: 6),
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
                         onTap: () => onQtyChanged(max(1, quantity - 1)),
                         child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                           child: const Icon(Icons.remove, size: 14, color: Color(0xFF1E3A8A)),
                         ),
                       ),
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 10),
                         child: Text(quantity.toInt().toString().padLeft(2, '0'), style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
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
                 ),
                 const SizedBox(height: 4),
                 GestureDetector(
                   onTap: onDelete,
                   child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                 ),
               ],
             )
           ],
         ),
       );
  }
  

  /// Adds a standalone fourniture (material-only) line to the current room.
  /// Implemented as a pseudo-task with no labor (hours = 0): the recap renders
  /// it as a line where Main d'œuvre = 0 and Fournitures = unitPrice × qty.
  Future<void> _addStandaloneFourniture(String roomId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FournituresScreen(selectionMode: true),
      ),
    );
    if (result == null || result is! Map<String, dynamic>) return;

    final fournId = (result['id'] ?? '').toString();
    if (fournId.isEmpty) return;
    final name = (result['name'] ?? 'Fourniture').toString();
    final unitPrice = (result['unitPrice'] as num?)?.toDouble() ?? 0.0;

    // Synthesize a unique task id so multiple fournitures can coexist.
    final pseudoTaskId =
        'fourniture_${fournId}_${DateTime.now().millisecondsSinceEpoch}';
    final key = _getKey(roomId, pseudoTaskId);

    setState(() {
      final state = RoomTaskState(
        taskId: pseudoTaskId,
        roomId: roomId,
        label: name,
        isExpanded: false,
        hours: 0.0, // no labor — material-only line
      );
      state.inputs['quantity'] = 1.0;
      state.selectedFournitures[fournId] = {
        ...result,
        'quantity': 1.0,
        'unitPrice': unitPrice,
      };
      _taskStates[key] = state;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fourniture ajoutée : $name')),
      );
    }
  }

  Future<void> _showAddProductModal(String roomId, String taskId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FournituresScreen(selectionMode: true),
      ),
    );
    if (result == null || result is! Map<String, dynamic>) return;

    final key = _getKey(roomId, taskId);
    final itemId = (result['id'] ?? '').toString();
    if (itemId.isEmpty) return;

    setState(() {
      _taskStates.putIfAbsent(
        key,
        () => RoomTaskState(taskId: taskId, roomId: roomId, label: ''),
      );
      _taskStates[key]!.selectedFournitures[itemId] = Map<String, dynamic>.from(result);
    });
  }
  

}
